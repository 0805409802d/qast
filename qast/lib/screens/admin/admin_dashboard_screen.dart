import 'package:flutter/material.dart';
import 'dart:async';
import 'package:qast/screens/admin/admin_approvals_screen.dart';
import 'package:qast/screens/admin/admin_caja_screen.dart';
import 'package:qast/screens/admin/create_admin_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      _RadarPanel(onAlertaCreada: _onAlertaCreada),
      const AdminApprovalsScreen(),
      const AdminCajaScreen(),
    ];
  }

  // Recibe notificaciones del panel de radar (en producción vendrían del WebSocket)
  void _onAlertaCreada(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[900], // Rojo intenso
        duration: const Duration(seconds: 8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Fondo limpio para resaltar tarjetas blancas
      appBar: AppBar(
        backgroundColor: Colors.green[900], // Verde institucional muy oscuro y formal
        elevation: 4,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.security, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'CENTRO DE MANDO',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Añadir Administrador',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateAdminScreen()),
              );
            },
          )
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2))
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(icon: Icon(Icons.radar), label: 'Radar'),
            BottomNavigationBarItem(icon: Icon(Icons.people_alt), label: 'Directorio'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance), label: 'Caja Municipal'),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green[800],
          unselectedItemColor: Colors.grey[500],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class _RadarPanel extends StatefulWidget {
  final void Function(String mensaje) onAlertaCreada;
  const _RadarPanel({required this.onAlertaCreada});

  @override
  State<_RadarPanel> createState() => _RadarPanelState();
}

class _RadarPanelState extends State<_RadarPanel> {
  // --- DATOS MOCK EN TIEMPO REAL ---
  final List<Map<String, dynamic>> _alertas = [];
  int _conductoresActivos = 7;
  int _pedidosEnCurso = 3;
  Timer? _mockTimer;

  // Alertas simuladas que van llegando como si fueran del WebSocket
  static const List<Map<String, String>> _alertasMock = [
    {'tipo': 'PANICO_CLIENTE', 'mensaje': 'PÁNICO: María López • Moto ABC-123', 'color': 'rojo'},
    {'tipo': 'CONDUCTOR_ONLINE', 'mensaje': 'Pedro Quiñónez se conectó', 'color': 'verde'},
    {'tipo': 'VIAJE_COMPLETADO', 'mensaje': 'Viaje finalizado • Carlos M. → Barrio 10 de Agosto', 'color': 'azul'},
    {'tipo': 'PEDIDO_NUEVO', 'mensaje': 'Nuevo pedido en Restaurante El Buen Gusto', 'color': 'naranja'},
    {'tipo': 'PANICO_CHOFER', 'mensaje': 'PÁNICO CHOFER: Luis Torres • Placa MNO-456', 'color': 'rojo'},
    {'tipo': 'CONDUCTOR_OFFLINE', 'mensaje': 'Ana Gómez se desconectó', 'color': 'gris'},
  ];

  int _mockIndex = 0;

  @override
  void initState() {
    super.initState();
    _iniciarMockFeed();
  }

  void _iniciarMockFeed() {
    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) { timer.cancel(); return; }
      final evento = _alertasMock[_mockIndex % _alertasMock.length];
      _mockIndex++;

      setState(() {
        _alertas.insert(0, {
          ...evento,
          'hora': _horaActual(),
        });
        if (_alertas.length > 20) _alertas.removeLast();

        if (evento['tipo'] == 'CONDUCTOR_ONLINE') _conductoresActivos++;
        if (evento['tipo'] == 'CONDUCTOR_OFFLINE' && _conductoresActivos > 0) _conductoresActivos--;
        if (evento['tipo'] == 'PEDIDO_NUEVO') _pedidosEnCurso++;
        if (evento['tipo'] == 'VIAJE_COMPLETADO' && _pedidosEnCurso > 0) _pedidosEnCurso--;
      });

      if (evento['tipo']?.startsWith('PANICO') == true) {
        widget.onAlertaCreada(evento['mensaje']!);
      }
    });
  }

  String _horaActual() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  IconData _getIconForAlert(String colorKey) {
    switch (colorKey) {
      case 'rojo': return Icons.warning_rounded;
      case 'verde': return Icons.login;
      case 'azul': return Icons.check_circle_outline;
      case 'naranja': return Icons.shopping_bag_outlined;
      default: return Icons.logout;
    }
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Indicador de conexión en tiempo real
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: Colors.green[800],
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PulsingDot(),
              SizedBox(width: 8),
              Text(
                'ENLACE SATELITAL ACTIVO • CANAL ENCRIPTADO',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.two_wheeler,
                  label: 'CONDUCTORES',
                  value: _conductoresActivos.toString(),
                  color: Colors.green[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.local_shipping,
                  label: 'PEDIDOS',
                  value: _pedidosEnCurso.toString(),
                  color: Colors.orange[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.sos,
                  label: 'ALERTAS',
                  value: _alertas.where((a) => a['tipo']?.startsWith('PANICO') == true).length.toString(),
                  color: Colors.red[900]!, // Rojo intenso
                ),
              ),
            ],
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.list_alt, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'REGISTRO DE OPERACIONES',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2, color: Colors.black87),
              ),
            ],
          ),
        ),

        // Feed de alertas en tiempo real
        Expanded(
          child: _alertas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.green),
                      const SizedBox(height: 16),
                      Text(
                        'Escuchando eventos en tiempo real...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _alertas.length,
                  itemBuilder: (context, index) {
                    final alerta = _alertas[index];
                    final isRojo = alerta['color'] == 'rojo';
                    final esNueva = index == 0;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 600),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        // Tarjetas blancas limpias, excepto si es rojo que tiene un fondo super sutil rojo
                        color: isRojo ? Colors.red[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isRojo ? Colors.red.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                            blurRadius: isRojo ? 12 : 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                        // Borde uniforme para evitar crasheo con borderRadius
                        border: Border.all(
                          color: isRojo ? Colors.red[900]! : (alerta['color'] == 'verde' ? Colors.green : (alerta['color'] == 'naranja' ? Colors.orange : Colors.blue)),
                          width: 1.5,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isRojo ? Colors.red[100] : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForAlert(alerta['color']),
                            color: isRojo ? Colors.red[900] : Colors.black87,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          alerta['mensaje'] ?? '',
                          style: TextStyle(
                            fontWeight: isRojo ? FontWeight.w900 : (esNueva ? FontWeight.bold : FontWeight.w500),
                            color: isRojo ? Colors.red[900] : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        trailing: Text(
                          alerta['hora'] ?? '',
                          style: TextStyle(
                            color: isRojo ? Colors.red[700] : Colors.black45,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// Tarjeta de estadística profesional (Card blanca con Accent Border)
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        // No se puede usar Border no uniforme con borderRadius en Flutter.
        // Lo reemplazamos con un borde uniforme muy suave.
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// Punto verde pulsante que indica conexión activa
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 6, spreadRadius: 2)
          ],
        ),
      ),
    );
  }
}
