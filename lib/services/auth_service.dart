import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final String _collectionName = 'usuarios';

  // Usuario actual en sesión
  static Usuario? _usuarioActual;

  // Obtener usuario actual
  static Usuario? get usuarioActual => _usuarioActual;

  // Inicializar usuarios de ejemplo si no existen
  static Future<void> initializeDefaultUsers() async {
    try {
      print('🔐 Verificando usuarios predeterminados...');

      // Verificar si ya existen usuarios
      final querySnapshot = await _firestore.collection(_collectionName).get();

      if (querySnapshot.docs.isEmpty) {
        print('📝 Creando usuarios predeterminados...');

        // Crear usuario genérico
        await _firestore.collection(_collectionName).add({
          'nombreUsuario': 'Usuario',
          'contrasena': '12345678',
          'fechaCreacion': Timestamp.now(),
          'ultimaActualizacion': null,
        });

        // Crear usuario Dante
        await _firestore.collection(_collectionName).add({
          'nombreUsuario': 'Dante',
          'contrasena': '12345678',
          'fechaCreacion': Timestamp.now(),
          'ultimaActualizacion': null,
        });

        print('✅ Usuarios predeterminados creados exitosamente');
      } else {
        print('✅ Usuarios ya existen en la base de datos');
      }
    } catch (e) {
      print('❌ Error al inicializar usuarios: $e');
    }
  }

  // Iniciar sesión
  static Future<Usuario?> login(String nombreUsuario, String contrasena) async {
    try {
      print('🔐 Intentando login para: $nombreUsuario');

      // Buscar usuario por nombre
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('nombreUsuario', isEqualTo: nombreUsuario)
          .where('contrasena', isEqualTo: contrasena)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ Usuario o contraseña incorrectos');
        return null;
      }

      // Convertir documento a Usuario
      final usuario = Usuario.fromFirestore(querySnapshot.docs.first);
      _usuarioActual = usuario;

      print('✅ Login exitoso para: ${usuario.nombreUsuario}');
      return usuario;
    } catch (e) {
      print('❌ Error en login: $e');
      return null;
    }
  }

  // Cerrar sesión
  static void logout() {
    _usuarioActual = null;
    print('👋 Sesión cerrada');
  }

  // Cambiar nombre de usuario
  static Future<bool> cambiarNombreUsuario(String nuevoNombre) async {
    if (_usuarioActual == null) return false;

    try {
      print('📝 Cambiando nombre de usuario...');

      await _firestore.collection(_collectionName).doc(_usuarioActual!.id).update({
        'nombreUsuario': nuevoNombre,
        'ultimaActualizacion': Timestamp.now(),
      });

      _usuarioActual = _usuarioActual!.copyWith(
        nombreUsuario: nuevoNombre,
        ultimaActualizacion: DateTime.now(),
      );

      print('✅ Nombre de usuario actualizado exitosamente');
      return true;
    } catch (e) {
      print('❌ Error al cambiar nombre de usuario: $e');
      return false;
    }
  }

  // Cambiar contraseña
  static Future<bool> cambiarContrasena(String contrasenaActual, String nuevaContrasena) async {
    if (_usuarioActual == null) return false;

    try {
      print('🔐 Cambiando contraseña...');

      // Verificar contraseña actual
      if (_usuarioActual!.contrasena != contrasenaActual) {
        print('❌ Contraseña actual incorrecta');
        return false;
      }

      // Actualizar contraseña
      await _firestore.collection(_collectionName).doc(_usuarioActual!.id).update({
        'contrasena': nuevaContrasena,
        'ultimaActualizacion': Timestamp.now(),
      });

      _usuarioActual = _usuarioActual!.copyWith(
        contrasena: nuevaContrasena,
        ultimaActualizacion: DateTime.now(),
      );

      print('✅ Contraseña actualizada exitosamente');
      return true;
    } catch (e) {
      print('❌ Error al cambiar contraseña: $e');
      return false;
    }
  }

  // Obtener todos los usuarios (para admin)
  static Future<List<Usuario>> obtenerUsuarios() async {
    try {
      final querySnapshot = await _firestore.collection(_collectionName).get();
      return querySnapshot.docs.map((doc) => Usuario.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error al obtener usuarios: $e');
      return [];
    }
  }

  // Verificar si hay sesión activa
  static bool haySesionActiva() {
    return _usuarioActual != null;
  }

  // Crear un nuevo usuario
  static Future<Map<String, dynamic>> crearUsuario({
    required String nombreUsuario,
    required String contrasena,
  }) async {
    try {
      print('📝 Creando nuevo usuario: $nombreUsuario');

      // Validar que el nombre de usuario no esté vacío
      if (nombreUsuario.trim().isEmpty) {
        return {
          'success': false,
          'message': 'El nombre de usuario no puede estar vacío',
        };
      }

      // Validar que la contraseña tenga 8 dígitos
      if (contrasena.length != 8 || !RegExp(r'^\d{8}$').hasMatch(contrasena)) {
        return {
          'success': false,
          'message': 'La contraseña debe tener exactamente 8 dígitos',
        };
      }

      // Verificar que no exista un usuario con el mismo nombre
      final existingUser = await _firestore
          .collection(_collectionName)
          .where('nombreUsuario', isEqualTo: nombreUsuario.trim())
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        return {
          'success': false,
          'message': 'Ya existe un usuario con ese nombre',
        };
      }

      // Crear el nuevo usuario
      final docRef = await _firestore.collection(_collectionName).add({
        'nombreUsuario': nombreUsuario.trim(),
        'contrasena': contrasena,
        'fechaCreacion': Timestamp.now(),
        'ultimaActualizacion': null,
      });

      print('✅ Usuario creado exitosamente con ID: ${docRef.id}');
      return {
        'success': true,
        'message': 'Usuario creado exitosamente',
        'userId': docRef.id,
      };
    } catch (e) {
      print('❌ Error al crear usuario: $e');
      return {
        'success': false,
        'message': 'Error al crear usuario: $e',
      };
    }
  }

  // Eliminar un usuario
  static Future<Map<String, dynamic>> eliminarUsuario(String userId) async {
    try {
      print('🗑️ Eliminando usuario con ID: $userId');

      // Evitar que el usuario actual se elimine a sí mismo
      if (_usuarioActual?.id == userId) {
        return {
          'success': false,
          'message': 'No puedes eliminar tu propia cuenta mientras estás conectado',
        };
      }

      // Verificar que el usuario existe
      final doc = await _firestore.collection(_collectionName).doc(userId).get();
      if (!doc.exists) {
        return {
          'success': false,
          'message': 'El usuario no existe',
        };
      }

      // Eliminar el usuario
      await _firestore.collection(_collectionName).doc(userId).delete();

      print('✅ Usuario eliminado exitosamente');
      return {
        'success': true,
        'message': 'Usuario eliminado exitosamente',
      };
    } catch (e) {
      print('❌ Error al eliminar usuario: $e');
      return {
        'success': false,
        'message': 'Error al eliminar usuario: $e',
      };
    }
  }

  // Verificar si un nombre de usuario está disponible
  static Future<bool> esNombreUsuarioDisponible(String nombreUsuario) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('nombreUsuario', isEqualTo: nombreUsuario.trim())
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('❌ Error al verificar disponibilidad: $e');
      return false;
    }
  }
}
