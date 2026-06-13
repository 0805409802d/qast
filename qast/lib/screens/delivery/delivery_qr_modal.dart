import 'package:flutter/material.dart';

class DeliveryQrModal extends StatelessWidget {
  const DeliveryQrModal({super.key});

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
          const Text('Repartidor Autorizado por el Municipio', textAlign: TextAlign.center, style: TextStyle(color: Colors.deepOrange)),
          const SizedBox(height: 32),
          Container(
            width: 200,
            height: 200,
            color: Colors.grey[200],
            child: const Center(
              child: Icon(Icons.qr_code, size: 150, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Miguel Torres', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text('Moto: Honda XYZ-987', style: TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 16),
          const Text(
            'Muestra este código al Dueño del Local para retirar el pedido.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
