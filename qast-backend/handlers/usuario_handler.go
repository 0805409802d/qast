package handlers

import (
	"net/http"
	"qast-backend/config"
	"qast-backend/models"

	"github.com/gin-gonic/gin"
)

type PerfilRequest struct {
	Nombre    string `json:"nombre" binding:"required"`
	Apellidos string `json:"apellidos" binding:"required"`
	Cedula    string `json:"cedula" binding:"required"`
}

func CompletarPerfil(c *gin.Context) {
	userIDStr, exists := c.Get("userID")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "No autorizado"})
		return
	}

	var req PerfilRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Todos los campos son obligatorios (Nombre, Apellidos, Cédula)"})
		return
	}

	var usuario models.Usuario
	if err := config.DB.Where("id = ?", userIDStr).First(&usuario).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Usuario no encontrado"})
		return
	}

	usuario.Nombre = req.Nombre
	usuario.Apellidos = req.Apellidos
	usuario.Cedula = req.Cedula

	if err := config.DB.Save(&usuario).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al actualizar perfil"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Perfil completado exitosamente",
		"usuario": usuario,
	})
}
