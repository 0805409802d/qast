import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qast/screens/delivery/delivery_qr_modal.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  bool _conectado = false;
  bool _isPressingPanic = false;
  Timer? _panicTimer;

  // Estados del pedido: 0 = Libre, 1 = Yendo al Local, 2 = Yendo al Cliente
  int _estadoPedido = 0; 
  
  // Datos simulados
  final String _nombreLocal = "Burger King Quinindé";
  final String _nombreCliente = "Carlos Mendoza";
  final String _direccionCliente = "Barrio 10 de Agosto, Casa 45";

  void _toggleConexion() {
    setState(() {
      _conectado = !_conectado;
    });
    
    if (_conectado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conectado. Esperando pedidos de locales...'), backgroundColor: Colors.green),
      );
      // Simular que entra un pedido a los 5 segundos de conectarse
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _conectado && _estadoPedido == 0) {
          _mostrarAlertaNuevoPedido();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Desconectado. No recibirás pedidos.'), backgroundColor: Colors.grey[800]),
      );
    }
  }

  void _mostrarAlertaNuevoPedido() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.deepOrange, size: 32),
            SizedBox(width: 8),
            Text('¡NUEVO PEDIDO!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Retirar en: $_nombreLocal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text('Entregar a: $_nombreCliente', style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            const Text('Ganancia estimada: \$1.50', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Rechazar
            },
            child: const Text('RECHAZAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _estadoPedido = 1; // Yendo al Local
              });
            },
            child: const Text('ACEPTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _avanzarEstado() {
    setState(() {
      if (_estadoPedido == 1) {
        _estadoPedido = 2; // Ya lo recogió, va al cliente
      } else if (_estadoPedido == 2) {
        _estadoPedido = 0; // Lo entregó, queda libre
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Entrega exitosa! Ganancia sumada a tu cuenta.'), backgroundColor: Colors.green),
        );
      }
    });
  }

  void _startPanicTimer() {
    setState(() {
      _isPressingPanic = true;
    });
    _panicTimer = Timer(const Duration(seconds: 2), () {
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
    _cancelPanicTimer();
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
          'El Centro de Mando ha recibido tu señal de pánico. Las autoridades están en camino a tu ubicación GPS.',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold)),
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
      builder: (context) => const DeliveryQrModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          Positioned.fill(
            child: Image.asset(
              'image/sismo-quininde-sintio-quito-700x391.jpg',
              fit: BoxFit.cover,
            ),
          ),
          
          // Capa oscura
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),

          // Header Conexión (Solo si está libre)
          if (_estadoPedido == 0)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: InkWell(
                onTap: _toggleConexion,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: _conectado ? Colors.green : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_conectado ? Icons.wifi : Icons.wifi_off, color: _conectado ? Colors.white : Colors.grey[800]),
                      const SizedBox(width: 8),
                      Text(
                        _conectado ? 'CONECTADO (ESPERANDO)' : 'DESCONECTADO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _conectado ? Colors.white : Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Panel de Misión (Si está en un pedido)
          if (_estadoPedido > 0)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _estadoPedido == 1 ? Icons.storefront : Icons.person_pin_circle,
                          color: _estadoPedido == 1 ? Colors.indigo : Colors.lightBlue,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _estadoPedido == 1 ? 'DIRÍGETE AL LOCAL' : 'ENTREGA AL CLIENTE',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                              ),
                              Text(
                                _estadoPedido == 1 ? _nombreLocal : _nombreCliente,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              if (_estadoPedido == 2)
                                Text(_direccionCliente, style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        onPressed: _avanzarEstado,
                        icon: Icon(_estadoPedido == 1 ? Icons.check_circle : Icons.done_all, color: Colors.white),
                        label: Text(
                          _estadoPedido == 1 ? 'YA RECOGÍ EL PEDIDO' : 'MARCAR COMO ENTREGADO',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

          // Alarma Visual Pánico
          if (_isPressingPanic)
            Positioned.fill(
              child: Container(
                color: Colors.red.withValues(alpha: 0.4),
                child: const Center(
                  child: Text('MANTÉN PRESIONADO...', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

          // Botón Pánico
          Positioned(
            bottom: 40,
            left: 20,
            child: GestureDetector(
              onTapDown: (_) => _startPanicTimer(),
              onTapUp: (_) => _cancelPanicTimer(),
              onTapCancel: () => _cancelPanicTimer(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _isPressingPanic ? 90 : 80,
                height: _isPressingPanic ? 90 : 80,
                decoration: BoxDecoration(
                  color: Colors.red[700],
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.6), blurRadius: 15, spreadRadius: _isPressingPanic ? 5 : 2)],
                ),
                child: const Icon(Icons.sos, color: Colors.white, size: 40),
              ),
            ),
          ),

          // Botón Mi QR
          Positioned(
            bottom: 40,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _mostrarQR,
              backgroundColor: Colors.deepOrange,
              icon: const Icon(Icons.qr_code_2, color: Colors.white),
              label: const Text('MI QR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

