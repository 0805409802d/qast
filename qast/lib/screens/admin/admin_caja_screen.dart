import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminCajaScreen extends StatefulWidget {
  const AdminCajaScreen({super.key});

  @override
  State<AdminCajaScreen> createState() => _AdminCajaScreenState();
}

class _AdminCajaScreenState extends State<AdminCajaScreen> {
  List<Map<String, String>> _pendientes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchPendientes();
  }

  Future<void> _fetchPendientes() async {
    setState(() => _isLoading = true);
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token') ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/admin/conductores'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _pendientes.clear();
          for (var item in data) {
            if (item["estado_aprobacion"] == "pendiente") {
              _pendientes.add({
                "id": item["id"]?.toString() ?? '',
                "nombre": item["nombre"]?.toString() ?? '',
                "apellidos": item["apellidos"]?.toString() ?? '',
                "cedula": item["cedula"]?.toString() ?? '',
              });
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cargando datos: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _activarChofer(String conductorId, String matricula, String licencia, XFile? imagen) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token') ?? '';

      // URL simulada ya que no hay upload en demo
      String imageUrl = "https://dummyimage.com/600x400/000/fff&text=Licencia+$conductorId";

      final response = await http.post(
        Uri.parse('$baseUrl/admin/conductores/$conductorId/paso2-activacion'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "matricula": matricula,
          "licencia_conducir": licencia,
          "documentos_url": imageUrl,
          "metodo_pago": "efectivo"
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _pendientes.removeWhere((c) => c["id"] == conductorId);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Chofer 100% aprobado y activo! (BD)'), backgroundColor: Colors.green),
        );
      } else {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${data['error']}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _abrirModalPaso2(Map<String, String> chofer) {
    final formKey = GlobalKey<FormState>();
    final matriculaCtrl = TextEditingController();
    final licenciaCtrl = TextEditingController();
    bool pagoRealizado = false;
    XFile? licenciaImagen;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Paso 2: Activar a ${chofer["nombre"]}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: matriculaCtrl,
                      decoration: const InputDecoration(labelText: 'Matrícula del Vehículo', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: licenciaCtrl,
                      decoration: const InputDecoration(labelText: 'Número de Licencia', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          setStateModal(() {
                            licenciaImagen = image;
                          });
                        }
                      },
                      icon: const Icon(Icons.upload_file),
                      label: Text(licenciaImagen == null ? 'Subir Foto de Licencia' : 'Foto subida: ${licenciaImagen!.name}'),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: CheckboxListTile(
                        title: const Text('Confirmo que el chofer ha pagado los \$20 anuales', style: TextStyle(fontWeight: FontWeight.bold)),
                        value: pagoRealizado,
                        onChanged: (val) {
                          setStateModal(() => pagoRealizado = val!);
                        },
                        activeColor: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          if (!pagoRealizado) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Debe confirmar el pago para activar al chofer'), backgroundColor: Colors.red),
                            );
                            return;
                          }
                          if (licenciaImagen == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Debe subir la foto de la licencia'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          _activarChofer(chofer["id"] ?? "", matriculaCtrl.text, licenciaCtrl.text, licenciaImagen);
                          Navigator.pop(context);
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text('ACEPTAR Y ACTIVAR', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendientes.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No hay trámites pendientes de pago en Caja.', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _pendientes.length,
      itemBuilder: (context, index) {
        final chofer = _pendientes[index];
        return Card(
          elevation: 2,
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.warning, color: Colors.white)),
            title: Text('${chofer["nombre"]} ${chofer["apellidos"]}'),
            subtitle: Text('Cédula: ${chofer["cedula"]}'),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _abrirModalPaso2(chofer),
              child: const Text('ACTIVAR'),
            ),
          ),
        );
      },
    );
  }
}
