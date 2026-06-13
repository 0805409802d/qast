package services

import (
	"crypto/rand"
	"fmt"
	"log"
	"os"

	"github.com/twilio/twilio-go"
	api "github.com/twilio/twilio-go/rest/api/v2010"
)

// GenerateOTP genera un código de 4 dígitos aleatorio
func GenerateOTP() string {
	b := make([]byte, 2)
	rand.Read(b)
	// Asegurar 4 dígitos
	return fmt.Sprintf("%04d", int(b[0])*256+int(b[1]))[:4]
}

// SendOTP via SMS usando Twilio
func SendOTP(telefono, codigo string) error {
	// Solo iniciar Twilio si las keys están configuradas, para desarrollo local no bloquear
	accountSid := os.Getenv("TWILIO_ACCOUNT_SID")
	if accountSid == "" || accountSid == "ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" {
		log.Printf("SIMULADO (Twilio no configurado) -> Enviando OTP [%s] a %s", codigo, telefono)
		return nil
	}

	client := twilio.NewRestClient()
	from := os.Getenv("TWILIO_SMS_NUMBER")

	msg := fmt.Sprintf("Tu código de seguridad de Quinindé Seguro es: %s", codigo)

	params := &api.CreateMessageParams{}
	params.SetTo(telefono)
	params.SetFrom(from)
	params.SetBody(msg)

	resp, err := client.Api.CreateMessage(params)
	if err != nil {
		log.Printf("Error enviando SMS: %s", err.Error())
		return err
	}
	log.Printf("SMS enviado correctamente: SID %s", *resp.Sid)
	return nil
}
