package handlers

import (
	"fmt"
	"net/http"

	"qast-backend/config"
	"qast-backend/models"
	"qast-backend/services"

	"github.com/gin-gonic/gin"
)

func DetonarPanico(c *gin.Context) {
	viajeID := c.Param("id")
	userIDStr, _ := c.Get("userID")

	// 1. Poner el viaje en estado de emergencia
	var viaje models.Viaje
	if err := config.DB.Where("id = ?", viajeID).First(&viaje).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Viaje no encontrado"})
		return
	}

	viaje.Estado = "emergencia"
	config.DB.Save(&viaje)

	// 2. Obtener los contactos del pasajero
	var usuario models.Usuario
	config.DB.Where("id = ?", userIDStr).First(&usuario)

	// 3. Obtener info del conductor (para las placas)
	var conductor models.Conductor
	if viaje.ConductorID != nil {
		config.DB.Where("id = ?", viaje.ConductorID).First(&conductor)
	}

	// 4. Enviar SMS a familiar si existe
	if usuario.CelularEmergencia != "" {
		mensaje := fmt.Sprintf("🚨 ALERTA: Tu familiar %s ha activado el BOTÓN DE PÁNICO viajando en la moto Placa %s. ", usuario.Nombre, conductor.Matricula)
		// En la vida real aquí añadimos un link a la app o a un mapa web
		go services.SendOTP(usuario.CelularEmergencia, "PÁNICO: "+mensaje) // Reutilizamos SendOTP para SMS general por ahora
	}

	// 5. Alertar al Municipio vía WebSockets
	alerta := map[string]interface{}{
		"tipo":         "ALERTA_PANICO",
		"viaje_id":     viaje.ID,
		"cliente":      usuario.Nombre,
		"placa":        conductor.Matricula,
		"telefono_cli": usuario.Telefono,
	}
	HubAdmin.Broadcast <- alerta

	c.JSON(http.StatusOK, gin.H{"message": "Alerta detonada. Contactando a autoridades y familiares."})
}

// DetonarPanicoChofer es para que el conductor mande alerta silenciosa en cualquier momento
func DetonarPanicoChofer(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "No autorizado"})
		return
	}

	var usuario models.Usuario
	if err := config.DB.Where("id = ?", userIDStr).First(&usuario).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Usuario no encontrado"})
		return
	}

	var conductor models.Conductor
	config.DB.Where("usuario_id = ?", userIDStr).First(&conductor)

	// Alertar al Municipio vía WebSockets
	alerta := map[string]interface{}{
		"tipo":         "ALERTA_PANICO_CHOFER",
		"chofer_id":    conductor.ID,
		"chofer":       usuario.Nombre + " " + usuario.Apellidos,
		"placa":        conductor.Matricula,
		"telefono":     usuario.Telefono,
	}
	HubAdmin.Broadcast <- alerta

	// Opcional: SMS a su familiar
	if usuario.CelularEmergencia != "" {
		mensaje := fmt.Sprintf("🚨 ALERTA: Tu familiar %s (Conductor) ha activado su BOTÓN DE PÁNICO. Placa %s.", usuario.Nombre, conductor.Matricula)
		go services.SendOTP(usuario.CelularEmergencia, "PÁNICO CHOFER: "+mensaje)
	}

	c.JSON(http.StatusOK, gin.H{"message": "Alerta silenciosa enviada al Centro de Mando."})
}

