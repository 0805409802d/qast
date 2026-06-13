package routes

import (
	"qast-backend/handlers"
	"qast-backend/middlewares"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {
	r := gin.Default()

	// Configurar CORS
	configCors := cors.DefaultConfig()
	configCors.AllowAllOrigins = true
	configCors.AllowHeaders = []string{"Origin", "Content-Length", "Content-Type", "Authorization"}
	r.Use(cors.New(configCors))

	// Ruta de prueba
	r.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "API de Quinindé Seguro en línea (Gin+GORM)",
		})
	})

	// Rutas Públicas (Auth)
	authRoutes := r.Group("/api/auth")
	{
		authRoutes.POST("/request-otp", handlers.RequestOTP)
		authRoutes.POST("/verify-otp", handlers.VerifyOTP)
		authRoutes.POST("/admin-login", handlers.AdminLogin)
	}

	// Rutas WebSockets (Ideales proteger con token por URL o Header, por ahora públicas para test)
	r.GET("/ws/admin", handlers.WsAdminHandler)

	// Rutas Protegidas (Solo Usuarios Logueados)
	protected := r.Group("/api")
	protected.Use(middlewares.RequireAuth())
	{
		// Módulo Usuarios (Clientes)
		protected.POST("/usuarios/completar-perfil", handlers.CompletarPerfil)

		// Módulo Conductores
		protected.POST("/conductores/register", handlers.RegisterConductor)
		protected.GET("/conductores/me", handlers.GetConductorProfile)
		protected.POST("/conductores/panico", handlers.DetonarPanicoChofer)

		// Módulo Viajes y Pánico
		protected.POST("/viajes/solicitar", handlers.SolicitarViaje)
		protected.POST("/viajes/:id/aceptar", handlers.AceptarViaje)
		protected.POST("/viajes/:id/iniciar-qr", handlers.IniciarViajeQR)
		protected.POST("/viajes/:id/completar", handlers.CompletarViaje)
		protected.POST("/viajes/:id/panico", handlers.DetonarPanico)

		// Módulo Delivery (Pedidos)
		protected.POST("/pedidos/crear", handlers.CrearPedido)
		protected.POST("/pedidos/:id/aceptar", handlers.AceptarPedidoDelivery)
		protected.POST("/pedidos/:id/entregar", handlers.EntregarPedido)

		// Módulo Negocios
		protected.POST("/negocios/register", handlers.CrearNegocio)
		negocios := protected.Group("/negocios")
		negocios.Use(middlewares.RequireNegocio())
		{
			negocios.POST("/productos", handlers.SubirProducto)
			negocios.GET("/productos", handlers.ListarMisProductos)
			negocios.POST("/pedidos/:id/listo", handlers.MarcarPedidoListo)
		}

		// Módulo Administración (Solo Admins)
		adminRoutes := protected.Group("/admin")
		adminRoutes.Use(middlewares.RequireAdmin())
		{
			adminRoutes.GET("/conductores", handlers.ListarConductores)
			adminRoutes.POST("/conductores/paso1-basico", handlers.Paso1Basico)
			adminRoutes.POST("/conductores/:id/paso2-activacion", handlers.Paso2Activacion)
			adminRoutes.POST("/crear-admin", handlers.CrearNuevoAdmin)
		}
	}

	return r
}
