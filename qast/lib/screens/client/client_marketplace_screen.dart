import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qast/screens/client/client_business_detail_screen.dart';

class ClientMarketplaceScreen extends StatelessWidget {
  const ClientMarketplaceScreen({super.key});

  final List<Map<String, dynamic>> _negociosMock = const [
    {
      'id': '1',
      'nombre': 'Burger King Quinindé',
      'categoria': 'Comida Rápida',
      'rating': '4.8',
      'tiempo': '15-25 min',
      'imagen': Icons.fastfood
    },
    {
      'id': '2',
      'nombre': 'Farmacia Cruz Azul',
      'categoria': 'Salud y Farmacia',
      'rating': '4.9',
      'tiempo': '10-20 min',
      'imagen': Icons.local_pharmacy
    },
    {
      'id': '3',
      'nombre': 'Asadero El Buen Pollo',
      'categoria': 'Almuerzos y Cenas',
      'rating': '4.5',
      'tiempo': '20-30 min',
      'imagen': Icons.restaurant
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Quinindé Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
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
            child: Column(
              children: [
                // Barra de Búsqueda
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: '¿Qué se te antoja hoy?',
                            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                            prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Categorías rápidas
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoria(Icons.restaurant, 'Comida'),
                      _buildCategoria(Icons.local_pharmacy, 'Farmacia'),
                      _buildCategoria(Icons.shopping_basket, 'Víveres'),
                      _buildCategoria(Icons.local_shipping, 'Paquetes'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Lista de Negocios
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: _negociosMock.length,
                    itemBuilder: (context, index) {
                      final n = _negociosMock[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => ClientBusinessDetailScreen(negocio: n)));
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Column(
                                  children: [
                                    // Portada simulada
                                    Container(
                                      height: 140,
                                      decoration: BoxDecoration(
                                        color: Colors.lightBlueAccent.withOpacity(0.2),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                      ),
                                      child: Center(
                                        child: Icon(n['imagen'], size: 70, color: Colors.white.withOpacity(0.8)),
                                      ),
                                    ),
                                    // Detalles
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(n['nombre'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                                              const SizedBox(height: 6),
                                              Text(n['categoria'], style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.amber.withOpacity(0.5))
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                                    const SizedBox(width: 4),
                                                    Text(n['rating'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(n['tiempo'], style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                            ],
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoria(IconData icon, String titulo) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 65,
                width: 65,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(titulo, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
