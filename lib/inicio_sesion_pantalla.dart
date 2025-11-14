import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'seleccion_usuario_pantalla.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InicioSesionPantalla extends StatefulWidget {
  const InicioSesionPantalla({super.key});

  @override
  _InicioSesionPantallaState createState() => _InicioSesionPantallaState();
}

class _InicioSesionPantallaState extends State<InicioSesionPantalla> {
  final AuthService _authService = AuthService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;

  // 🔹 Tutor con Google (requiere PIN)
  Future<void> _iniciarSesionTutor() async {
    String pin = '';
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('PIN Requerido'),
        content: TextField(
          controller: _pinController,
          decoration: const InputDecoration(hintText: 'Ingresa PIN'),
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
              pin = _pinController.text.trim();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );

    if (pin != '1234') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN incorrecto')),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Forzar que siempre aparezca la selección de cuenta
    await _authService.signOut();
    final user = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión cancelado o fallido')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bienvenido ${user.displayName ?? 'Tutor'}')),
    );

    // Navegar a pantalla de selección de usuario (Tutor ve todos)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionUsuarioPantalla(usuario: 'Juan'),
      ),
    );

    // Tip adicional comentado
    // final perfil = await _authService.obtenerPerfil(user.uid);
    // bool esTutor = perfil?['rol'] == 'tutor';
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => SeleccionUsuarioPantalla(usuario: user.displayName ?? 'Usuario', esTutor: esTutor),
    //   ),
    // );
  }

  // 🔹 Usuario normal por nombre
  Future<void> _iniciarSesionUsuario() async {
    String nombre = _nombreController.text.trim();
    if (nombre.isEmpty) return;

    // 🔹 Buscar en Firestore por campo 'nombre'
    final query = await FirebaseFirestore.instance
        .collection('usuarios')
        .where('nombre', isEqualTo: nombre)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuario no existe')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bienvenido $nombre')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SeleccionUsuarioPantalla(usuario: nombre),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade200,
              Colors.lightBlue.shade300,
              Colors.yellow.shade200,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Mi Rutina Visual',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),

                    // 🔤 Campo de texto para ingresar nombre
                    TextField(
                      controller: _nombreController,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Escribe tu nombre',
                        filled: true,
                        fillColor: Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 🚀 Botón Ingresar (usuario normal)
                    ElevatedButton(
                      onPressed: _iniciarSesionUsuario,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'Ingresar',
                        style: TextStyle(fontSize: 20, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 50),

                    // 🚀 Botón Tutor (Google Sign-In)
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.teal)
                        : ElevatedButton.icon(
                            onPressed: _iniciarSesionTutor,
                            icon: Image.asset(
                              'assets/google_logo.png',
                              height: 24,
                              width: 24,
                            ),
                            label: const Text(
                              'Tutor',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 15,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
