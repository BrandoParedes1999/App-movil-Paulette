import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paulette/models/notificacion_model.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 📬 Crear notificación
  Future<bool> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? appointmentId,
  }) async {
    try {
      final notification = AppNotification(
        id: const Uuid().v4(),
        userId: userId,
        title: title,
        body: body,
        type: type,
        appointmentId: appointmentId,
        createdAt: DateTime.now(),
      );

      await _db
          .collection("notifications")
          .doc(notification.id)
          .set(notification.toMap());

      return true;
    } catch (e) {
      print("🔥 Error al crear notificación: $e");
      return false;
    }
  }

  /// 📨 Notificar aprobación de cita
  Future<bool> notifyAppointmentApproved({
    required String userId,
    required String appointmentId,
    required String designTitle,
    required DateTime date,
    required String time,
  }) async {
    return await createNotification(
      userId: userId,
      title: "¡Cita Aprobada! 🎉",
      body: "Tu cita de $designTitle para el ${_formatDate(date)} a las $time ha sido aprobada.",
      type: "appointment_approved",
      appointmentId: appointmentId,
    );
  }

  /// 📨 Notificar rechazo de cita
  Future<bool> notifyAppointmentRejected({
    required String userId,
    required String appointmentId,
    required String designTitle,
  }) async {
    return await createNotification(
      userId: userId,
      title: "Cita No Disponible 😔",
      body: "Lo sentimos, la cita de $designTitle no pudo ser confirmada. Por favor, selecciona otro horario.",
      type: "appointment_rejected",
      appointmentId: appointmentId,
    );
  }

  /// 📨 Notificar recordatorio
  Future<bool> notifyReminder({
    required String userId,
    required String appointmentId,
    required String designTitle,
    required DateTime date,
    required String time,
  }) async {
    return await createNotification(
      userId: userId,
      title: "Recordatorio de Cita ⏰",
      body: "Tienes una cita de $designTitle mañana ${_formatDate(date)} a las $time. ¡Te esperamos!",
      type: "reminder",
      appointmentId: appointmentId,
    );
  }

  /// 📖 Obtener notificaciones del usuario
  Stream<List<AppNotification>> getUserNotifications(String userId) {
    return _db
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.data()))
          .toList();
    });
  }

  /// ✅ Marcar como leída
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _db.collection("notifications").doc(notificationId).update({
        "isRead": true,
      });
      return true;
    } catch (e) {
      print("🔥 Error al marcar notificación: $e");
      return false;
    }
  }

  /// ✅ Marcar todas como leídas
  Future<bool> markAllAsRead(String userId) async {
    try {
      final batch = _db.batch();
      final snapshot = await _db
          .collection("notifications")
          .where("userId", isEqualTo: userId)
          .where("isRead", isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {"isRead": true});
      }

      await batch.commit();
      return true;
    } catch (e) {
      print("🔥 Error al marcar todas: $e");
      return false;
    }
  }

  /// 🔢 Contar no leídas
  Stream<int> getUnreadCount(String userId) {
    return _db
        .collection("notifications")
        .where("userId", isEqualTo: userId)
        .where("isRead", isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// 🗑️ Eliminar notificación
  Future<bool> deleteNotification(String notificationId) async {
    try {
      await _db.collection("notifications").doc(notificationId).delete();
      return true;
    } catch (e) {
      print("🔥 Error al eliminar notificación: $e");
      return false;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return "${date.day} de ${months[date.month - 1]}";
  }
}