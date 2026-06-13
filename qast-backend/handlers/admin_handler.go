package handlers

import (
	"fmt"
	"net/http"
	"time"

	"qast-backend/config"
	"qast-backend/models"

	"github.com/gin-gonic/gin"
	"golang.org/x/crypto/bcrypt"
)

// ==========================================
// FLUJO DE CHOFERES (2 PASOS)
// ==========================================

type Paso1Request struct {
	Nombre     string `json:"nombre" binding:"required"`
	Apellidos  string `json:"apellidos" binding:"required"`
	Cedula     string `json:"cedula" binding:"required"`
	Telefono   string `json:"telefono" binding:"required"`
	TipoSangre string `json:"tipo_sangre"`
}

func Paso1Basico(c *gin.Context) {
	var req Paso1Request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Faltan datos básicos"})
		return
	}

	// 1. Crear Usuario
	usuario := models.Usuario{
		Nombre:    req.Nombre,
		Apellidos: req.Apellidos,
		Telefono:  req.Telefono,
		Rol:       "chofer",
	}

	if err := config.DB.Create(&usuario).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "El teléfono ya está registrado"})
		return
	}

	// 2. Crear Conductor Pendiente
	conductor := models.Conductor{
		UsuarioID:        usuario.ID,
		Cedula:           req.Cedula,
		TipoSangre:       req.TipoSangre,
		EstadoAprobacion: "pendiente",
	}

	if err := config.DB.Create(&conductor).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "La cédula ya está registrada"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message":   "Chofer registrado en Paso 1 exitosamente",
		"conductor": conductor,
	})
}

type Paso2Request struct {
	Matricula        string `json:"matricula" binding:"required"`
	LicenciaConducir string `json:"licencia_conducir"`
	DocumentosUrl    string `json:"documentos_url"`
	MetodoPago       string `json:"metodo_pago"` // efectivo, transferencia
}

func Paso2Activacion(c *gin.Context) {
	conductorID := c.Param("id")
	adminIDStr, _ := c.Get("userID")

	var req Paso2Request
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Faltan datos vehiculares o de pago"})
		return
	}

	var conductor models.Conductor
	if err := config.DB.Where("id = ?", conductorID).First(&conductor).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Conductor no encontrado"})
		return
	}

	if conductor.EstadoAprobacion == "aprobado" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "El conductor ya estaba aprobado"})
		return
	}

	// 1. Actualizar Conductor
	qrID := fmt.Sprintf("QAST-%s", conductor.ID.String()[:8])
	nuevaFecha := time.Now().AddDate(1, 0, 0)

	conductor.Matricula = req.Matricula
	conductor.LicenciaConducir = req.LicenciaConducir
	conductor.DocumentosUrl = req.DocumentosUrl
	conductor.EstadoAprobacion = "aprobado"
	conductor.QrID = qrID
	conductor.SuscripcionActiva = true
	conductor.FechaFinSuscripcion = &nuevaFecha

	if err := config.DB.Save(&conductor).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al actualizar documentos (¿Matrícula duplicada?)"})
		return
	}

	// 2. Registrar Pago
	if req.MetodoPago == "" {
		req.MetodoPago = "efectivo"
	}
	config.DB.Exec("INSERT INTO pagos_suscripcion (conductor_id, monto, metodo_pago, valido_hasta, registrado_por_admin_id) VALUES (?, 20.00, ?, ?, ?)",
		conductor.ID, req.MetodoPago, nuevaFecha, adminIDStr)

	c.JSON(http.StatusOK, gin.H{
		"message":      "Conductor totalmente aprobado y activo por 1 año",
		"qr_id":        qrID,
		"valido_hasta": nuevaFecha,
	})
}

func ListarConductores(c *gin.Context) {
	// struct custom para devolver datos combinados
	type ConductorResumen struct {
		ID               string `json:"id"`
		Nombre           string `json:"nombre"`
		Apellidos        string `json:"apellidos"`
		Telefono         string `json:"telefono"`
		Cedula           string `json:"cedula"`
		Matricula        string `json:"matricula"`
		EstadoAprobacion string `json:"estado_aprobacion"`
	}

	resultados := make([]ConductorResumen, 0)
	config.DB.Model(&models.Conductor{}).
		Select("conductors.id, usuarios.nombre, usuarios.apellidos, usuarios.telefono, conductors.cedula, conductors.matricula, conductors.estado_aprobacion").
		Joins("left join usuarios on usuarios.id::text = conductors.usuario_id::text").
		Scan(&resultados)

	c.JSON(http.StatusOK, resultados)
}


// Estructura para el nuevo admin
type CrearAdminRequest struct {
	Nombre   string `json:"nombre" binding:"required"`
	Telefono string `json:"telefono" binding:"required"`
	Correo   string `json:"correo" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// CrearNuevoAdmin permite a un admin existente crear a otro admin
func CrearNuevoAdmin(c *gin.Context) {
	var req CrearAdminRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Faltan datos obligatorios (Nombre, Telefono, Correo, Password)"})
		return
	}

	// 1. Encriptar contraseña
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al procesar la contraseña"})
		return
	}

	// 2. Crear modelo
	nuevoAdmin := models.Usuario{
		Nombre:       req.Nombre,
		Telefono:     req.Telefono,
		Correo:       req.Correo,
		PasswordHash: string(hash),
		Rol:          "admin", // Forzamos el rol
	}

	// 3. Guardar en base de datos
	if err := config.DB.Create(&nuevoAdmin).Error; err != nil {
		c.JSON(http.StatusConflict, gin.H{"error": "El correo o teléfono ya están registrados en el sistema"})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"message": "Administrador creado exitosamente",
		"admin": gin.H{
			"id":       nuevoAdmin.ID,
			"nombre":   nuevoAdmin.Nombre,
			"correo":   nuevoAdmin.Correo,
			"telefono": nuevoAdmin.Telefono,
		},
	})
}
