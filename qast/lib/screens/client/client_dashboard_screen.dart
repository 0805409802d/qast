import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qast/screens/client/client_marketplace_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  bool _enViaje = false;
  bool _buscandoMoto = false;

  // --- MOCK DE MAPA ANIMADO ---
  double _motoProgress = 0.0;
  Timer? _motoTimer;
  static const List<Offset> _rutaMock = [
    Offset(0.15, 0.20),
    Offset(0.22, 0.25),
    Offset(0.30, 0.28),
    Offset(0.38, 0.33),
    Offset(0.45, 0.38),
    Offset(0.48, 0.43),
    Offset(0.49, 0.47),
    Offset(0.50, 0.52),
  ];
  int _rutaIndex = 0;

  void _iniciarBusqueda() {
    setState(() {
      _buscandoMoto = true;
      _motoProgress = 0.0;
      _rutaIndex = 0;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🏍️ ¡Juan Pérez aceptó tu viaje! Viene en camino...', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _iniciarAnimacionMoto();
    });
  }

  void _iniciarAnimacionMoto() {
    _motoTimer?.cancel();
    _motoTimer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_rutaIndex < _rutaMock.length - 1) {
          _rutaIndex++;
          _motoProgress = _rutaIndex / (_rutaMock.length - 1);
        } else {
          timer.cancel();
          _buscandoMoto = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('🛵 ¡El conductor llegó! Escanea su QR para iniciar.', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.lightBlueAccent.withOpacity(0.8),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    });
  }

  void _escanearQR() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D2D2D).withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.lightBlueAccent, size: 32),
                      SizedBox(width: 8),
                      Text('Escanear QR', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('¿Simular escaneo exitoso del Gafete del Conductor?', style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCELAR', style: TextStyle(color: Colors.white54)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent),
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {
                            _enViaje = true;
                            _buscandoMoto = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('✅ Viaje Seguro vinculado con éxito', style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.green.withOpacity(0.8),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: const Text('SIMULAR ÉXITO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _detonarPanico() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red[900]!.withOpacity(0.85),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 50),
                  const SizedBox(height: 16),
                  const Text('¡ALERTA ENVIADA!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  const Text(
                    'Tus datos y la placa del conductor han sido enviados a la policía municipal de Quinindé. Mantén la calma.',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('ENTENDIDO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _motoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double safeAreaTop = MediaQuery.of(context).padding.top;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Imagen de fondo (mapa de Quinindé)
          Image.asset(
            'image/sismo-quininde-sintio-quito-700x391.jpg',
            fit: BoxFit.cover,
          ),

          // 2. Capa de sombra ligera
          Container(color: Colors.black.withOpacity(0.2)),

          // --- MOCK ANIMADO: Ícono de la moto moviéndose hacia el cliente ---
          if (_buscandoMoto && _rutaIndex < _rutaMock.length)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1600),
              curve: Curves.easeInOut,
              left: _rutaMock[_rutaIndex].dx * size.width - 24,
              top: _rutaMock[_rutaIndex].dy * size.height - 24,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
                    ),
                    child: const Icon(Icons.two_wheeler, color: Colors.lightBlue, size: 32),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.lightBlue, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      _motoProgress >= 1.0 ? '¡Llegó!' : 'Juan P.',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

          // Marcador de tu posición (punto azul fijo)
          if (_buscandoMoto)
            Positioned(
              bottom: size.height * 0.4,
              left: 0,
              right: 0,
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.6), blurRadius: 12, spreadRadius: 4)],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(12)),
                      child: const Text('Tu ubicación', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ),
                  ],
                ),
              ),
            ),

          // Panel de llegada con barra de progreso
          if (_buscandoMoto)
            Positioned(
              top: safeAreaTop + 16,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.lightBlueAccent.withOpacity(0.3), shape: BoxShape.circle),
                              child: const Icon(Icons.person, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Juan Pérez', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                Text('Moto • ABC-123 • ⭐ 4.9', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: LinearProgressIndicator(
                            value: _motoProgress,
                            minHeight: 10,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _motoProgress >= 1.0
                              ? '¡Tu conductor llegó! Escanea su QR.'
                              : 'Llegando en aprox. ${((1 - _motoProgress) * 8).ceil()} min...',
                          style: TextStyle(
                            color: _motoProgress >= 1.0 ? Colors.greenAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 3. Barra de búsqueda (cuando está libre)
          if (!_enViaje && !_buscandoMoto)
            Positioned(
              top: safeAreaTop + 16,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: TextField(
                      readOnly: true,
                      onTap: _iniciarBusqueda,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '¿A dónde quieres ir hoy?',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        suffixIcon: GestureDetector(
                          onTap: _iniciarBusqueda,
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Colors.lightBlueAccent, Colors.blue]),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.lightBlue.withOpacity(0.5), blurRadius: 5)]
                            ),
                            child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 4. Panel inferior de acciones (libre)
          if (!_enViaje && !_buscandoMoto)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _iniciarBusqueda,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.lightBlueAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.4)),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.two_wheeler, size: 48, color: Colors.lightBlueAccent),
                                  SizedBox(height: 12),
                                  Text('Transporte\nSeguro', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientMarketplaceScreen()));
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.orangeAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.orangeAccent.withOpacity(0.4)),
                              ),
                              child: const Column(
                                children: [
                                  Icon(Icons.local_shipping, size: 48, color: Colors.orangeAccent),
                                  SizedBox(height: 12),
                                  Text('Delivery\nEncargos', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 5. Botón Escanear QR (cuando el conductor ya llegó)
          if (_buscandoMoto && _motoProgress >= 1.0)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(colors: [Colors.lightBlueAccent, Colors.blue]),
                  boxShadow: [BoxShadow(color: Colors.lightBlue.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: _escanearQR,
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                  label: const Text(
                    'ESCANEAR QR DEL CONDUCTOR',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
                  ),
                ),
              ),
            ),

          // 6. Panel de Viaje Activo + Botón de Pánico
          if (_enViaje)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'VIAJE SEGURO ACTIVO',
                              style: TextStyle(fontWeight: FontWeight.w900, color: Colors.greenAccent, letterSpacing: 1.5, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.greenAccent)),
                              child: const Text('En progreso', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Colors.white.withOpacity(0.2), thickness: 1),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.lightBlueAccent.withOpacity(0.3), shape: BoxShape.circle),
                            child: const Icon(Icons.person, color: Colors.white, size: 28),
                          ),
                          title: const Text('Juan Pérez', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                          subtitle: Text('Matrícula: ABC-123', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15)),
                          trailing: const Icon(Icons.star, color: Colors.amber, size: 28),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFD32F2F)]),
                                  boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]
                                ),
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: _detonarPanico,
                                  icon: const Icon(Icons.sos, color: Colors.white),
                                  label: const Text(
                                    'BOTÓN PÁNICO',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _enViaje = false;
                                    _buscandoMoto = false;
                                    _motoProgress = 0.0;
                                    _rutaIndex = 0;
                                  });
                                },
                                child: const Text('Finalizar Viaje', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
