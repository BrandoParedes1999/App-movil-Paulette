import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String? userName;
  final String designId;
  final String designTitle;
  final String imageUrl;
  final DateTime date;
  final String time;
  final String? description;
  final String status;
  final DateTime createdAt;
  final double price; // <- nuevo campo

  Appointment({
    required this.id,
    required this.userId,
    this.userName,
    required this.designId,
    required this.designTitle,
    required this.imageUrl,
    required this.date,
    required this.time,
    this.description,
    this.status = "pending",
    required this.createdAt,
    required this.price,
  });

  // ---------- CONVERTIR A MAP PARA GUARDAR ----------
  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "userName": userName,
      "designId": designId,
      "designTitle": designTitle,
      "imageUrl": imageUrl,
      // Guardamos date y createdAt como Timestamp para compatibilidad con Firestore
      "date": Timestamp.fromDate(date),
      "time": time,
      "description": description,
      "status": status,
      "createdAt": Timestamp.fromDate(createdAt),
      "price": price,
    };
  }

  // ---------- CONVERTIR DESDE FIREBASE ----------
  factory Appointment.fromMap(Map<String, dynamic> data) {
    // Helper para parsear Date/Time que puede venir como String, Timestamp o num
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final d = DateTime.tryParse(value);
        return d ?? DateTime.now();
      }
      return DateTime.now();
    }

    double parsePrice(dynamic p) {
      if (p == null) return 0.0;
      if (p is double) return p;
      if (p is int) return p.toDouble();
      if (p is num) return p.toDouble();
      if (p is String) {
        return double.tryParse(p.replaceAll(RegExp(r'[^0-9\.\-]'), '')) ?? 0.0;
      }
      return 0.0;
    }

    return Appointment(
      id: (data["id"] ?? "") as String,
      userId: (data["userId"] ?? "") as String,
      userName: data["userName"] as String?,
      designId: (data["designId"] ?? "") as String,
      designTitle: (data["designTitle"] ?? "") as String,
      imageUrl: (data["imageUrl"] ?? "") as String,
      date: parseDate(data["date"]),
      time: (data["time"] ?? "") as String,
      description: data["description"] as String?,
      status: (data["status"] ?? "pending") as String,
      createdAt: parseDate(data["createdAt"]),
      price: parsePrice(data["price"]),
    );
  }
}