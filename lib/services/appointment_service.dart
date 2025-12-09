import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:paulette/services/notificacion_Service.dart';
import '../models/appointment.dart';

class AppointmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // ✅ LISTA MAESTRA DE HORARIOS: Única fuente para toda la app
  static const List<String> timeSlots = [
    "09:00 AM", "10:00 AM", "11:00 AM", "12:00 PM",
    "01:00 PM", "02:00 PM", "03:00 PM", "04:00 PM", "05:00 PM", "06:00 PM"
  ];

  // ---------------------------------------------------------
  // 🔹 1. Crear Cita (Cliente)
  // ---------------------------------------------------------
  Future<bool> createAppointment(Appointment appointment) async {
    try {
      await _db.collection("appointments").doc(appointment.id).set(appointment.toMap());
      return true;
    } catch (e) {
      print("🔥 Error al crear cita: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // 🔹 2. Bloquear Horarios (Admin - Lógica Batch)
  // ---------------------------------------------------------
  Future<bool> blockTimeSlots({
    required DateTime date,
    required String reason,
    bool blockFullDay = false,
    String? startTime,
    String? endTime,
  }) async {
    try {
      final WriteBatch batch = _db.batch();
      List<String> slotsToBlock = [];

      // Definir qué horas se bloquean
      if (blockFullDay) {
        slotsToBlock = timeSlots;
      } else if (startTime != null && endTime != null) {
        final startIndex = timeSlots.indexOf(startTime);
        final endIndex = timeSlots.indexOf(endTime);
        
        if (startIndex != -1 && endIndex != -1 && startIndex <= endIndex) {
          slotsToBlock = timeSlots.sublist(startIndex, endIndex + 1);
        } else {
          slotsToBlock = [startTime];
        }
      } else if (startTime != null) {
        slotsToBlock = [startTime];
      }

      // Crear documentos de bloqueo
      for (String time in slotsToBlock) {
        final docRef = _db.collection("appointments").doc();
        
        // Normalizar fecha (sin horas/minutos)
        final cleanDate = DateTime(date.year, date.month, date.day);

        final blockedSlot = Appointment(
          id: docRef.id,
          userId: "ADMIN_BLOCK",
          userName: "⛔ BLOQUEADO",
          designId: "block",
          designTitle: reason.isEmpty ? "No Disponible" : reason,
          imageUrl: "https://cdn-icons-png.flaticon.com/512/1828/1828843.png",
          date: cleanDate, // Guardar fecha limpia
          time: time,
          status: "blocked", // Estado especial
          createdAt: DateTime.now(),
          price: 0.0,
          description: "Bloqueo administrativo: $reason",
        );

        batch.set(docRef, blockedSlot.toMap());
      }

      await batch.commit();
      return true;
    } catch (e) {
      print("🔥 Error bloqueando horarios: $e");
      return false;
    }
  }

  // ---------------------------------------------------------
  // 🔹 3. Consultar Disponibilidad (Cliente)
  // ---------------------------------------------------------
  Future<List<String>> getOccupiedTimeSlots(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _db
          .collection("appointments")
          .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where("date", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          // IMPORTANTE: Incluir 'blocked' para que aparezcan en gris
          .where("status", whereIn: ["pending", "approved", "blocked"])
          .get();

      return snapshot.docs.map((doc) => doc.data()["time"] as String).toList();
    } catch (e) {
      print("🔥 Error obteniendo horarios: $e");
      return [];
    }
  }

  Future<bool> isTimeSlotAvailable(DateTime date, String time) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _db
          .collection("appointments")
          .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where("date", isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where("time", isEqualTo: time)
          .where("status", whereIn: ["pending", "approved", "blocked"])
          .get();

      return snapshot.docs.isEmpty;
    } catch (e) {
      return true;
    }
  }

  // ---------------------------------------------------------
  // 🔹 Métodos Auxiliares (Getters, Updates, Deletes)
  // ---------------------------------------------------------
  Stream<List<Appointment>> getAllAppointments() {
    return _db.collection("appointments")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Appointment.fromMap(d.data())).toList());
  }

  Stream<List<Appointment>> getAppointmentsByUser(String userId) {
    return _db.collection("appointments")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Appointment.fromMap(d.data())).toList());
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      final doc = await _db.collection("appointments").doc(id).get();
      if(!doc.exists) return false;
      final appt = Appointment.fromMap(doc.data()!);
      
      await _db.collection("appointments").doc(id).update({"status": status});
      
      if(status == "approved") {
        _notificationService.notifyAppointmentApproved(userId: appt.userId, appointmentId: id, designTitle: appt.designTitle, date: appt.date, time: appt.time);
      } else if (status == "cancelled") {
        _notificationService.notifyAppointmentRejected(userId: appt.userId, appointmentId: id, designTitle: appt.designTitle);
      }
      return true;
    } catch(e) { return false; }
  }

  Future<bool> updateStatusAndDetails(String id, String status, double price, int duration) async {
    try {
      final doc = await _db.collection("appointments").doc(id).get();
      if(!doc.exists) return false;
      final appt = Appointment.fromMap(doc.data()!);

      await _db.collection("appointments").doc(id).update({
        "status": status, "price": price, "durationMinutes": duration
      });
      
      if(status == "approved") {
        _notificationService.notifyAppointmentApproved(userId: appt.userId, appointmentId: id, designTitle: appt.designTitle, date: appt.date, time: appt.time);
      }
      return true;
    } catch(e) { return false; }
  }
  
  Future<bool> deleteAppointment(String id) async {
    try { await _db.collection("appointments").doc(id).delete(); return true; } catch(e) { return false; }
  }
  
  Future<bool> hasRating(String id) async {
    try { 
      final doc = await _db.collection("appointments").doc(id).get();
      return doc.exists && (doc.data()?["hasRating"] ?? false);
    } catch(e) { return false; }
  }

  /// ---------------------------------------------------------
  /// 🧹 LIMPIEZA AUTOMÁTICA (Auto-Cleanup)
  /// Borra bloqueos y citas 'pendientes' antiguas (de ayer o antes)
  /// ---------------------------------------------------------
  Future<void> deleteOldAppointments() async {
    try {
      // Definimos "antiguo" como todo lo anterior al inicio del día de hoy
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day); 

      // Buscamos documentos viejos
      // NOTA: Esto requiere un índice compuesto en Firestore si hay muchos datos
      // (date < today)
      final snapshot = await _db.collection("appointments")
          .where("date", isLessThan: Timestamp.fromDate(startOfToday))
          .get();

      if (snapshot.docs.isEmpty) return;

      final WriteBatch batch = _db.batch();
      int count = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? '';

        // REGLAS DE LIMPIEZA:
        // 1. Borrar 'blocked' antiguos (ya pasaron, no sirven)
        // 2. Borrar 'cancelled' antiguos (historial basura)
        // 3. Borrar 'pending' antiguos (citas que nunca se aprobaron y ya pasó la fecha)
        // 4. (Opcional) NO borrar 'completed' ni 'approved' si quieres historial de ventas
        
        if (status == 'blocked' || status == 'cancelled' || status == 'pending') {
          batch.delete(doc.reference);
          count++;
        }
      }

      if (count > 0) {
        await batch.commit();
        print("🧹 Limpieza completada: $count registros antiguos eliminados.");
      }
    } catch (e) {
      print("⚠️ Error en limpieza automática: $e");
    }
  }

  // ⭐ NUEVO: Calificar Cita (Rating)
  // ---------------------------------------------------------
  Future<void> rateAppointment(String appointmentId, String designId, double rating, String comment) async {
    try {
      final WriteBatch batch = _db.batch();
      
      // 1. Crear el documento de calificación
      final ratingRef = _db.collection('ratings').doc();
      batch.set(ratingRef, {
        'appointmentId': appointmentId,
        'designId': designId, // Para saber qué diseño gustó más
        'rating': rating,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Marcar la cita como "ya calificada" para no duplicar
      final appointmentRef = _db.collection('appointments').doc(appointmentId);
      batch.update(appointmentRef, {'hasRating': true});

      await batch.commit();
    } catch (e) {
      print("🔥 Error al calificar: $e");
      throw e;
    }
  }
}