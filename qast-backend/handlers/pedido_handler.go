package handlers

import (
	"fmt"
	"net/http"

	"qast-backend/config"
	"qast-backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type CrearPedidoReq struct {
	NegocioID   string  `json:"negocio_id" binding:"required"`
	DetalleJson string  `json:"detalle_json" binding:"required"`
	Total       float64 `json:"total" binding:"required"`
}

func CrearPedido(c *gin.Context) {
	clienteIDStr, _ := c.Get("userID")
	clienteUUID, _ := uuid.Parse(fmt.Sprintf("%v", clienteIDStr))

	var req CrearPedidoReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Datos inválidos"})
		return
	}

	negocioUUID, err := uuid.Parse(req.NegocioID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "ID de negocio inválido"})
		return
	}

	pedido := models.PedidoDelivery{
		ClienteID:   clienteUUID,
		NegocioID:   negocioUUID,
		DetalleJson: req.DetalleJson,
		Total:       req.Total,
		Estado:      "pendiente",
	}

	if err := config.DB.Create(&pedido).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al crear pedido"})
		return
	}

	// Alerta al restaurante por WebSockets iría aquí
	c.JSON(http.StatusOK, gin.H{"message": "Pedido enviado al restaurante", "pedido": pedido})
}

func MarcarPedidoListo(c *gin.Context) {
	pedidoID := c.Param("id")
	// Verificar que el restaurante dueño hace esto (Simplificado por ahora)
	
	var pedido models.PedidoDelivery
	if err := config.DB.Where("id = ?", pedidoID).First(&pedido).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pedido no encontrado"})
		return
	}

	pedido.Estado = "listo"
	config.DB.Save(&pedido)

	// Alerta a los repartidores por WebSockets
	c.JSON(http.StatusOK, gin.H{"message": "Pedido listo para recoger"})
}

func AceptarPedidoDelivery(c *gin.Context) {
	pedidoID := c.Param("id")
	conductorIDStr, _ := c.Get("userID")

	var conductor models.Conductor
	config.DB.Where("usuario_id = ?", conductorIDStr).First(&conductor)

	var pedido models.PedidoDelivery
	if err := config.DB.Where("id = ?", pedidoID).First(&pedido).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pedido no encontrado"})
		return
	}

	if pedido.Estado != "listo" && pedido.Estado != "pendiente" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Pedido ya fue tomado"})
		return
	}

	pedido.Estado = "en_camino"
	pedido.ConductorID = &conductor.ID
	config.DB.Save(&pedido)

	c.JSON(http.StatusOK, gin.H{"message": "Pedido asignado, ve al restaurante a recogerlo"})
}

func EntregarPedido(c *gin.Context) {
	pedidoID := c.Param("id")
	
	var pedido models.PedidoDelivery
	if err := config.DB.Where("id = ?", pedidoID).First(&pedido).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Pedido no encontrado"})
		return
	}

	pedido.Estado = "entregado"
	config.DB.Save(&pedido)

	c.JSON(http.StatusOK, gin.H{"message": "Pedido entregado con éxito"})
}
