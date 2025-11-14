import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔹 Usuarios locales fijos
  final List<String> _usuariosPermitidos = ['Juan', 'María', 'Pedro', 'Ana'];

  /// Método para validar usuarios locales fijos
  Future<bool> signIn(String usuario) async {
    await Future.delayed(const Duration(seconds: 1));
    return _usuariosPermitidos.contains(usuario);
  }

  // 🔹 Login con Google (Android/iOS)
  Future<User?> signInWithGoogle() async {
    try {
      // Inicia el flujo de Google Sign-In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // usuario canceló login

      // Obtiene credenciales de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Inicia sesión en Firebase con credenciales de Google
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Guardar perfil en Firestore si es nuevo usuario
      await guardarPerfil(userCredential.user!.displayName ?? 'Sin Nombre', {
        'email': userCredential.user!.email,
        'uid': userCredential.user!.uid,
        'lastLogin': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } catch (e) {
      print('Error en signInWithGoogle: $e');
      return null;
    }
  }

  // 🔹 Logout
  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _auth.signOut();
  }

  // 🔹 Guardar o actualizar perfil en Firestore
  Future<void> guardarPerfil(String nombreUsuario, Map<String, dynamic> datos) async {
    await _db.collection('usuarios').doc(nombreUsuario).set(datos, SetOptions(merge: true));
  }

  // 🔹 Obtener datos del perfil por ID de documento
  Future<Map<String, dynamic>?> obtenerPerfil(String nombreUsuario) async {
    final doc = await _db.collection('usuarios').doc(nombreUsuario).get();
    return doc.exists ? doc.data() : null;
  }

  // 🔹 Nuevo: Obtener datos del perfil por campo 'nombre' (para login de usuarios normales)
  Future<Map<String, dynamic>?> obtenerPerfilPorNombre(String nombre) async {
    final query = await _db
        .collection('usuarios')
        .where('nombre', isEqualTo: nombre)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first.data();
  }
}
