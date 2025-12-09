import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;             // viene del document.id
  final String nombre;
  final String email;
  final String telefono;
  final String telefono2;
  final String tieneAlergia;
  final String tieneDiabetes;
  final bool isAdmin;
  final DateTime? createdAt;
  final String? fcmToken; // Para notificaciones push

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.telefono2,
    required this.tieneAlergia,
    required this.tieneDiabetes,
    required this.isAdmin,
    required this.createdAt,
    this.fcmToken,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      telefono: data['telefono'] ?? '',
      telefono2: data['telefono2'] ?? '',
      tieneAlergia: data['tieneAlergia'] ?? '',
      tieneDiabetes: data['tieneDiabetes'] ?? '',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      fcmToken: data["fcmToken"]
    );
  }
}