import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  List<Map<String, String>> _choferes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchConductores();
  }

  Future<void> _fetchConductores() async {
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
          _choferes.clear(); // Limpiar lista
          for (var item in data) {
            _choferes.add({
              "id": item["id"]?.toString() ?? '',
              "nombre": item["nombre"]?.toString() ?? '',
              "apellidos": item["apellidos"]?.toString() ?? '',
              "cedula": item["cedula"]?.toString() ?? '',
              "telefono": item["telefono"]?.toString() ?? '',
              "estado": item["estado_aprobacion"]?.toString() ?? 'pendiente',
            });
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

  Future<void> _crearUsuario(String nombre, String apellidos, String cedula, String telefono, String tipoSangre) async {
    try {
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8080/api';
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('admin_token') ?? '';

      final response = await http.post(
        Uri.parse('$baseUrl/admin/conductores/paso1-basico'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "nombre": nombre,
          "apellidos": apellidos,
          "cedula": cedula,
          "telefono": telefono,
          "tipo_sangre": tipoSangre,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final conductorId = data['conductor']?['ID']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();

        setState(() {
          _choferes.add({
            "id": conductorId,
            "nombre": nombre,
            "apellidos": apellidos,
            "cedula": cedula,
            "telefono": telefono,
            "estado": "pendiente",
          });
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario Creado en BD. Pendiente de Pago/Vehículo.'), backgroundColor: Colors.green),
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

  void _mostrarFormularioPaso1() {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final apellidosCtrl = TextEditingController();
    final cedulaCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final tipoSangreCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
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
                const Text(
                  'Registrar Nuevo Chofer (Paso 1)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: apellidosCtrl,
                  decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: cedulaCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Cédula de Identidad', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: telefonoCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Número de Teléfono', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: tipoSangreCtrl,
                  decoration: const InputDecoration(labelText: 'Tipo de Sangre (Opcional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      // Usar la función real en lugar del setState directo
                      _crearUsuario(
                        nombreCtrl.text,
                        apellidosCtrl.text,
                        cedulaCtrl.text,
                        telefonoCtrl.text,
                        tipoSangreCtrl.text,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('CREAR USUARIO', style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _choferes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No hay conductores registrados.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _choferes.length,
              itemBuilder: (context, index) {
                final chofer = _choferes[index];
                final isAprobado = chofer["estado"] == "aprobado";

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isAprobado ? Colors.green : Colors.orange,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text('${chofer["nombre"]} ${chofer["apellidos"]}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Cédula: ${chofer["cedula"]} • Tel: ${chofer["telefono"]}'),
                    trailing: Chip(
                      label: Text(isAprobado ? 'Activo' : 'Pendiente', style: const TextStyle(color: Colors.white)),
                      backgroundColor: isAprobado ? Colors.green : Colors.orange,
                    ),
                    onTap: () {
                      // Aquí se podría abrir un modal para "Editar" el teléfono si se pierde
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Para activar o completar pago, vaya a la pestaña CAJA')));
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarFormularioPaso1,
        backgroundColor: Colors.green[700],
        icon: const Icon(Icons.add),
        label: const Text('Crear Usuario'),
      ),
    );
  }
}
