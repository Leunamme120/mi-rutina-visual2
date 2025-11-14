import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? _fotoUrl;

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Función para seleccionar y subir foto
  Future<void> _seleccionarFoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      File fotoFile = File(image.path);

      final ref = _storage.ref().child(
          'usuarios/${DateTime.now().millisecondsSinceEpoch}_${nombreController.text.isEmpty ? "usuario" : nombreController.text}.jpg');

      UploadTask uploadTask = ref.putFile(fotoFile);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await uploadTask;
        _fotoUrl = await ref.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al subir la foto')),
        );
      } finally {
        Navigator.pop(context); // Cierra loading
      }

      setState(() {
        _fotoUsuario = fotoFile;
      });
    }
  }

  // Función para guardar usuario en Firestore
  Future<void> _guardarUsuario() async {
    if (nombreController.text.isEmpty ||
        edadController.text.isEmpty ||
        necesidadSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor completa todos los campos.")),
      );
      return;
    }

    try {
      await _firestore.collection('usuarios').add({
        'nombre': nombreController.text,
        'edad': int.parse(edadController.text),
        'necesidad': necesidadSeleccionada,
        'foto': _fotoUrl ?? '',
        'fecha_creacion': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario creado exitosamente!")),
      );

      Navigator.pop(context, {
        'nombre': nombreController.text,
        'edad': edadController.text,
        'necesidad': necesidadSeleccionada,
        'foto': _fotoUrl ?? '',
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error al guardar el usuario")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dimensiones fijas similares a "Nueva Rutina"
    final double dialogWidth = MediaQuery.of(context).size.width * 0.85;
    final double dialogHeight = MediaQuery.of(context).size.height * 0.75;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Fondo atenuado
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black.withOpacity(0.5), // fondo semitransparente
            ),
          ),

          // Recuadro central
          Center(
            child: Container(
              width: dialogWidth,
              height: dialogHeight,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), // recuadro semi-transparente
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Nuevo Usuario",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    const Text("Nombre", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(
                        hintText: "Ingrese el nombre del usuario",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),

                    const Text("Edad", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: edadController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: "Ingrese la edad del usuario",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),

                    const Text("Selección de necesidad", style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: necesidadSeleccionada,
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
                    const SizedBox(height: 20),

                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundImage: _fotoUsuario != null
                                ? FileImage(_fotoUsuario!)
                                : const AssetImage('assets/images/usuario.png') as ImageProvider,
                            backgroundColor: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: _seleccionarFoto,
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Subir foto"),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancelar"),
                        ),
                        ElevatedButton(
                          onPressed: _guardarUsuario,
                          child: const Text("Guardar"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
