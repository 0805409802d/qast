import 'package:flutter/material.dart';

class DriverQrModal extends StatelessWidget {
  const DriverQrModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'GAFETE DIGITAL',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
          const SizedBox(height: 8),
          const Text('Chofer Autorizado por el Municipio de Quinindé', textAlign: TextAlign.center, style: TextStyle(color: Colors.green)),
          const SizedBox(height: 32),
          // Aquí iría el widget QrImageView de qr_flutter
          Container(
            width: 200,
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.qr_code, size: 150, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Juan Pérez', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Matrícula: ABC-123', style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              onPressed: () {
                // Lógica de descarga (requiere path_provider y gallery_saver o similar)
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Imagen guardada en la Galería'), backgroundColor: Colors.green),
                );
              },
              icon: const Icon(Icons.download, color: Colors.green),
              label: const Text('DESCARGAR PARA IMPRIMIR', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
