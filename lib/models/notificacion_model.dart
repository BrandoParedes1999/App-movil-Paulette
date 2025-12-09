import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type; // "appointment_approved", "appointment_rejected", "reminder"
  final String? appointmentId;
  final DateTime createdAt;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.appointmentId,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "userId": userId,
      "title": title,
      "body": body,
      "type": type,
      "appointmentId": appointmentId,
      "createdAt": Timestamp.fromDate(createdAt),
      "isRead": isRead,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> data) {
    return AppNotification(
      id: data["id"] ?? "",
      userId: data["userId"] ?? "",
      title: data["title"] ?? "",
      body: data["body"] ?? "",
      type: data["type"] ?? "",
      appointmentId: data["appointmentId"],
      createdAt: (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data["isRead"] ?? false,
    );
  }
}