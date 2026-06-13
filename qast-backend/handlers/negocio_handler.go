package handlers

import (
	"fmt"
	"net/http"

	"qast-backend/config"
	"qast-backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type CrearNegocioReq struct {
	NombreComercial string `json:"nombre_comercial" binding:"required"`
	Direccion       string `json:"direccion" binding:"required"`
}

func CrearNegocio(c *gin.Context) {
	userIDStr, _ := c.Get("userID")
	userUUID, _ := uuid.Parse(fmt.Sprintf("%v", userIDStr))

	var req CrearNegocioReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Faltan datos"})
		return
	}

	negocio := models.Negocio{
		UsuarioID:       userUUID,
		NombreComercial: req.NombreComercial,
		Direccion:       req.Direccion,
		EstadoAbierto:   true,
	}

	if err := config.DB.Create(&negocio).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al crear negocio"})
		return
	}

	// Cambiar el rol del usuario a 'negocio'
	config.DB.Exec("UPDATE usuarios SET rol = 'negocio' WHERE id = ?", userUUID)

	c.JSON(http.StatusOK, gin.H{"message": "Negocio creado con éxito", "negocio": negocio})
}

type SubirProductoReq struct {
	Titulo             string  `json:"titulo" binding:"required"`
	Descripcion        string  `json:"descripcion"`
	Precio             float64 `json:"precio" binding:"required"`
	FotoUrl            string  `json:"foto_url"`
	CantidadDisponible int     `json:"cantidad_disponible"`
}

func SubirProducto(c *gin.Context) {
	userIDStr, _ := c.Get("userID")

	// Obtener el negocio del usuario
	var negocio models.Negocio
	if err := config.DB.Where("usuario_id = ?", userIDStr).First(&negocio).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "No tienes un negocio registrado"})
		return
	}

	var req SubirProductoReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Datos del producto incompletos"})
		return
	}

	producto := models.Producto{
		NegocioID:          negocio.ID,
		Titulo:             req.Titulo,
		Descripcion:        req.Descripcion,
		Precio:             req.Precio,
		FotoUrl:            req.FotoUrl,
		CantidadDisponible: req.CantidadDisponible,
	}

	if err := config.DB.Create(&producto).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al subir producto"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Producto añadido al menú", "producto": producto})
}

func ListarMisProductos(c *gin.Context) {
	userIDStr, _ := c.Get("userID")

	var negocio models.Negocio
	if err := config.DB.Where("usuario_id = ?", userIDStr).First(&negocio).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Negocio no encontrado"})
		return
	}

	var productos []models.Producto
	config.DB.Where("negocio_id = ?", negocio.ID).Find(&productos)

	c.JSON(http.StatusOK, gin.H{"productos": productos})
}
