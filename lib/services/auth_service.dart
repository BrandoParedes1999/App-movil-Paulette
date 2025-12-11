import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter para obtener el usuario actual (Necesario para getUserData)
  User? get currentUser => _auth.currentUser;

  // Stream para escuchar cambios en la autenticación (Login/Logout)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // -----------------------------------------------------------------------------
  // INICIAR SESIÓN
  // -----------------------------------------------------------------------------
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      // 1. Autenticar con Firebase Auth
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = result.user;
      
      if (user != null) {
        // 2. Obtener datos extras de Firestore (Rol, nombre, etc.)
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        bool isUserAdmin = false;
        Map<String, dynamic>? userData;

        if (userDoc.exists) {
          userData = userDoc.data() as Map<String, dynamic>?;
          // Verificamos si tiene la bandera de admin
          isUserAdmin = userData?['isAdmin'] == true;
        } 

        return {
          'success': true,
          'user': user,
          'isAdmin': isUserAdmin,
          'userData': userData,
        };
      }
      return {'success': false, 'message': 'Error desconocido'};
      
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _handleAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // -----------------------------------------------------------------------------
  // REGISTRO DE USUARIO (CLIENTE)
  // -----------------------------------------------------------------------------
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
    String? telefono2,
    required String tieneDiabetes,
    required String tieneAlergia,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // Guardar información completa en Firestore
        // NOTA: 'isAdmin' es false porque es un registro público
        await _firestore.collection('users').doc(user.uid).set({
          'email': email.trim(),
          'nombre': nombre,
          'telefono': telefono,
          'telefono2': telefono2 ?? '',
          'tieneDiabetes': tieneDiabetes,
          'tieneAlergia': tieneAlergia,
          'isAdmin': false, 
          'createdAt': FieldValue.serverTimestamp(),
          'role': 'client', // Definimos rol explícito
        });

        return {
          'success': true,
          'user': user,
          'message': 'Cuenta creada exitosamente',
        };
      }

      return {'success': false, 'message': 'Error al crear usuario'};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _handleAuthError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // -----------------------------------------------------------------------------
  // REGISTRAR ADMINISTRADOR (Función Avanzada)
  // -----------------------------------------------------------------------------
  /// Registra un nuevo administrador sin cerrar la sesión actual
  Future<String?> registerAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Inicializamos una app secundaria temporal para no cerrar sesión al actual
      secondaryApp = await Firebase.initializeApp(
        name: 'AdminRegistration',
        options: Firebase.app().options,
      );

      // 2. Usamos la auth de esa app secundaria
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 3. Creamos el usuario
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4. Guardamos los datos en Firestore (usando la instancia principal)
      // CORRECCIÓN: Usamos las mismas claves ('nombre', 'telefono') que en el modelo de usuario
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'nombre': name,        // Antes decia 'name', corregido a 'nombre'
        'telefono': phone,     // Antes decia 'phoneNumber', corregido a 'telefono'
        'telefono2': '',
        'role': 'admin',
        'isAdmin': true,       // Bandera admin activada
        'createdAt': FieldValue.serverTimestamp(),
        'tieneDiabetes': 'No',
        'tieneAlergia': 'No',
      });

      return null; // Null significa éxito
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e.code);
    } catch (e) {
      return "Error desconocido: $e";
    } finally {
      // 5. Limpiamos la app secundaria
      await secondaryApp?.delete();
    }
  }

  // -----------------------------------------------------------------------------
  // OTROS MÉTODOS
  // -----------------------------------------------------------------------------
  
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Se ha enviado un correo para restablecer tu contraseña',
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _handleAuthError(e.code)};
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      User? user = currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          return doc.data() as Map<String, dynamic>?;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Helper para mensajes de error limpios
  String _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      case 'invalid-email':
        return 'Correo electrónico inválido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres)';
      case 'invalid-credential':
        return 'Credenciales inválidas';
      default:
        return 'Error de autenticación: $code';
    }
  }
}