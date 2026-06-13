package handlers

import (
	"net/http"
	"time"

	"qast-backend/config"
	"qast-backend/models"

	"github.com/gin-gonic/gin"
)

type RegisterConductorRequest struct {
	Cedula    string `json:"cedula" binding:"required"`
	Matricula string `json:"matricula" binding:"required"`
}

func RegisterConductor(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "No autorizado"})
		return
	}

	var req RegisterConductorRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Cédula y Matrícula son obligatorias"})
		return
	}



	// Usaremos Where() o DB.Exec dependiendo del parsing de UUID. En Gorm basta con buscar el Usuario o pasar string
	// Por simplicidad en la conversión de JWT sub a UUID, usaremos DB.Exec para insertar directamente 
	// o usaremos google/uuid para parsear.
	
	// Forma segura usando GORM nativo si la struct Conductor usa uuid.UUID:
	// db.Create(&conductor) fallará si UsuarioID no es parseable a UUID.
	
	err := config.DB.Exec("INSERT INTO conductores (usuario_id, cedula, matricula, estado_aprobacion) VALUES (?, ?, ?, 'pendiente')", userIDStr, req.Cedula, req.Matricula).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al registrar conductor o ya existe", "details": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Solicitud registrada. Por favor acércate al Municipio con tus documentos físicos."})
}

func GetConductorProfile(c *gin.Context) {
	userIDStr, _ := c.Get("userID")

	var conductor models.Conductor
	if err := config.DB.Where("usuario_id = ?", userIDStr).First(&conductor).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No eres un conductor registrado"})
		return
	}

	// Revisar si la suscripción sigue activa
	if conductor.SuscripcionActiva && conductor.FechaFinSuscripcion != nil {
		if time.Now().After(*conductor.FechaFinSuscripcion) {
			conductor.SuscripcionActiva = false
			config.DB.Save(&conductor)
		}
	}

	c.JSON(http.StatusOK, gin.H{
		"conductor": conductor,
	})
}
