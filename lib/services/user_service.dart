import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtener usuario por ID
  Future<UserModel?> getUserById(String id) async {
    final doc = await _db.collection("users").doc(id).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Obtener datos del usuario actual
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _db.collection("users").doc(user.uid).get();
      
      if (!doc.exists) return null;
      
      return UserModel.fromFirestore(doc);
    } catch (e) {
      print("🔥 Error al obtener usuario: $e");
      return null;
    }
  }

  /// Stream del usuario actual
  Stream<UserModel?> getCurrentUserStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _db
        .collection("users")
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Verificar si el usuario actual es admin
  Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.isAdmin ?? false;
  }

  /// Actualizar FCM Token para notificaciones
  Future<bool> updateFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _db.collection("users").doc(user.uid).update({
        "fcmToken": token,
      });
      return true;
    } catch (e) {
      print("🔥 Error al actualizar FCM token: $e");
      return false;
    }
  }
  /// 🔹 Obtener TODOS los clientes (para el Admin)
  Stream<List<UserModel>> getAllClients() {
    return _db
        .collection("users")
        .where("isAdmin", isEqualTo: false) // Solo clientes
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    });
  }
}