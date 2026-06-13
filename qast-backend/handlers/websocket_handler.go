package handlers

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"sync"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	// Seguridad: Solo permitir conexiones de orígenes confiables.
	// En dev aceptamos todo; en producción cambiar por la URL del panel admin.
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

// AdminHub gestiona todas las conexiones WebSocket del panel de administración.
type AdminHub struct {
	Clients   map[*websocket.Conn]bool
	Broadcast chan map[string]interface{}
	Mutex     sync.RWMutex
}

// Instancia global del Hub
var HubAdmin = &AdminHub{
	Clients:   make(map[*websocket.Conn]bool),
	Broadcast: make(chan map[string]interface{}, 256), // Buffer para no bloquear en picos
}

// Run escucha el canal de broadcast y reenvía a todos los clientes conectados.
// Debe ejecutarse como goroutine al iniciar el servidor.
func (hub *AdminHub) Run() {
	for msg := range hub.Broadcast {
		hub.Mutex.Lock()
		for client := range hub.Clients {
			if err := client.WriteJSON(msg); err != nil {
				log.Printf("[WS] Cliente desconectado, removiendo: %v", err)
				client.Close()
				delete(hub.Clients, client)
			}
		}
		hub.Mutex.Unlock()
	}
}

// validarTokenWS extrae y verifica el JWT que viene como query param ?token=...
// Retorna el rol del usuario o un error si el token es inválido.
func validarTokenWS(tokenString string) (string, error) {
	if tokenString == "" {
		return "", fmt.Errorf("falta el token de autenticación")
	}

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		secret = "tu_secreto_seguro_para_jwt_aqui"
	}

	token, err := jwt.Parse(tokenString, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("método de firma inesperado: %v", t.Header["alg"])
		}
		return []byte(secret), nil
	})

	if err != nil || !token.Valid {
		return "", fmt.Errorf("token inválido o expirado")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", fmt.Errorf("no se pudieron leer los claims del token")
	}

	rol, _ := claims["rol"].(string)
	return rol, nil
}

// WsAdminHandler gestiona la conexión WebSocket del panel de administración.
// Requiere un JWT válido con rol 'admin' enviado como query param: ?token=<jwt>
func WsAdminHandler(c *gin.Context) {
	// --- SEGURIDAD: Validar JWT ANTES de hacer el upgrade a WebSocket ---
	tokenString := c.Query("token")
	rol, err := validarTokenWS(tokenString)
	if err != nil {
		log.Printf("[WS] Intento de conexión rechazado: %v | IP: %s", err, c.ClientIP())
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Acceso denegado al canal seguro. " + err.Error()})
		return
	}
	if rol != "admin" {
		log.Printf("[WS] Acceso denegado. Rol '%s' no tiene acceso al Centro de Mando. IP: %s", rol, c.ClientIP())
		c.JSON(http.StatusForbidden, gin.H{"error": "Solo los administradores pueden conectarse al Centro de Mando."})
		return
	}

	// Token válido: proceder con el upgrade a WebSocket
	conn, err := upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		log.Printf("[WS] Error en upgrade: %v", err)
		return
	}

	log.Printf("[WS] Admin conectado al Centro de Mando. IP: %s", c.ClientIP())

	HubAdmin.Mutex.Lock()
	HubAdmin.Clients[conn] = true
	HubAdmin.Mutex.Unlock()

	// Enviar mensaje de bienvenida para confirmar que la conexión es segura
	conn.WriteJSON(map[string]interface{}{
		"tipo":    "CONECTADO",
		"message": "Bienvenido al Centro de Mando Seguro de Quinindé.",
	})

	// Mantener la conexión abierta y detectar desconexiones
	for {
		if _, _, err := conn.ReadMessage(); err != nil {
			HubAdmin.Mutex.Lock()
			delete(HubAdmin.Clients, conn)
			HubAdmin.Mutex.Unlock()
			log.Printf("[WS] Admin desconectado del Centro de Mando. IP: %s", c.ClientIP())
			break
		}
	}
}
