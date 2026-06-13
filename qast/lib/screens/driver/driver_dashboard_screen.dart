import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qast/screens/driver/driver_qr_modal.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  bool _conectado = false;
  bool _isPressingPanic = false;
  Timer? _panicTimer;
  Timer? _viajeTimer;
  Timer? _countdownTimer;

  // Estado del viaje: null = libre, Map = viaje asignado
  Map<String, String>? _viajeActual;
  int _countdown = 15; // Segundos para aceptar o rechazar

  void _toggleConexion() {
    setState(() {
      _conectado = !_conectado;
    });

    if (_conectado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🟢 En línea. Buscando viajes...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      // MOCK: Simular que entra un viaje a los 6 segundos de conectarse
      _viajeTimer = Timer(const Duration(seconds: 6), () {
        if (mounted && _conectado && _viajeActual == null) {
          _recibirViajesMock();
        }
      });
    } else {
      _viajeTimer?.cancel();
      _countdownTimer?.cancel();
      setState(() => _viajeActual = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🔴 Desconectado. No recibirás viajes.'),
          backgroundColor: Colors.grey[800],
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _recibirViajesMock() {
    setState(() {
      _viajeActual = {
        'cliente': 'María López',
        'origen': 'Parque Central',
        'destino': 'Barrio 10 de Agosto',
        'precio': '\$2.00',
        'distancia': '1.2 km',
      };
      _countdown = 15;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        timer.cancel();
        setState(() => _viajeActual = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Viaje ignorado.'), duration: Duration(seconds: 2)),
        );
        _viajeTimer = Timer(const Duration(seconds: 8), () {
          if (mounted && _conectado) _recibirViajesMock();
        });
      }
    });
  }

  void _aceptarViaje() {
    _countdownTimer?.cancel();
    _viajeTimer?.cancel();
    setState(() => _viajeActual = null);
    _mostrarQR();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Viaje aceptado. Dirígete al origen.'), backgroundColor: Colors.green),
    );
  }

  void _rechazarViaje() {
    _countdownTimer?.cancel();
    setState(() {
      _viajeActual = null;
      _countdown = 15;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Viaje rechazado.'), duration: Duration(seconds: 2)),
    );
    _viajeTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _conectado) _recibirViajesMock();
    });
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    _viajeTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startPanicTimer() {
    setState(() {
      _isPressingPanic = true;
    });
    _panicTimer = Timer(const Duration(seconds: 3), () {
      if (_isPressingPanic) {
        _detonarPanico();
      }
    });
  }

  void _cancelPanicTimer() {
    setState(() {
      _isPressingPanic = false;
    });
    _panicTimer?.cancel();
  }

  void _detonarPanico() {
    setState(() {
      _isPressingPanic = false;
    });
    // Lógica para detonar pánico (vibración, API, etc.)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.white, size: 32),
            SizedBox(width: 8),
            Text('¡ALERTA ENVIADA!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'El Centro de Mando municipal y la policía han recibido tu ubicación. Mantén la calma.',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _mostrarQR() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DriverQrModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de Fondo (Mapa)
          Positioned.fill(
            child: Image.asset(
              'image/sismo-quininde-sintio-quito-700x391.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // 2. Capa súper clara para simular el mapa de día (legibilidad exterior)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),

          // 3. Header Flotante (Botón Conectarse) - Tamaño Masivo y Contraste
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: InkWell(
              onTap: _toggleConexion,
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: _conectado ? Colors.green[800] : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _conectado ? Colors.green[900]! : Colors.grey[400]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _conectado ? Colors.green[600] : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _conectado ? Icons.wifi : Icons.power_settings_new,
                        color: _conectado ? Colors.white : Colors.grey[600],
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _conectado ? 'EN LÍNEA' : 'DESCONECTADO',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: _conectado ? Colors.white : Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Panel de solicitud de viaje entrante
          if (_viajeActual != null)
            Positioned(
              bottom: 140,
              left: 16,
              right: 16,
              child: Material(
                elevation: 16,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.green, width: 3),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.person_pin, color: Colors.green, size: 28),
                              SizedBox(width: 8),
                              Text(
                                'NUEVO VIAJE',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.black87),
                              ),
                            ],
                          ),
                          // Countdown circular grande
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  value: _countdown / 15,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                  strokeWidth: 6,
                                ),
                              ),
                              Text(
                                '$_countdown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.circle, color: Colors.green, size: 16),
                              Container(height: 24, width: 2, color: Colors.grey),
                              const Icon(Icons.location_on, color: Colors.green, size: 16),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_viajeActual!['origen']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 20),
                                Text(_viajeActual!['destino']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _viajeActual!['precio']!,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 28, color: Colors.green),
                              ),
                              Text(_viajeActual!['distancia']!, style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey, width: 2),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: _rechazarViaje,
                              child: const Text('RECHAZAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              onPressed: _aceptarViaje,
                              child: const Text('ACEPTAR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.0)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 5. Botón Mi QR (Inferior Derecha) - Tema Institucional
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _mostrarQR,
              backgroundColor: Colors.white,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              icon: const Icon(Icons.qr_code_2, color: Colors.green, size: 28),
              label: const Text('MI GAFETE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
            ),
          ),

          // 6. Indicador Visual de Pánico Overlay
          if (_isPressingPanic)
            Positioned.fill(
              child: Container(
                color: Colors.red.withValues(alpha: 0.3),
              ),
            ),

          // 7. Botón de Pánico (Flotante Inferior Izquierda)
          Positioned(
            bottom: 40,
            left: 20,
            child: GestureDetector(
              onTapDown: (_) => _startPanicTimer(),
              onTapUp: (_) => _cancelPanicTimer(),
              onTapCancel: () => _cancelPanicTimer(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isPressingPanic ? 90 : 70,
                height: _isPressingPanic ? 90 : 70,
                decoration: BoxDecoration(
                  color: Colors.red[800],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5), 
                      blurRadius: _isPressingPanic ? 25 : 10, 
                      spreadRadius: _isPressingPanic ? 10 : 2
                    )
                  ],
                ),
                child: const Icon(Icons.sos, color: Colors.white, size: 36),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
