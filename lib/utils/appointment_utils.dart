import 'package:flutter/material.dart';

class AppointmentStatus {
  static const String pending = "pending";
  static const String approved = "approved";
  static const String completed = "completed";
  static const String blocked = "blocked";
  static const String cancelled = "cancelled";
}

class AppointmentUtils {
  static Color getStatusColor(String status) {
    switch (status) {
      case AppointmentStatus.pending: return Colors.orange;
      case AppointmentStatus.approved: return Colors.blue;
      case AppointmentStatus.completed: return Colors.green;
      case AppointmentStatus.blocked: return Colors.grey;
      case AppointmentStatus.cancelled: return Colors.red;
      default: return Colors.blueGrey;
    }
  }

  static String getStatusText(String status) {
    switch (status) {
      case AppointmentStatus.pending: return "Pendiente";
      case AppointmentStatus.approved: return "Aprobada";
      case AppointmentStatus.completed: return "Completada";
      case AppointmentStatus.blocked: return "Bloqueado";
      default: return "Cancelada";
    }
  }
}