import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Lista de correos de administradores
  final List<String> adminEmails = [
    'admin1@ejemplo.com',
    'admin2@ejemplo.com',
    'super_admi@hotmail.com',
  ];

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream del estado de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verificar si el usuario es administrador
  bool isAdmin(String email) {
    return adminEmails.contains(email.toLowerCase());
  }

  // Iniciar sesión
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = result.user;
      
      if (user != null) {
        // Verificar si es admin
        bool isUserAdmin = isAdmin(user.email!);
        
        Map<String, dynamic>? userData;
        
        // Solo intentar obtener datos de Firestore si no es admin
        // o si queremos crear el documento de admin
        try {
          DocumentSnapshot userDoc = await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

          if (userDoc.exists) {
            userData = userDoc.data() as Map<String, dynamic>?;
          } else if (isUserAdmin) {
            // Si es admin y no tiene documento, crearlo
            await _firestore.collection('users').doc(user.uid).set({
              'email': user.email,
              'nombre': 'Administrador',
              'isAdmin': true,
              'createdAt': FieldValue.serverTimestamp(),
            });
          }
        } catch (firestoreError) {
          // Si falla Firestore pero el login fue exitoso, continuar
          print('Error de Firestore: $firestoreError');
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
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe una cuenta con este correo';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
        case 'user-disabled':
          message = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'invalid-credential':
          message = 'Credenciales inválidas';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // Registrar nuevo usuario con información completa
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
        await _firestore.collection('users').doc(user.uid).set({
          'email': email.trim(),
          'nombre': nombre,
          'telefono': telefono,
          'telefono2': telefono2 ?? '',
          'tieneDiabetes': tieneDiabetes,
          'tieneAlergia': tieneAlergia,
          'isAdmin': isAdmin(email),
          'createdAt': FieldValue.serverTimestamp(),
        });

        return {
          'success': true,
          'user': user,
          'message': 'Cuenta creada exitosamente',
        };
      }

      return {'success': false, 'message': 'Error al crear usuario'};
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Este correo ya está registrado';
          break;
        case 'weak-password':
          message = 'La contraseña es muy débil (mínimo 6 caracteres)';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Recuperar contraseña
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {
        'success': true,
        'message': 'Se ha enviado un correo para restablecer tu contraseña',
      };
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe una cuenta con este correo';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
        default:
          message = 'Error: ${e.message}';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Error inesperado: $e'};
    }
  }

  // Obtener datos del usuario actual
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
  /// Registra un nuevo administrador sin cerrar la sesión actual
  Future<String?> registerAdmin({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // 1. Inicializamos una app secundaria temporal
      secondaryApp = await Firebase.initializeApp(
        name: 'AdminRegistration',
        options: Firebase.app().options,
      );

      // 2. Usamos la auth de esa app secundaria
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      // 3. Creamos el usuario (esto no afecta tu sesión actual)
      final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4. Guardamos los datos en Firestore con el rol de admin
      // Usamos la instancia principal de Firestore, ya que el admin actual tiene permisos
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'phoneNumber': phone,
        'role': 'admin',      // Rol clave
        'isAdmin': true,      // Bandera explícita
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': '',       // Foto vacía por defecto
        'tieneDiabetes': 'No',
        'tieneAlergia': 'No',
      });

      return null; // Null significa éxito
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error desconocido: $e";
    } finally {
      // 5. Borramos la app secundaria para liberar memoria
      await secondaryApp?.delete();
    }
  }
}