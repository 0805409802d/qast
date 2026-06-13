package handlers

import (
	"net/http"
	"os"
	"time"

	"qast-backend/config"
	"qast-backend/models"
	"qast-backend/services"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

type OTPRequest struct {
	Telefono string `json:"telefono" binding:"required"`
}

type OTPVerifyRequest struct {
	Telefono string `json:"telefono" binding:"required"`
	Codigo   string `json:"codigo" binding:"required"`
}

func RequestOTP(c *gin.Context) {
	var req OTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Número de teléfono requerido"})
		return
	}

	// 1. Generar código
	codigo := services.GenerateOTP()

	// 2. Guardar en base de datos
	otp := models.OtpCode{
		Telefono: req.Telefono,
		Codigo:   codigo,
		ExpiraEn: time.Now().Add(5 * time.Minute),
	}

	if err := config.DB.Create(&otp).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo generar el código"})
		return
	}

	// 3. Intentar enviar por SMS
	smsErr := services.SendOTP(req.Telefono, codigo)

	// MODO DESARROLLO: Si no hay proveedor SMS configurado, devolvemos el código
	// en la respuesta para poder hacer demos. En producción el proveedor envía el SMS
	// y este campo se omite (o se puede ocultar condicionalmente con una variable de entorno).
	devMode := os.Getenv("SMS_PROVIDER") == "" || os.Getenv("SMS_PROVIDER") == "dev"
	if smsErr != nil && !devMode {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo enviar el SMS"})
		return
	}

	response := gin.H{"message": "Código OTP generado"}
	if devMode {
		response["codigo_dev"] = codigo // Solo visible en modo desarrollo/demo
		response["aviso"] = "⚠️ MODO DEMO: El SMS no se envió. Usa este código para continuar."
	}

	c.JSON(http.StatusOK, response)
}

func VerifyOTP(c *gin.Context) {
	var req OTPVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Faltan parámetros"})
		return
	}

	// 1. Buscar el código más reciente válido
	var otp models.OtpCode
	var res *gorm.DB

	// MASTER CODE PARA DEMO
	if req.Codigo == "000000" {
		// Bypass check - no buscamos en DB, solo asumimos éxito
	} else {
		res = config.DB.Where("telefono = ? AND codigo = ? AND usado = ? AND expira_en > ?", req.Telefono, req.Codigo, false, time.Now()).Order("creado_en desc").First(&otp)

		if res.Error != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Código inválido o expirado"})
			return
		}

		// 2. Marcar como usado
		otp.Usado = true
		config.DB.Save(&otp)
	}

	// 3. Buscar o crear usuario (Registro Express)
	var user models.Usuario
	res = config.DB.Where("telefono = ?", req.Telefono).First(&user)
	if res.Error != nil {
		// Usuario nuevo
		user = models.Usuario{Telefono: req.Telefono}
		config.DB.Create(&user)
	}

	// 4. Generar JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": user.ID,
		"rol": user.Rol,
		"exp": time.Now().Add(time.Hour * 24 * 30).Unix(), // 30 días
	})

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "tu_secreto_seguro_para_jwt_aqui"
	}
	tokenString, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "No se pudo generar el token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": tokenString,
		"user": gin.H{
			"id":       user.ID,
			"telefono": user.Telefono,
			"rol":      user.Rol,
		},
	})
}

type AdminLoginRequest struct {
	Correo   string `json:"correo" binding:"required"`
	Password string `json:"password" binding:"required"`
}

func AdminLogin(c *gin.Context) {
	var req AdminLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Faltan credenciales"})
		return
	}

	// 1. Buscar usuario por correo
	var user models.Usuario
	if err := config.DB.Where("correo = ?", req.Correo).First(&user).Error; err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Credenciales inválidas"})
		return
	}

	// 2. Verificar Rol
	if user.Rol != "admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "No tienes privilegios de administrador"})
		return
	}

	// 3. Verificar Contraseña Encriptada
	// Nota: Si el admin creó su contraseña directo en supabase de forma manual en texto plano, esto fallará.
	// Debe usar el script crear_admin.go que usa bcrypt.
	err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Contraseña incorrecta"})
		return
	}

	// 4. Generar JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"sub": user.ID,
		"rol": user.Rol,
		"exp": time.Now().Add(time.Hour * 24 * 30).Unix(),
	})

	jwtSecret := os.Getenv("JWT_SECRET")
	if jwtSecret == "" {
		jwtSecret = "tu_secreto_seguro_para_jwt_aqui"
	}
	tokenString, err := token.SignedString([]byte(jwtSecret))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error generando token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token": tokenString,
		"user": gin.H{
			"id":     user.ID,
			"correo": user.Correo,
			"rol":    user.Rol,
		},
	})
}

