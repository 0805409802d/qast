package main

import (
	"fmt"
	"log"

	"qast-backend/config"
	"qast-backend/models"

	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

func main() {
	godotenv.Load()
	config.ConnectDB()

	correo := "darlyndavid100@gmail.com"
	password := "Darlyn2002."

	// 1. Encriptar la contraseña
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatal("Error encriptando contraseña", err)
	}

	// 2. Crear usuario maestro en la DB
	admin := models.Usuario{
		Telefono:     "0000000000", // Teléfono ficticio porque es requerido
		Correo:       correo,
		PasswordHash: string(hash),
		Nombre:       "Super Admin Municipal",
		Rol:          "admin",
	}

	// Cuidado: si ya existe, esto dará error por el teléfono único.
	if err := config.DB.Create(&admin).Error; err != nil {
		log.Fatal("No se pudo crear el admin:", err)
	}

	fmt.Println("¡Administrador maestro creado exitosamente!")
	fmt.Println("Correo:", correo)
	fmt.Println("Contraseña:", password)
}
