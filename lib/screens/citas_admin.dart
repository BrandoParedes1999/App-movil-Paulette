import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

class AdminAppointmentsPanel extends StatefulWidget {
  const AdminAppointmentsPanel({super.key});

  @override
  State<AdminAppointmentsPanel> createState() => _AdminAppointmentsPanelState();
}

class _AdminAppointmentsPanelState extends State<AdminAppointmentsPanel>
    with SingleTickerProviderStateMixin {
  final AppointmentService _appointmentService = AppointmentService();
  final UserService _userService = UserService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // 🧹 EJECUTAR LIMPIEZA SILENCIOSA
    // Usamos addPostFrameCallback para no bloquear la construcción de la UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _appointmentService.deleteOldAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🎨 Color según estado
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.blue;
      case "completed":
        return Colors.green;
      case "cancelled":
      case "canceled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // =======================================================
  // 🛡️ NUEVO: Lógica de Bloqueo de Horario
  // =======================================================
  void _showBlockTimeDialog() {
    final dateCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    DateTime? selectedDate;
    String? startTime;
    String? endTime;
    bool isFullDay = false;

    // Usamos la lista maestra del servicio para evitar errores de texto
    final List<String> adminTimeSlots = AppointmentService.timeSlots;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Bloquear Agenda"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: reasonCtrl,
                    decoration: const InputDecoration(
                      labelText: "Motivo (ej. Vacaciones)",
                      prefixIcon: Icon(
                        Icons.info_outline,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: dateCtrl,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Fecha",
                      prefixIcon: Icon(
                        Icons.calendar_month,
                        color: Colors.pinkAccent,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setDialogState(() {
                          selectedDate = date;
                          dateCtrl.text = DateFormat('dd/MM/yyyy').format(date);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text(
                      "Bloquear todo el día",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    value: isFullDay,
                    activeColor: Colors.red,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setDialogState(() {
                        isFullDay = val;
                        if (val) {
                          startTime = null;
                          endTime = null;
                        }
                      });
                    },
                  ),
                  if (!isFullDay) ...[
                    const Divider(),
                    const Text(
                      "Rango de Horas",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            hint: const Text(
                              "Inicio",
                              style: TextStyle(fontSize: 12),
                            ),
                            value: startTime,
                            items: adminTimeSlots
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                      t,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setDialogState(() => startTime = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            hint: const Text(
                              "Fin",
                              style: TextStyle(fontSize: 12),
                            ),
                            value: endTime,
                            items: adminTimeSlots
                                .where(
                                  (t) =>
                                      startTime == null ||
                                      adminTimeSlots.indexOf(t) >=
                                          adminTimeSlots.indexOf(startTime!),
                                )
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                      t,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setDialogState(() => endTime = v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (selectedDate == null || reasonCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Completa fecha y motivo")),
                    );
                    return;
                  }
                  if (!isFullDay && startTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Selecciona hora de inicio"),
                      ),
                    );
                    return;
                  }

                  await _appointmentService.blockTimeSlots(
                    date: selectedDate!,
                    reason: reasonCtrl.text.trim(),
                    blockFullDay: isFullDay,
                    startTime: startTime,
                    endTime: endTime ?? startTime,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Bloqueo aplicado")),
                    );
                  }
                },
                child: const Text("Bloquear"),
              ),
            ],
          );
        },
      ),
    );
  }

  // =======================================================
  // Funcionalidad 5: Ajuste de Duración/Precio al Aprobar
  // =======================================================

  /// ✅ Aprobar cita (MODIFICADO para mostrar diálogo de ajuste)
  Future<void> _approveAppointment(Appointment appointment) async {
    final result = await _showApprovalDialog(
      context,
      appointment.price,
      appointment.description,
    );

    if (result == null || !mounted) return;

    final success = await _appointmentService.updateStatusAndDetails(
      appointment.id,
      "approved",
      result['price'] as double,
      result['duration'] as int,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? "Cita aprobada y detalles ajustados"
                : "Error al aprobar cita",
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  /// ❌ Rechazar cita (o eliminar bloqueo)
  Future<void> _rejectAppointment(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Rechazar cita?"),
        content: const Text("El cliente será notificado del rechazo."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Rechazar"),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await _appointmentService.updateStatus(
        appointmentId,
        "cancelled",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? "Cita rechazada" : "Error al rechazar cita",
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    }
  }

  /// ✔️ Completar cita
  Future<void> _completeAppointment(String appointmentId) async {
    final success = await _appointmentService.updateStatus(
      appointmentId,
      "completed",
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? "Cita completada" : "Error al completar"),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // 🧹 Lógica para eliminar un bloqueo (Borrado directo)
  Future<void> _deleteBlock(String appointmentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Desbloquear Horario?"),
        content: const Text(
          "Este horario volverá a estar disponible para clientes.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Desbloquear"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _appointmentService.deleteAppointment(appointmentId);
    }
  }

  /// 📋 Lista de citas según filtro
  Widget _buildAppointmentsList(String status) {
    return StreamBuilder<List<Appointment>>(
      stream: _appointmentService.getAllAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.pinkAccent),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No hay registros",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        List<Appointment> filtered = snapshot.data!;

        // Filtro especial: Si estamos en la pestaña "Todas", mostramos todo.
        // Si no, filtramos por estado.
        // PERO: Los bloqueos (blocked) solo los mostramos en "Todas" o en una pestaña especial si quisieras.
        // Aquí los mostraremos en "Todas" y "Pendientes" (opcional) o filtraremos blocked si no queremos verlos en listas normales.

        if (status != "all") {
          filtered = filtered.where((a) => a.status == status).toList();
        }

        if (filtered.isEmpty) {
          return const Center(
            child: Text(
              "Sin datos en esta categoría",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final appointment = filtered[index];
            return _AppointmentCard(
              appointment: appointment,
              onApprove: () => _approveAppointment(appointment),
              onReject: () => _rejectAppointment(appointment.id),
              onComplete: () => _completeAppointment(appointment.id),
              onUnblock: () =>
                  _deleteBlock(appointment.id), // Nueva callback para bloqueos
              userService: _userService,
            );
          },
        );
      },
    );
  }

  // =======================================================
  // Dialogo de Ajuste de Precio/Duración
  // =======================================================
  Future<Map<String, dynamic>?> _showApprovalDialog(
    BuildContext context,
    double originalPrice,
    String? clientDescription,
  ) async {
    final priceController = TextEditingController(
      text: originalPrice.toStringAsFixed(2),
    );
    final durationController = TextEditingController(text: '60');

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aprobar y Ajustar Cita"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Notas del Cliente:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                clientDescription != null && clientDescription.isNotEmpty
                    ? clientDescription
                    : "No hay notas adicionales.",
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "Duración Final (Minutos)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Ej. 60",
                  prefixIcon: Icon(Icons.access_time),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Precio Final (\$)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Costo total",
                  prefixText: "\$",
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              final duration = int.tryParse(durationController.text);
              if (price == null ||
                  duration == null ||
                  price <= 0 ||
                  duration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ingresa valores válidos")),
                );
                return;
              }
              Navigator.pop(context, {'price': price, 'duration': duration});
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Aprobar Cita"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Panel de Administración",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 🛑 BOTÓN PARA BLOQUEAR HORARIO
          IconButton(
            icon: const Icon(Icons.block, color: Colors.white),
            tooltip: "Bloquear Horario",
            onPressed: _showBlockTimeDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Todas"),
            Tab(text: "Pendientes"),
            Tab(text: "Aprobadas"),
            Tab(text: "Completadas"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppointmentsList("all"),
          _buildAppointmentsList("pending"),
          _buildAppointmentsList("approved"),
          _buildAppointmentsList("completed"),
        ],
      ),
    );
  }
}

/// Widget de tarjeta de cita
class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final UserService userService;
  final Function() onApprove;
  final VoidCallback onReject;
  final VoidCallback onComplete;
  final VoidCallback onUnblock; // Nuevo callback para desbloquear

  const _AppointmentCard({
    required this.appointment,
    required this.userService,
    required this.onApprove,
    required this.onReject,
    required this.onComplete,
    required this.onUnblock,
  });

  // 🔹 LÓGICA WHATSAPP INTELIGENTE
  void _handleWhatsApp(BuildContext context, UserModel user) {
    final phone1 = user.telefono.replaceAll(RegExp(r'[^0-9]'), '');
    final phone2 = user.telefono2.replaceAll(RegExp(r'[^0-9]'), '');

    // MENSAJE PERSONALIZADO
    final message =
        "Hola ${user.nombre}, te escribimos de Paulette Salón respecto a tu cita del ${DateFormat('dd/MM').format(appointment.date)} a las ${appointment.time}.";

    if (phone1.isEmpty && phone2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cliente sin teléfono registrado")),
      );
      return;
    }

    if (phone1.isNotEmpty && phone2.isEmpty) {
      _launchWhatsAppUrl(phone1, message);
      return;
    }

    if (phone1.isEmpty && phone2.isNotEmpty) {
      _launchWhatsAppUrl(phone2, message);
      return;
    }

    // Dos números: Preguntar
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: Center(
                child: Text(
                  "Contactar Cliente",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.green,
              ),
              title: Text("Principal: ${user.telefono}"),
              onTap: () {
                Navigator.pop(context);
                _launchWhatsAppUrl(phone1, message);
              },
            ),
            ListTile(
              leading: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.teal,
              ),
              title: Text("Respaldo: ${user.telefono2}"),
              onTap: () {
                Navigator.pop(context);
                _launchWhatsAppUrl(phone2, message);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsAppUrl(String phone, String message) async {
    // Código de país +52 para México (ajustable)
    final url = Uri.parse(
      "https://wa.me/+52$phone?text=${Uri.encodeComponent(message)}",
    );
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      print("Error WhatsApp: $e");
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.blue;
      case "completed":
        return Colors.green;
      case "blocked":
        return Colors.grey; // Color para bloqueado
      default:
        return Colors.red;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return "Pendiente";
      case "approved":
        return "Aprobada";
      case "completed":
        return "Completada";
      case "blocked":
        return "Bloqueado";
      default:
        return "Cancelada";
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ CASO ESPECIAL: Si está BLOQUEADO, mostramos una tarjeta simple
    if (appointment.status == "blocked") {
      return Card(
        color: Colors.grey.shade200,
        margin: const EdgeInsets.only(bottom: 15),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.redAccent,
            child: Icon(Icons.block, color: Colors.white),
          ),
          title: Text(
            "Bloqueo: ${appointment.designTitle}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          subtitle: Text(
            "${DateFormat('dd/MM/yyyy').format(appointment.date)} - ${appointment.time}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            tooltip: "Desbloquear",
            onPressed: onUnblock, // Llama a la función de borrado
          ),
        ),
      );
    }

    // TARJETA NORMAL PARA CITAS DE CLIENTES
    return FutureBuilder<UserModel?>(
      future: userService.getUserById(appointment.userId),
      builder: (context, snapshot) {
        final UserModel? user = snapshot.data;

        final bool hasDiabetes =
            (user?.tieneDiabetes.toLowerCase() == 'sí' ||
            user?.tieneDiabetes.toLowerCase() == 'si');
        final bool hasAlergy =
            (user?.tieneAlergia.toLowerCase() == 'sí' ||
            user?.tieneAlergia.toLowerCase() == 'si');

        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: Column(
            children: [
              // Header con imagen y Badges
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      appointment.imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        height: 120,
                        color: Colors.grey.shade300,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        _getStatusText(appointment.status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (hasDiabetes)
                    const Positioned(
                      bottom: 10,
                      left: 10,
                      child: _HealthBadge(
                        text: "⚠️ DIABETES",
                        color: Colors.red,
                      ),
                    ),
                  if (hasAlergy)
                    Positioned(
                      bottom: hasDiabetes ? 35 : 10,
                      left: 10,
                      child: const _HealthBadge(
                        text: "💊 ALERGIA",
                        color: Colors.orange,
                      ),
                    ),
                ],
              ),

              // Información
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            appointment.designTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          "\$${appointment.price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.pinkAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // FILA DEL CLIENTE CON BOTÓN DE WHATSAPP
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            user != null
                                ? user.nombre
                                : appointment.userName ?? "Cliente",
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        // 🟢 BOTÓN WHATSAPP AQUÍ
                        if (user != null)
                          IconButton(
                            icon: const FaIcon(
                              FontAwesomeIcons.whatsapp,
                              color: Colors.green,
                              size: 24,
                            ),
                            tooltip: "Contactar por WhatsApp",
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _handleWhatsApp(context, user),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          DateFormat('dd/MM/yyyy').format(appointment.date),
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(width: 15),
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          appointment.time,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),

                    if (appointment.description != null &&
                        appointment.description!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Notas: ${appointment.description!}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    if (appointment.status == "pending") {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onApprove,
              icon: const Icon(Icons.check, size: 18),
              label: const Text("Aprobar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 18),
              label: const Text("Rechazar"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (appointment.status == "approved") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onComplete,
          icon: const Icon(Icons.verified, size: 18),
          label: const Text("Marcar como Completada"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

/// Helper para el Badge de Alerta Sanitaria
class _HealthBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _HealthBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
