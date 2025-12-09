import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:paulette/models/appointment.dart';
import 'package:paulette/services/appointment_service.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  String _selectedFilter = "Todas";

  final List<String> _filters = ["Todas", "Pendientes", "Aprobadas", "Completadas", "Canceladas"];

  // Lógica de filtrado en cliente
  List<Appointment> _applyFilter(List<Appointment> list) {
    if (_selectedFilter == "Todas") return list;
    
    String statusKey = "";
    if (_selectedFilter == "Pendientes") statusKey = "pending";
    else if (_selectedFilter == "Aprobadas") statusKey = "approved";
    else if (_selectedFilter == "Completadas") statusKey = "completed";
    else if (_selectedFilter == "Canceladas") statusKey = "cancelled";

    return list.where((a) => a.status == statusKey).toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Inicia sesión")));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mis Citas", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. BARRA DE FILTROS HORIZONTAL
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedFilter = filter),
                  selectedColor: Colors.pinkAccent,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              },
            ),
          ),

          // 2. LISTA DE CITAS
          Expanded(
            child: StreamBuilder<List<Appointment>>(
              stream: _appointmentService.getAppointmentsByUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final filteredList = _applyFilter(snapshot.data!);

                if (filteredList.isEmpty) {
                  return Center(child: Text("No tienes citas $_selectedFilter", style: const TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    return _AppointmentUserCard(
                      appointment: filteredList[index],
                      service: _appointmentService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 20),
          const Text("Aún no tienes citas agendadas", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------
// WIDGET: TARJETA DE CITA (CLIENTE)
// ------------------------------------------------------
class _AppointmentUserCard extends StatelessWidget {
  final Appointment appointment;
  final AppointmentService service;

  const _AppointmentUserCard({required this.appointment, required this.service});

  // Colores según estado
  Color _getColor() {
    switch (appointment.status) {
      case 'pending': return Colors.orange;
      case 'approved': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  // Textos según estado
  String _getStatusText() {
    switch (appointment.status) {
      case 'pending': return "Pendiente";
      case 'approved': return "Confirmada";
      case 'completed': return "Finalizada";
      case 'cancelled': return "Cancelada";
      default: return "Desconocido";
    }
  }

  // ACCIÓN: Cancelar Cita
  void _cancelAppointment(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Cancelar Cita?"),
        content: const Text("¿Estás segura? Esta acción liberará el horario."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Volver")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sí, Cancelar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await service.updateStatus(appointment.id, "cancelled");
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cita cancelada")));
    }
  }

  // ACCIÓN: Calificar Cita (CORREGIDA)
  void _rateAppointment(BuildContext context) {
    double rating = 5.0;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Califica tu experiencia", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("¿Qué te pareció el servicio?"),
              const SizedBox(height: 15),
              
              // ⚠️ CORRECCIÓN DE OVERFLOW AQUÍ ⚠️
              // Usamos FittedBox para asegurar que se ajusten si la pantalla es pequeña
              FittedBox(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      // Eliminamos el padding extra para que quepan
                      padding: const EdgeInsets.symmetric(horizontal: 2), 
                      constraints: const BoxConstraints(), // Quita restricciones de tamaño mínimo
                      onPressed: () => setDialogState(() => rating = index + 1.0),
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32, // Tamaño cómodo
                      ),
                    );
                  }),
                ),
              ),
              
              const SizedBox(height: 15),
              TextField(
                controller: commentCtrl,
                decoration: InputDecoration(
                  hintText: "Escribe un comentario (opcional)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Omitir")),
            ElevatedButton(
              onPressed: () async {
                await service.rateAppointment(appointment.id, appointment.designId, rating, commentCtrl.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Gracias por tu opinión!")));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Enviar", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          // HEADER: Imagen y Estado
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  appointment.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) => Container(height: 120, color: Colors.grey[200]),
                ),
              ),
              Positioned(
                top: 10, right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: _getColor(), borderRadius: BorderRadius.circular(20)),
                  child: Text(_getStatusText(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ),
            ],
          ),

          // INFO
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(appointment.designTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    Text("\$${appointment.price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(DateFormat('dd/MM/yyyy').format(appointment.date), style: TextStyle(color: Colors.grey[700])),
                    const SizedBox(width: 15),
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 5),
                    Text(appointment.time, style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                
                // BOTONES DE ACCIÓN
                const SizedBox(height: 15),
                if (appointment.status == 'pending' || appointment.status == 'approved')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _cancelAppointment(context),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      child: const Text("Cancelar Cita"),
                    ),
                  ),
                
                if (appointment.status == 'completed')
                  // Verificación segura para mostrar botón de calificar
                  FutureBuilder<bool>(
                    future: service.hasRating(appointment.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                      
                      // Si NO tiene rating (false), mostramos botón
                      if (snapshot.hasData && snapshot.data == false) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _rateAppointment(context),
                            icon: const Icon(Icons.star, size: 18),
                            label: const Text("Calificar Servicio"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.white),
                          ),
                        );
                      }
                      // Si YA tiene rating
                      if (snapshot.hasData && snapshot.data == true) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Center(
                            child: Text("✅ ¡Gracias por tu calificación!", 
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  )
              ],
            ),
          )
        ],
      ),
    );
  }
}