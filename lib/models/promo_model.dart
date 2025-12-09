import 'package:cloud_firestore/cloud_firestore.dart';

class PromoModel {
  final String id;
  final String title;
  final String description;
  final double discount; // Porcentaje o monto
  final DateTime validUntil;
  final bool isActive;

  PromoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.validUntil,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'discount': discount,
      'validUntil': Timestamp.fromDate(validUntil),
      'isActive': isActive,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory PromoModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PromoModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      discount: (data['discount'] ?? 0.0).toDouble(),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }
}