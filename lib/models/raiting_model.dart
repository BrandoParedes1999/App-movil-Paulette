import 'package:cloud_firestore/cloud_firestore.dart';

class Rating {
  final String id;
  final String appointmentId;
  final String userId;
  final String userName;
  final String designId;
  final int stars; // 1-5
  final String? comment;
  final DateTime createdAt;

  Rating({
    required this.id,
    required this.appointmentId,
    required this.userId,
    required this.userName,
    required this.designId,
    required this.stars,
    this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "appointmentId": appointmentId,
      "userId": userId,
      "userName": userName,
      "designId": designId,
      "stars": stars,
      "comment": comment,
      "createdAt": Timestamp.fromDate(createdAt),
    };
  }

  factory Rating.fromMap(Map<String, dynamic> data) {
    return Rating(
      id: data["id"] ?? "",
      appointmentId: data["appointmentId"] ?? "",
      userId: data["userId"] ?? "",
      userName: data["userName"] ?? "Usuario",
      designId: data["designId"] ?? "",
      stars: data["stars"] ?? 0,
      comment: data["comment"],
      createdAt: (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}