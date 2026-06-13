import 'package:flutter/material.dart';
import 'dart:ui'; // Necesario para ImageFilter.blur
import 'package:qast/screens/admin/admin_login_screen.dart';
import 'package:qast/screens/driver/driver_login_screen.dart';
import 'package:qast/screens/client/client_login_screen.dart';
import 'package:qast/screens/business/business_login_screen.dart';
import 'package:qast/screens/delivery/delivery_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Widget _buildGlassCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
        },
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withValues(alpha: 0.3),
        highlightColor: color.withValues(alpha: 0.1),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminLoginScreen()));
      },
      borderRadius: BorderRadius.circular(24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text(
                  'ACCESO ADMINISTRATIVO',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Imagen de Fondo a Pantalla Completa
          Positioned.fill(
            child: Image.asset(
              'image/Monumento-de-Quininde-scaled.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 2. Gradiente Oscuro (Mejora legibilidad sin ocultar el fondo)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 3. Contenido Principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Header
                  const Center(
                    child: Icon(
                      Icons.shield,
                      size: 64,
                      color: Colors.greenAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Quinindé Seguro',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu ciudad, en tus manos.\nSelecciona cómo deseas ingresar hoy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  
                  const Spacer(),

                  // Grid de Roles (Glassmorphism)
                  Row(
                    children: [
                      _buildGlassCard(
                        context: context,
                        title: 'Transporte\nSeguro',
                        icon: Icons.local_taxi,
                        color: Colors.yellowAccent,
                        destination: const DriverLoginScreen(),
                      ),
                      const SizedBox(width: 16),
                      _buildGlassCard(
                        context: context,
                        title: 'Delivery\nEncargos',
                        icon: Icons.delivery_dining,
                        color: Colors.orangeAccent,
                        destination: const DeliveryLoginScreen(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildGlassCard(
                        context: context,
                        title: 'Soy\nPasajero',
                        icon: Icons.person,
                        color: Colors.lightBlueAccent,
                        destination: const ClientLoginScreen(),
                      ),
                      const SizedBox(width: 16),
                      _buildGlassCard(
                        context: context,
                        title: 'Dueño de\nNegocio',
                        icon: Icons.storefront,
                        color: Colors.indigoAccent,
                        destination: const BusinessLoginScreen(),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Botón de Admin
                  _buildAdminButton(context),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
