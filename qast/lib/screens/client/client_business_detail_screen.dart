import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientBusinessDetailScreen extends StatefulWidget {
  final Map<String, dynamic> negocio;
  const ClientBusinessDetailScreen({super.key, required this.negocio});

  @override
  State<ClientBusinessDetailScreen> createState() => _ClientBusinessDetailScreenState();
}

class _ClientBusinessDetailScreenState extends State<ClientBusinessDetailScreen> {
  // Productos simulados
  final List<Map<String, dynamic>> _productos = [
    {'id': 'p1', 'nombre': 'Combo Clásico', 'desc': 'Hamburguesa + Papas + Gaseosa', 'precio': 5.50},
    {'id': 'p2', 'nombre': 'Hamburguesa Doble Carne', 'desc': 'Doble carne de res con queso', 'precio': 4.00},
    {'id': 'p3', 'nombre': 'Porción de Papas Fritas', 'desc': 'Papas rústicas con salsa', 'precio': 2.00},
    {'id': 'p4', 'nombre': 'Gaseosa 1 Litro', 'desc': 'Coca Cola bien fría', 'precio': 1.50},
  ];

  // Carrito local
  final List<Map<String, dynamic>> _carrito = [];

  void _agregarAlCarrito(Map<String, dynamic> prod) {
    setState(() {
      _carrito.add(prod);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${prod['nombre']} añadido al carrito', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.lightBlueAccent.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _abrirCarritoBottomSheet() {
    if (_carrito.isEmpty) return;

    double total = _carrito.fold(0, (sum, item) => sum + item['precio']);
    String metodoPago = 'Efectivo';
    String notas = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.85,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E).withOpacity(0.85),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2))),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(width: 50, height: 6, decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
                      ),
                      const SizedBox(height: 24),
                      const Text('Tu Pedido', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 16),
                      
                      // Lista de items en el carrito
                      Expanded(
                        child: ListView.builder(
                          itemCount: _carrito.length,
                          itemBuilder: (context, i) {
                            final item = _carrito[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['nombre'], style: const TextStyle(color: Colors.white, fontSize: 16)),
                                  Text('\$${item['precio'].toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Divider(thickness: 1, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total a Pagar:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('\$${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Opciones de Pago
                      const Text('Método de Pago', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          selectedForegroundColor: Colors.white,
                          selectedBackgroundColor: Colors.lightBlueAccent.withOpacity(0.4),
                          side: BorderSide(color: Colors.white.withOpacity(0.2)),
                        ),
                        segments: const [
                          ButtonSegment(value: 'Efectivo', label: Text('Efectivo al Repartidor')),
                          ButtonSegment(value: 'Transferencia', label: Text('Transferencia')),
                        ],
                        selected: {metodoPago},
                        onSelectionChanged: (Set<String> newSelection) {
                          setModalState(() {
                            metodoPago = newSelection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Notas
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Ej. Sin cebolla, o billete de \$20',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.2))),
                        ),
                        onChanged: (v) => notas = v,
                      ),
                      const SizedBox(height: 32),

                      // Botón Enviar a WhatsApp
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [Colors.green, Colors.lightGreen]),
                          boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                          onPressed: () {
                            _enviarPedidoWhatsApp(total, metodoPago, notas);
                          },
                          icon: const Icon(Icons.send, color: Colors.white),
                          label: const Text('ENVIAR PEDIDO POR WHATSAPP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _enviarPedidoWhatsApp(double total, String metodoPago, String notas) async {
    String mensaje = "Hola *${widget.negocio['nombre']}*! Quiero hacer el siguiente pedido:\n\n";
    for (var p in _carrito) {
      mensaje += "- ${p['nombre']} (\$${p['precio'].toStringAsFixed(2)})\n";
    }
    mensaje += "\n*Total:* \$${total.toStringAsFixed(2)}\n";
    mensaje += "*Método de Pago:* $metodoPago\n";
    if (notas.isNotEmpty) {
      mensaje += "*Notas:* $notas\n";
    }
    mensaje += "\nEspero la confirmación para que me envíen al repartidor de Quinindé Seguro. Gracias!";

    String telefonoNegocio = "+593999999999"; 
    final url = Uri.parse("https://wa.me/$telefonoNegocio?text=${Uri.encodeComponent(mensaje)}");

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir WhatsApp')));
      }
    } else {
      if (mounted) {
        Navigator.pop(context); // Cierra bottom sheet
        Navigator.pop(context); // Regresa al marketplace
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.negocio['nombre'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black.withOpacity(0.3),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo oscuro
          Image.asset(
            'image/parque-cetral-quininde-ecuadorlive.jpg',
            fit: BoxFit.cover,
          ),
          Container(color: Colors.black.withOpacity(0.6)), // Overlay oscuro

          SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100),
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final prod = _productos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prod['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                                  const SizedBox(height: 8),
                                  Text(prod['desc'], style: TextStyle(color: Colors.white.withOpacity(0.7))),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.greenAccent.withOpacity(0.5))
                                    ),
                                    child: Text('\$${prod['precio'].toStringAsFixed(2)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.lightBlueAccent.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.lightBlueAccent.withOpacity(0.5))
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 28),
                              ),
                              onPressed: () => _agregarAlCarrito(prod),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _carrito.isNotEmpty ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(colors: [Colors.lightBlue, Colors.blueAccent]),
          boxShadow: [BoxShadow(color: Colors.lightBlue.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: _abrirCarritoBottomSheet,
          icon: const Icon(Icons.shopping_cart, color: Colors.white),
          label: Text('VER CARRITO (${_carrito.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
