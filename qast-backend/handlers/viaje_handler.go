package handlers

import (
	"fmt"
	"math"
	"net/http"
	"strconv"

	"qast-backend/config"
	"qast-backend/models"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type SolicitarViajeReq struct {
	OrigenLat     float64 `json:"origen_lat"`
	OrigenLng     float64 `json:"origen_lng"`
	DestinoLat    float64 `json:"destino_lat"`
	DestinoLng    float64 `json:"destino_lng"`
	OrigenNombre  string  `json:"origen_nombre"` // opcional para texto
	DestinoNombre string  `json:"destino_nombre"`// opcional para texto
}

// Formula Haversine básica en KM
func distanceKM(lat1, lon1, lat2, lon2 float64) float64 {
	const r = 6371 // Radio de la tierra en KM
	p := math.Pi / 180
	a := 0.5 - math.Cos((lat2-lat1)*p)/2 + math.Cos(lat1*p)*math.Cos(lat2*p)*(1-math.Cos((lon2-lon1)*p))/2
	return 2 * r * math.Asin(math.Sqrt(a))
}

func SolicitarViaje(c *gin.Context) {
	clienteIDStr, _ := c.Get("userID")
	clienteUUID, err := uuid.Parse(fmt.Sprintf("%v", clienteIDStr))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "UUID inválido"})
		return
	}

	var req SolicitarViajeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Datos inválidos"})
		return
	}

	var tarifa float64 = 0
	
	// 1. Intentar buscar tarifa fija (Punto A -> Punto B)
	var tarifaFija models.TarifaFija
	if req.OrigenNombre != "" && req.DestinoNombre != "" {
		res := config.DB.Where("origen_nombre = ? AND destino_nombre = ?", req.OrigenNombre, req.DestinoNombre).First(&tarifaFija)
		if res.Error == nil {
			tarifa = tarifaFija.Precio
		}
	}

	// 2. Si no hay tarifa fija, calcular por distancia
	if tarifa == 0 {
		dist := distanceKM(req.OrigenLat, req.OrigenLng, req.DestinoLat, req.DestinoLng)
		
		// Obtener precio base de configuración (o default $0.50)
		var conf models.Configuracion
		precioBase := 0.50
		if err := config.DB.Where("clave = ?", "precio_por_km").First(&conf).Error; err == nil {
			if val, err := strconv.ParseFloat(conf.Valor, 64); err == nil {
				precioBase = val
			}
		}

		tarifa = dist * precioBase
		if tarifa < 1.00 { // Tarifa mínima
			tarifa = 1.00
		}
		// Redondear a 2 decimales
		tarifa = math.Round(tarifa*100) / 100
	}

	viaje := models.Viaje{
		ClienteID:  clienteUUID,
		OrigenLat:  req.OrigenLat,
		OrigenLng:  req.OrigenLng,
		DestinoLat: req.DestinoLat,
		DestinoLng: req.DestinoLng,
		Tarifa:     tarifa,
		Estado:     "pendiente",
	}

	if err := config.DB.Create(&viaje).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Error al crear viaje"})
		return
	}

	// Notificar vía WebSockets a los choferes conectados se haría aquí

	c.JSON(http.StatusOK, gin.H{"viaje": viaje})
}

// AceptarViaje, IniciarQR, CompletarViaje ...
func AceptarViaje(c *gin.Context) {
	viajeID := c.Param("id")
	conductorIDStr, _ := c.Get("userID")

	// Buscar ID real del conductor en la tabla conductores (no el usuarioID)
	var conductor models.Conductor
	config.DB.Where("usuario_id = ?", conductorIDStr).First(&conductor)

	var viaje models.Viaje
	if err := config.DB.Where("id = ?", viajeID).First(&viaje).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Viaje no encontrado"})
		return
	}

	if viaje.Estado != "pendiente" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "El viaje ya fue aceptado"})
		return
	}

	viaje.Estado = "asignado"
	viaje.ConductorID = &conductor.ID
	config.DB.Save(&viaje)

	c.JSON(http.StatusOK, gin.H{"message": "Viaje asignado", "viaje": viaje})
}

type IniciarQRReq struct {
	QrID string `json:"qr_id" binding:"required"`
}

func IniciarViajeQR(c *gin.Context) {
	viajeID := c.Param("id")
	var req IniciarQRReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Falta el QR"})
		return
	}

	var viaje models.Viaje
	if err := config.DB.Where("id = ?", viajeID).First(&viaje).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Viaje no encontrado"})
		return
	}

	var conductor models.Conductor
	config.DB.Where("id = ?", viaje.ConductorID).First(&conductor)

	if conductor.QrID != req.QrID {
		c.JSON(http.StatusForbidden, gin.H{"error": "QR no coincide con el conductor asignado. ¡ALERTA!"})
		return
	}

	viaje.Estado = "activo"
	config.DB.Save(&viaje)

	c.JSON(http.StatusOK, gin.H{"message": "Viaje verificado y seguro iniciado"})
}

func CompletarViaje(c *gin.Context) {
	viajeID := c.Param("id")
	var viaje models.Viaje
	if err := config.DB.Where("id = ?", viajeID).First(&viaje).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Viaje no encontrado"})
		return
	}

	viaje.Estado = "completado"
	config.DB.Save(&viaje)

	c.JSON(http.StatusOK, gin.H{"message": "Viaje completado exitosamente"})
}
