package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

// BaseModel is a custom GORM model that uses UUIDs instead of uints for IDs
type BaseModel struct {
	ID        uuid.UUID      `gorm:"type:uuid;default:uuid_generate_v4();primaryKey"`
	CreadoEn  time.Time      `gorm:"autoCreateTime"`
}

func (base *BaseModel) BeforeCreate(tx *gorm.DB) (err error) {
	if base.ID == uuid.Nil {
		base.ID = uuid.New() // Generate a new UUID if not provided. Needs github.com/google/uuid in go.mod
	}
	return
}

type Usuario struct {
	BaseModel
	Telefono           string `gorm:"unique;not null"`
	Correo             string `gorm:"unique"`
	PasswordHash       string
	Nombre             string
	Apellidos          string
	Cedula             string
	ContactoEmergencia string
	CelularEmergencia  string
	Rol                string `gorm:"default:'cliente'"`
}

type Conductor struct {
	BaseModel
	UsuarioID           uuid.UUID
	Cedula              string `gorm:"unique;not null"`
	TipoSangre          string
	Matricula           string `gorm:"unique"`
	LicenciaConducir    string
	DocumentosUrl       string
	EstadoAprobacion    string `gorm:"default:'pendiente'"`
	EstadoConexion      bool   `gorm:"default:false"`
	QrID                string `gorm:"unique"`
	SuscripcionActiva   bool   `gorm:"default:false"`
	FechaFinSuscripcion *time.Time
}

type PagoSuscripcion struct {
	BaseModel
	ConductorID         uuid.UUID
	Monto               float64 `gorm:"default:20.00"`
	MetodoPago          string
	FechaPago           time.Time `gorm:"autoCreateTime"`
	ValidoHasta         time.Time
	RegistradoPorAdminID uuid.UUID
}

type OtpCode struct {
	BaseModel
	Telefono string    `gorm:"not null"`
	Codigo   string    `gorm:"not null"`
	ExpiraEn time.Time `gorm:"not null"`
	Usado    bool      `gorm:"default:false"`
}

type Configuracion struct {
	BaseModel
	Clave       string `gorm:"unique;not null"`
	Valor       string `gorm:"not null"`
	Descripcion string
}

type TarifaFija struct {
	BaseModel
	OrigenNombre  string  `gorm:"not null"`
	DestinoNombre string  `gorm:"not null"`
	Precio        float64 `gorm:"not null"`
}

type Viaje struct {
	BaseModel
	ClienteID   uuid.UUID
	ConductorID *uuid.UUID
	Estado      string  `gorm:"default:'pendiente'"`
	Tarifa      float64
	OrigenLat   float64
	OrigenLng   float64
	DestinoLat  float64
	DestinoLng  float64
}

type Negocio struct {
	BaseModel
	UsuarioID       uuid.UUID
	NombreComercial string `gorm:"not null"`
	Direccion       string
	EstadoAbierto   bool `gorm:"default:true"`
}

type Producto struct {
	BaseModel
	NegocioID          uuid.UUID
	Titulo             string  `gorm:"not null"`
	Descripcion        string
	Precio             float64 `gorm:"not null"`
	FotoUrl            string
	CantidadDisponible int `gorm:"default:-1"`
}

type PedidoDelivery struct {
	BaseModel
	ClienteID   uuid.UUID
	NegocioID   uuid.UUID
	ConductorID *uuid.UUID
	DetalleJson string  `gorm:"not null"`
	Estado      string  `gorm:"default:'pendiente'"`
	Total       float64 `gorm:"not null"`
}

