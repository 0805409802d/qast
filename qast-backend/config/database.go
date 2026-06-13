package config

import (
	"log"
	"os"

	"qast-backend/models"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDB() {
	dsn := os.Getenv("DATABASE_URL")
	if dsn == "" {
		log.Fatal("DATABASE_URL is not set in .env")
	}

	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Opcional: Automigrate en Go para mantener la DB sincronizada (con cuidado en prod)
	// Para nuestro caso, la estructura fuerte está en schema.sql, 
	// pero podemos dejar que Gorm cree la tabla de UUID si no existe
	err = db.AutoMigrate(&models.Usuario{}, &models.Conductor{}, &models.PagoSuscripcion{}, &models.OtpCode{}, &models.Configuracion{}, &models.TarifaFija{}, &models.Viaje{}, &models.Negocio{}, &models.Producto{}, &models.PedidoDelivery{})
	if err != nil {
		log.Printf("Warning in AutoMigrate: %v", err)
	}

	DB = db
	log.Println("Database connection successfully opened")
}
