import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'crear_usuario_pantalla.dart';
import 'rutinas_pantalla.dart';
import 'inicio_sesion_pantalla.dart';

class SeleccionUsuarioPantalla extends StatefulWidget {
  final String usuario; // nombre del usuario que inició sesión

  const SeleccionUsuarioPantalla({super.key, required this.usuario});

  @override
  _SeleccionUsuarioPantallaState createState() => _SeleccionUsuarioPantallaState();
}

class _SeleccionUsuarioPantallaState extends State<SeleccionUsuarioPantalla> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final bool esTutor = widget.usuario.toLowerCase() == 'juan';

    return Scaffold(
      appBar: AppBar(
        title: Text("Bienvenido ${widget.usuario}"),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const InicioSesionPantalla()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('usuarios')
                  .orderBy('fecha_creacion', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No hay usuarios registrados."));
                }

                final usuarios = snapshot.data!.docs;
                final usuariosVisibles = esTutor
                    ? usuarios
                    : usuarios.where((u) =>
                        u['nombre'].toString().toLowerCase() ==
                        widget.usuario.toLowerCase()).toList();

                return ListView.builder(
                  itemCount: usuariosVisibles.length,
                  itemBuilder: (context, index) {
                    final usuario = usuariosVisibles[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: usuario['foto'] != ''
                              ? NetworkImage(usuario['foto'])
                              : const AssetImage('assets/images/usuario.png') as ImageProvider,
                        ),
                        title: Text(usuario['nombre']),
                        subtitle: Text("Edad: ${usuario['edad']} - necesidad: ${usuario['necesidad']}"),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RutinasPantalla(
                                usuario: usuario.data() as Map<String, dynamic>,
                                esTutor: esTutor,
                              ),
                            ),
                          );
                        },
                        trailing: esTutor
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await _firestore.collection('usuarios').doc(usuario.id).delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Usuario eliminado")),
                                  );
                                },
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: esTutor
    ? Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FloatingActionButton(
            backgroundColor: Colors.grey.shade800,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
            onPressed: () async {
              final nuevoUsuario = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrearUsuarioPantalla()),
              );
              if (nuevoUsuario != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Usuario creado exitosamente!")),
                );
              }
            },
          ),
        ),
      )
    : null,

    );
  }
}
