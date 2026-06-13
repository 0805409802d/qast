import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qast/screens/business/business_dashboard_screen.dart';

class BusinessSetupScreen extends StatefulWidget {
  final String telefono;
  const BusinessSetupScreen({super.key, required this.telefono});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreLocalCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  String _categoriaSeleccionada = 'Restaurante / Comida';

  final List<String> _categorias = [
    'Restaurante / Comida',
    'Farmacia',
    'Víveres y Tiendas',
    'Ropa y Moda',
    'Servicios Profesionales'
  ];

  void _guardarNegocio() {
    if (_formKey.currentState!.validate()) {
      // Simular POST /api/negocios/register
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BusinessDashboardScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('¡Negocio registrado con éxito!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green.withOpacity(0.8),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Registrar Negocio', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset(
            'image/parque-cetral-quininde-ecuadorlive.jpg',
            fit: BoxFit.cover,
          ),
          // Filtro oscuro (overlay)
          Container(
            color: Colors.black.withOpacity(0.6),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Datos de tu Local',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Para que los clientes puedan encontrarte en el Marketplace.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 32),
                          _buildGlassTextField(
                            controller: TextEditingController(text: widget.telefono),
                            enabled: false,
                            hintText: 'Teléfono de Contacto',
                            icon: Icons.phone,
                          ),
                          const SizedBox(height: 16),
                          _buildGlassTextField(
                            controller: _nombreLocalCtrl,
                            hintText: 'Nombre del Local',
                            icon: Icons.store,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildGlassDropdown(
                            value: _categoriaSeleccionada,
                            hintText: 'Categoría',
                            icon: Icons.category,
                            items: _categorias,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _categoriaSeleccionada = newValue;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildGlassTextField(
                            controller: _direccionCtrl,
                            hintText: 'Dirección Exacta en Quinindé',
                            icon: Icons.map,
                            maxLines: 2,
                            validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          ),
                          const SizedBox(height: 32),
                          _buildGradientButton(
                            text: 'ABRIR MI TIENDA VIRTUAL',
                            onPressed: _guardarNegocio,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          errorStyle: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String value,
    required String hintText,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: const Color(0xFF2D2D2D), // Un fondo oscuro para el popup
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          border: InputBorder.none,
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.8)),
        items: items.map((String cat) {
          return DropdownMenuItem<String>(
            value: cat,
            child: Text(cat),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)], // Indigo a Purpura
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }
}
