import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CrearUsuarioPantalla extends StatefulWidget {
  const CrearUsuarioPantalla({super.key});

  @override
  _CrearUsuarioPantallaState createState() => _CrearUsuarioPantallaState();
}

class _CrearUsuarioPantallaState extends State<CrearUsuarioPantalla> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  String? necesidadSeleccionada;
  File? _fotoUsuario;

  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarFoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _fotoUsuario = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear Nuevo Usuario"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nombre
            const Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                hintText: "Ingrese el nombre del usuario",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Edad
            const Text("Edad", style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: edadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Ingrese la edad del usuario",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Tipo de necesidad
            const Text("Selección de necesidad",
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              initialValue: necesidadSeleccionada,
              items: ['Visual', 'Auditiva', 'Sensorial', 'Mixta']
                  .map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo),
                      ))
                  .toList(),
              onChanged: (valor) {
                setState(() {
                  necesidadSeleccionada = valor;
                });
              },
              decoration: const InputDecoration(
                hintText: "Seleccione una necesidad",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // 📸 Subir foto
            Center(
              child: Column(
                children: [
                  // Foto circular (previsualización)
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _fotoUsuario != null
                        ? FileImage(_fotoUsuario!)
                        : const AssetImage('assets/images/usuario.png')
                            as ImageProvider,
                    backgroundColor: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 10),

                  // Botón subir foto
                  TextButton.icon(
                    onPressed: _seleccionarFoto,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Subir foto"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nombreController.text.isEmpty ||
                        edadController.text.isEmpty ||
                        necesidadSeleccionada == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Por favor completa todos los campos.")),
                      );
                      return;
                    }

                    Navigator.pop(context, {
                      'nombre': nombreController.text,
                      'edad': edadController.text,
                      'necesidad': necesidadSeleccionada,
                      'foto': _fotoUsuario?.path,
                    });
                  },
                  child: const Text("Guardar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
