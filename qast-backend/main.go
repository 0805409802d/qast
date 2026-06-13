package main

import (
	"log"
	"os"

	"qast-backend/config"
	"qast-backend/handlers"
	"qast-backend/routes"

	"github.com/joho/godotenv"
)

func main() {
	// 1. Cargar .env
	err := godotenv.Load()
	if err != nil {
		log.Println("Aviso: No se encontró archivo .env local, usando variables de entorno del sistema.")
	}

	// Iniciar Hub de WebSockets en background
	go handlers.HubAdmin.Run()

	// 2. Conectar a la Base de Datos
	config.ConnectDB()

	// 3. Iniciar Router de Gin
	r := routes.SetupRouter()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Servidor backend escuchando en http://localhost:%s", port)
	r.Run(":" + port)
}
