import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String telefono2;
  final String tieneAlergia;
  final String tieneDiabetes;
  final String role; // Nuevo campo importante
  final bool isAdmin;
  final DateTime? createdAt;
  final String? fcmToken;
  final String? photoUrl;

  UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    this.telefono2 = '',
    this.tieneAlergia = 'No',
    this.tieneDiabetes = 'No',
    this.role = 'client',
    this.isAdmin = false,
    this.createdAt,
    this.fcmToken,
    this.photoUrl,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Seguridad si data es null

    if (data == null) {
      // Retornar un usuario vacío o manejar el error si el documento no tiene datos
      return UserModel(
        id: doc.id,
        nombre: 'Usuario Desconocido',
        email: '',
        telefono: '',
      );
    }

    return UserModel(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      telefono: data['telefono'] ?? '',
      telefono2: data['telefono2'] ?? '',
      tieneAlergia: data['tieneAlergia'] ?? 'No',
      tieneDiabetes: data['tieneDiabetes'] ?? 'No',
      role: data['role'] ?? 'client',
      isAdmin: data['isAdmin'] ?? false,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      fcmToken: data['fcmToken'],
      photoUrl: data['photoUrl'],
    );
  }

  // Método para convertir a Map (útil si necesitas actualizar datos)
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'telefono2': telefono2,
      'tieneAlergia': tieneAlergia,
      'tieneDiabetes': tieneDiabetes,
      'role': role,
      'isAdmin': isAdmin,
      'photoUrl': photoUrl,
      // No incluimos createdAt para no sobrescribirlo accidentalmente
    };
  }
}