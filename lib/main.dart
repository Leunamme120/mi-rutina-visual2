import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io'; // Para File
import 'package:image_picker/image_picker.dart'; // Para ImagePicker
// 👇 Importaciones para Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_service.dart';
import 'editar_perfil_pantalla.dart';
import 'rutinas_pantalla.dart';
import 'seleccion_usuario_pantalla.dart'; // pantalla nueva
import 'inicio_sesion_pantalla.dart'; // 👈 Asegúrate de que este archivo exista en lib/

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options:
        DefaultFirebaseOptions.currentPlatform, // 👈 usa firebase_options.dart
  );
  runApp(const MiRutinaVisualApp());
}

// ------------------- App -------------------
class MiRutinaVisualApp extends StatelessWidget {
  const MiRutinaVisualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mi Rutina Visual',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: InicioSesionPantalla(), // 👈 Pantalla inicial de login
    );
  }
}

// ------------------- Pantalla de Inicio / Login -------------------
class InicioPantalla extends StatelessWidget {
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final AuthService _authService = AuthService();

  InicioPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.lightBlue[100],
        padding: const EdgeInsets.all(30),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Mi Rutina Visual',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: usuarioController,
                decoration: const InputDecoration(
                  labelText: 'Usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                child: const Text('Ingresar', style: TextStyle(fontSize: 20)),
                onPressed: () async {
                  String usuario = usuarioController.text.trim();

                  // ✅ Validar si el usuario existe
                  bool existe = await _authService.signIn(usuario);

                  if (!existe) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No existe usuario')),
                    );
                    return; // No deja avanzar
                  }

                  // Si es Juan, pedir PIN
                  if (usuario.toLowerCase() == 'juan') {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('PIN Requerido'),
                        content: TextField(
                          controller: pinController,
                          decoration:
                              const InputDecoration(hintText: 'Ingresa PIN'),
                          obscureText: true,
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancelar'),
                            onPressed: () => Navigator.pop(context),
                          ),
                          ElevatedButton(
                            child: const Text('Ingresar'),
                            onPressed: () {
                              if (pinController.text == '1234') {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => SeleccionUsuarioPantalla(
                                          usuario: usuario)),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('PIN incorrecto')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              SeleccionUsuarioPantalla(usuario: usuario)),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------- Selección de Usuario -------------------
class SeleccionUsuarioPantalla extends StatefulWidget {
  final String usuario;
  const SeleccionUsuarioPantalla({super.key, required this.usuario});

  @override
  _SeleccionUsuarioPantallaState createState() =>
      _SeleccionUsuarioPantallaState();
}

class _SeleccionUsuarioPantallaState extends State<SeleccionUsuarioPantalla> {
  final List<Map<String, dynamic>> usuarios = [
    {
      'nombre': 'Juan',
      'edad': '35',
      'foto': 'assets/images/usuario.png',
      'tipo': 'Tutor',
      'color': Colors.blue,
      'recordatorio': false,
    },
    {
      'nombre': 'María',
      'edad': '7',
      'foto': 'assets/images/usuario2.png',
      'tipo': 'Más auditiva',
      'color': Colors.pink,
      'recordatorio': true,
    },
    {
      'nombre': 'Carlos',
      'edad': '9',
      'foto': 'assets/images/usuario.png',
      'tipo': 'Más visual',
      'color': Colors.red,
      'recordatorio': true,
    },
  ];

  bool get esTutor => widget.usuario.toLowerCase() == 'juan';

  void _crearUsuario() {
    TextEditingController nombreCtrl = TextEditingController();
    TextEditingController edadCtrl = TextEditingController();
    String tipoSeleccionado = 'Más visual';
    String? fotoSeleccionada;
    final ImagePicker picker = ImagePicker();

    Future<void> seleccionarFoto() async {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          fotoSeleccionada = image.path;
        });
      }
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text(
            'Crear Nuevo Usuario',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nombre
                TextField(
                  controller: nombreCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Edad
                TextField(
                  controller: edadCtrl,
                  decoration: InputDecoration(
                    labelText: 'Edad',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),

                // Tipo de necesidad
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<String>(
                    value: tipoSeleccionado,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items:
                        ['Más visual', 'Más auditiva', 'Más sensorial', 'Mixta']
                            .map((tipo) => DropdownMenuItem(
                                  value: tipo,
                                  child: Text(tipo),
                                ))
                            .toList(),
                    onChanged: (value) {
                      if (value != null)
                        setDialogState(() => tipoSeleccionado = value);
                    },
                  ),
                ),
                const SizedBox(height: 15),

                // Foto del usuario
                GestureDetector(
                  onTap: seleccionarFoto,
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.deepPurple.withOpacity(0.1),
                    backgroundImage: fotoSeleccionada != null
                        ? FileImage(File(fotoSeleccionada!))
                        : null,
                    child: fotoSeleccionada == null
                        ? const Icon(Icons.person,
                            size: 50, color: Colors.deepPurple)
                        : null,
                  ),
                ),
                const SizedBox(height: 5),
                TextButton.icon(
                  onPressed: seleccionarFoto,
                  icon:
                      const Icon(Icons.photo_library, color: Colors.deepPurple),
                  label: const Text("Seleccionar foto",
                      style: TextStyle(color: Colors.deepPurple)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                if (nombreCtrl.text.isNotEmpty && edadCtrl.text.isNotEmpty) {
                  setState(() {
                    usuarios.add({
                      'nombre': nombreCtrl.text,
                      'edad': edadCtrl.text,
                      'tipo': tipoSeleccionado,
                      'foto': fotoSeleccionada ?? 'assets/images/usuario.png',
                      // 👇 Color fijo para evitar null.withOpacity()
                      'color': Colors.deepPurple,
                      'recordatorio': true,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child:
                  const Text('Guardar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _editarUsuario(int index) {
    final usuario = usuarios[index];
    TextEditingController nombreCtrl =
        TextEditingController(text: usuario['nombre']);
    TextEditingController edadCtrl =
        TextEditingController(text: usuario['edad']);
    String tipoSeleccionado = usuario['tipo'];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar Usuario'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(hintText: 'Nombre')),
              const SizedBox(height: 10),
              TextField(
                  controller: edadCtrl,
                  decoration: const InputDecoration(hintText: 'Edad'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              DropdownButton<String>(
                value: tipoSeleccionado,
                items: ['Más visual', 'Más auditiva', 'Mixta']
                    .map((tipo) =>
                        DropdownMenuItem(value: tipo, child: Text(tipo)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => tipoSeleccionado = value);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                usuario['nombre'] = nombreCtrl.text;
                usuario['edad'] = edadCtrl.text;
                usuario['tipo'] = tipoSeleccionado;
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _eliminarUsuario(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Usuario'),
        content:
            Text('¿Seguro que deseas eliminar a ${usuarios[index]['nombre']}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                usuarios.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> listaMostrar = esTutor
        ? usuarios
        : usuarios
            .where((u) =>
                u['nombre'].toString().toLowerCase() ==
                widget.usuario.toLowerCase())
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Seleccionar Usuario')),
      body: ListView.builder(
        itemCount: listaMostrar.length,
        itemBuilder: (context, index) {
          final u = listaMostrar[index];

          // Determinar la imagen del usuario
          ImageProvider? imageProvider;
          if (u['foto'] != null) {
            if (u['foto'] is String && u['foto'].startsWith('assets/')) {
              imageProvider = AssetImage(u['foto']);
            } else if (u['foto'] is String) {
              imageProvider = FileImage(File(u['foto']));
            }
          }

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, size: 30, color: Colors.black54)
                    : null,
              ),
              title: Text(u['nombre'], style: const TextStyle(fontSize: 20)),
              subtitle: Text('Edad: ${u['edad']} - Tipo: ${u['tipo']}'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        RutinasPantalla(usuario: u, esTutor: esTutor),
                  ),
                );
              },
              trailing: esTutor && u['nombre'].toLowerCase() != 'juan'
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editarUsuario(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _eliminarUsuario(index),
                        ),
                      ],
                    )
                  : null,
            ),
          );
        },
      ),
      floatingActionButton: esTutor
          ? FloatingActionButton(
              onPressed: _crearUsuario,
              tooltip: 'Crear Usuario',
              child: Icon(Icons.person_add),
            )
          : null,
    );
  }
}
