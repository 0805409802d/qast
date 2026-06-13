package main

import (
	"fmt"
	"log"
	"math/rand"
	"time"

	"qast-backend/config"
	"qast-backend/models"

	"github.com/google/uuid"
	"github.com/joho/godotenv"
	"golang.org/x/crypto/bcrypt"
)

func init() {
	rand.Seed(time.Now().UnixNano())
}

func main() {
	godotenv.Load("../.env") // Load from root
	godotenv.Load() // Just in case we run from scripts dir

	config.ConnectDB()

	correo := "darlyndavid100@gmail.com"
	password := "Darlyn2002."
	telefonoPrincipal := "0980991658"

	fmt.Println("Iniciando Seed de Datos para Demo...")

	// 1. Encriptar la contraseña
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		log.Fatal("Error encriptando contraseña", err)
	}

	// 2. CREAR ADMINISTRADOR
	admin := models.Usuario{
		Telefono:     telefonoPrincipal,
		Correo:       correo,
		PasswordHash: string(hash),
		Nombre:       "Darlyn Admin",
		Rol:          "admin",
	}

	if err := config.DB.Where("correo = ?", correo).FirstOrCreate(&admin, admin).Error; err != nil {
		log.Println("Aviso al crear admin:", err)
	} else {
		fmt.Println("✅ Admin creado/verificado:", admin.Correo)
	}

	adminID := admin.ID
	if adminID == uuid.Nil {
		var a models.Usuario
		config.DB.Where("correo = ?", correo).First(&a)
		adminID = a.ID
	}

	// 3. CREAR CLIENTES (Pasajeros)
	nombresClientes := []string{"Carlos", "Maria", "Juan", "Ana", "Luis", "Elena", "Pedro", "Sofia", "Jorge", "Lucia"}
	for i, nombre := range nombresClientes {
		t := fmt.Sprintf("%s%02d", "09910000", i)
		cliente := models.Usuario{
			Telefono: t,
			Nombre:   nombre,
			Rol:      "cliente",
			Correo:   fmt.Sprintf("cliente%d@demo.com", i),
		}
		if i == 0 {
			// Hacer el primer cliente con un teléfono fácil de recordar
			cliente.Telefono = "0991111111"
			cliente.Nombre = "Cliente Principal"
			cliente.Correo = "clienteprincipal@demo.com"
		}
		config.DB.Where("telefono = ?", cliente.Telefono).FirstOrCreate(&cliente, cliente)
	}
	fmt.Println("✅ Clientes (Pasajeros) creados: 10")

	// 4. CREAR CONDUCTORES (Taxis/Motos)
	nombresConductores := []string{"Miguel", "Jose", "Diego", "Andres", "Fernando", "Ricardo", "Gabriel", "Roberto", "Daniel", "Pablo"}
	for i, nombre := range nombresConductores {
		t := fmt.Sprintf("%s%02d", "09920000", i)
		cedula := fmt.Sprintf("%s%02d", "17000000", i)
		matricula := fmt.Sprintf("QST-%04d", i+1)
		
		conductorUser := models.Usuario{
			Telefono: t,
			Nombre:   nombre,
			Rol:      "conductor",
			Correo:   fmt.Sprintf("conductor%d@demo.com", i),
		}
		if i == 0 {
			conductorUser.Telefono = "0992222222"
			conductorUser.Nombre = "Conductor Principal"
			conductorUser.Correo = "conductorprincipal@demo.com"
			cedula = "1700000000"
			matricula = "QST-0000" // Asegurar que sea único
		}
		
		config.DB.Where("telefono = ?", conductorUser.Telefono).FirstOrCreate(&conductorUser, conductorUser)
		
		// Recargar ID si existía
		var u models.Usuario
		config.DB.Where("telefono = ?", conductorUser.Telefono).First(&u)

		finSuscripcion := time.Now().AddDate(1, 0, 0)
		conductorPerfil := models.Conductor{
			UsuarioID:           u.ID,
			Cedula:              cedula,
			Matricula:           matricula,
			EstadoAprobacion:    "aprobado",
			EstadoConexion:      true,
			QrID:                uuid.New().String(),
			SuscripcionActiva:   true,
			FechaFinSuscripcion: &finSuscripcion,
		}
		
		config.DB.Where("cedula = ?", conductorPerfil.Cedula).FirstOrCreate(&conductorPerfil, conductorPerfil)
	}
	fmt.Println("✅ Conductores creados: 10")

	// 5. CREAR NEGOCIOS
	nombresNegocios := []string{"Burger King Quininde", "Pizzeria La Bella", "Asadero El Chamo", "Heladeria Pingüino", "Farmacia Cruz Azul", "Cevicheria El Marinero", "Panaderia Moderna", "Restaurante El Sabor", "Tienda La Esquina", "Licoreria Express"}
	for i, nombre := range nombresNegocios {
		t := fmt.Sprintf("%s%02d", "09930000", i)
		
		negocioUser := models.Usuario{
			Telefono: t,
			Nombre:   "Dueño de " + nombre,
			Rol:      "negocio",
			Correo:   fmt.Sprintf("negocio%d@demo.com", i),
		}
		if i == 0 {
			negocioUser.Telefono = "0993333333"
			negocioUser.Correo = "negocioprincipal@demo.com"
		}
		
		config.DB.Where("telefono = ?", negocioUser.Telefono).FirstOrCreate(&negocioUser, negocioUser)
		
		var u models.Usuario
		config.DB.Where("telefono = ?", negocioUser.Telefono).First(&u)

		negocioPerfil := models.Negocio{
			UsuarioID:       u.ID,
			NombreComercial: nombre,
			Direccion:       "Av. Principal " + fmt.Sprint(i+1),
			EstadoAbierto:   true,
		}
		config.DB.Where("nombre_comercial = ?", negocioPerfil.NombreComercial).FirstOrCreate(&negocioPerfil, negocioPerfil)
		
		var n models.Negocio
		config.DB.Where("nombre_comercial = ?", negocioPerfil.NombreComercial).First(&n)
		
		// Crear productos para cada negocio
		for j := 1; j <= 3; j++ {
			producto := models.Producto{
				NegocioID:          n.ID,
				Titulo:             fmt.Sprintf("Producto %d de %s", j, nombre),
				Descripcion:        "Descripción deliciosa del producto",
				Precio:             float64(j) * 2.5,
				CantidadDisponible: 100,
			}
			config.DB.Where("titulo = ? AND negocio_id = ?", producto.Titulo, producto.NegocioID).FirstOrCreate(&producto, producto)
		}
	}
	fmt.Println("✅ Negocios y Productos creados: 10 negocios, 30 productos")

	// 6. CREAR TARIFAS FIJAS
	tarifas := []models.TarifaFija{
		{OrigenNombre: "Terminal Terrestre", DestinoNombre: "Centro (Parque Central)", Precio: 1.50},
		{OrigenNombre: "Centro (Parque Central)", DestinoNombre: "Hospital Padre Alberto Buffoni", Precio: 1.75},
		{OrigenNombre: "Barrio Los Pambiles", DestinoNombre: "Centro (Parque Central)", Precio: 1.50},
		{OrigenNombre: "Barrio Nuevo Quinindé", DestinoNombre: "Terminal Terrestre", Precio: 2.00},
	}
	for _, t := range tarifas {
		config.DB.Where("origen_nombre = ? AND destino_nombre = ?", t.OrigenNombre, t.DestinoNombre).FirstOrCreate(&t, t)
	}
	fmt.Println("✅ Tarifas fijas creados: 4")

	fmt.Println("🎉 SEED COMPLETADO EXITOSAMENTE 🎉")
	fmt.Println("Puedes ingresar a la aplicación con:")
	fmt.Println("- Admin: ", correo, " / ", password)
	fmt.Println("- Cliente Principal: 0991111111 (OTP Demo: 000000)")
	fmt.Println("- Conductor Principal: 0992222222 (OTP Demo: 000000)")
	fmt.Println("- Negocio Principal: 0993333333 (OTP Demo: 000000)")
}
