-- Schema Seguro para Supabase con RLS y Control de Suscripciones

-- Habilitar extensión para UUIDs si no está habilitada
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

---------------------------------------------------------------------------
-- 1. TABLAS PRINCIPALES
---------------------------------------------------------------------------

-- Tabla Usuarios (Pasajeros y base para Choferes/Admins)
CREATE TABLE public.usuarios (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    telefono VARCHAR(20) UNIQUE NOT NULL,
    correo VARCHAR(100) UNIQUE,
    password_hash VARCHAR(255),
    nombre VARCHAR(100),
    apellidos VARCHAR(100),
    cedula VARCHAR(20),
    contacto_emergencia VARCHAR(100),
    celular_emergencia VARCHAR(20),
    rol VARCHAR(20) DEFAULT 'cliente', -- cliente, conductor, negocio, admin
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla Conductores (Manejo de Taxis/Motos y la Suscripción Anual)
CREATE TABLE public.conductores (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    usuario_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    cedula VARCHAR(20) UNIQUE NOT NULL,
    tipo_sangre VARCHAR(10),
    matricula VARCHAR(20) UNIQUE,
    licencia_conducir VARCHAR(50),
    documentos_url TEXT,
    estado_aprobacion VARCHAR(20) DEFAULT 'pendiente', -- pendiente, aprobado, rechazado
    estado_conexion BOOLEAN DEFAULT false,             -- true: conectado
    qr_id VARCHAR(50) UNIQUE,
    suscripcion_activa BOOLEAN DEFAULT false,          -- Control de pago anual ($20)
    fecha_fin_suscripcion TIMESTAMP WITH TIME ZONE,    -- Hasta cuándo es válido
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla Pagos de Suscripción (Registro histórico de los cobros de $20)
CREATE TABLE public.pagos_suscripcion (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    conductor_id UUID REFERENCES public.conductores(id) ON DELETE CASCADE,
    monto DECIMAL(10, 2) NOT NULL DEFAULT 20.00,
    metodo_pago VARCHAR(50), -- efectivo, transferencia
    fecha_pago TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    valido_hasta TIMESTAMP WITH TIME ZONE NOT NULL,
    registrado_por_admin_id UUID REFERENCES public.usuarios(id) -- Quién validó el pago
);

-- Tabla Códigos OTP Temporales
CREATE TABLE public.otp_codes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    telefono VARCHAR(20) NOT NULL,
    codigo VARCHAR(6) NOT NULL,
    expira_en TIMESTAMP WITH TIME ZONE NOT NULL,
    usado BOOLEAN DEFAULT false,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla Viajes
CREATE TABLE public.viajes (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    cliente_id UUID REFERENCES public.usuarios(id),
    conductor_id UUID REFERENCES public.conductores(id),
    estado VARCHAR(20) DEFAULT 'pendiente', -- pendiente, activo, completado, emergencia
    tarifa DECIMAL(10, 2),
    origen_lat DECIMAL(10, 8),
    origen_lng DECIMAL(11, 8),
    destino_lat DECIMAL(10, 8),
    destino_lng DECIMAL(11, 8),
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla Configuraciones Sistema
CREATE TABLE public.configuraciones (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    clave VARCHAR(50) UNIQUE NOT NULL,
    valor VARCHAR(200) NOT NULL,
    descripcion TEXT
);

-- Tabla Tarifas Fijas
CREATE TABLE public.tarifas_fijas (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    origen_nombre VARCHAR(100) NOT NULL,
    destino_nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10, 2) NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla Negocios
CREATE TABLE public.negocios (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    usuario_id UUID REFERENCES public.usuarios(id) ON DELETE CASCADE,
    nombre_comercial VARCHAR(100) NOT NULL,
    direccion TEXT,
    estado_abierto BOOLEAN DEFAULT true,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla Productos
CREATE TABLE public.productos (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    negocio_id UUID REFERENCES public.negocios(id) ON DELETE CASCADE,
    titulo VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio DECIMAL(10, 2) NOT NULL,
    foto_url TEXT,
    cantidad_disponible INT DEFAULT -1, -- -1 significa ilimitado
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Tabla Pedidos Delivery (Simplificada)
CREATE TABLE public.pedidos_delivery (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    cliente_id UUID REFERENCES public.usuarios(id),
    negocio_id UUID REFERENCES public.negocios(id),
    conductor_id UUID REFERENCES public.conductores(id),
    detalle_json TEXT NOT NULL, -- Ej: "2x Hamburguesa, 1x Cola"
    estado VARCHAR(20) DEFAULT 'pendiente', -- pendiente, preparando, listo, en_camino, entregado
    total DECIMAL(10, 2) NOT NULL,
    creado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    actualizado_en TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

---------------------------------------------------------------------------
-- 2. ROW LEVEL SECURITY (RLS) POLICIES
---------------------------------------------------------------------------
-- Como nuestro backend en Go se conectará usando la clave "Service Role" o 
-- con credenciales maestras de Postgres, el backend bypasses RLS.
-- Sin embargo, activamos RLS y lo bloqueamos para las claves anónimas/públicas
-- (anon key) de Supabase, evitando que alguien extraiga los datos si la API 
-- Key pública se filtra desde la app móvil.

ALTER TABLE public.usuarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conductores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pagos_suscripcion ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.otp_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.viajes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.configuraciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tarifas_fijas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.negocios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.pedidos_delivery ENABLE ROW LEVEL SECURITY;

-- Política restrictiva: Solo el Backend (postgres role/service_role) puede leer y escribir.
-- Las peticiones públicas de Supabase (anon) no pueden hacer nada.
CREATE POLICY "Denegar todo acceso publico anonimo a usuarios" ON public.usuarios FOR ALL TO anon USING (false);
CREATE POLICY "Denegar todo acceso publico anonimo a conductores" ON public.conductores FOR ALL TO anon USING (false);
CREATE POLICY "Denegar todo acceso publico anonimo a viajes" ON public.viajes FOR ALL TO anon USING (false);
CREATE POLICY "Denegar todo acceso publico anonimo a otp" ON public.otp_codes FOR ALL TO anon USING (false);
CREATE POLICY "Denegar todo acceso publico anonimo a negocios" ON public.negocios FOR ALL TO anon USING (false);
CREATE POLICY "Denegar todo acceso publico anonimo a productos" ON public.productos FOR ALL TO anon USING (false);
CREATE POLICY "Denegar todo acceso publico anonimo a pedidos" ON public.pedidos_delivery FOR ALL TO anon USING (false);

---------------------------------------------------------------------------
-- 3. TRIGGERS DE LÓGICA DE NEGOCIO
---------------------------------------------------------------------------
-- Función para limpiar OTPs expirados automáticamente
CREATE OR REPLACE FUNCTION limpiar_otp_expirados() RETURNS void AS $$
BEGIN
    DELETE FROM public.otp_codes WHERE expira_en < NOW() OR usado = true;
END;
$$ LANGUAGE plpgsql;

-- (Puedes llamar a `limpiar_otp_expirados()` periódicamente mediante pg_cron en Supabase)
