import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:paulette/models/appointment.dart';
import 'package:paulette/services/appointment_service.dart';
import 'package:uuid/uuid.dart';

class BookAppointmentScreen extends StatefulWidget {
  final String designId;
  final String designTitle;
  final String imageUrl;
  final double price;

  const BookAppointmentScreen({
    super.key,
    required this.designId,
    required this.designTitle,
    required this.imageUrl,
    required this.price,
  });

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? selectedDate;
  String? selectedTime;
  
  // Variables de control de estado
  bool isLoading = false;
  bool isLoadingSlots = false;
  List<String> _occupiedTimes = []; 

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  // 📅 AL SELECCIONAR FECHA: Consultamos BD
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.pinkAccent, onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        selectedTime = null; 
        _occupiedTimes = []; // Limpiar para no mostrar datos viejos
        isLoadingSlots = true; // Mostrar spinner
      });

      // 🔍 Consulta real a Firestore
      try {
        final occupied = await _appointmentService.getOccupiedTimeSlots(picked);
        setState(() {
          _occupiedTimes = occupied;
        });
      } catch (e) {
        print("Error: $e");
      } finally {
        setState(() => isLoadingSlots = false);
      }
    }
  }

  Future<void> _confirmAppointment() async {
    if (selectedDate == null || selectedTime == null) {
      _showError("Selecciona fecha y hora"); return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("Inicia sesión para continuar"); return;
    }

    setState(() => isLoading = true);

    try {
      // Doble verificación de seguridad
      final isAvailable = await _appointmentService.isTimeSlotAvailable(selectedDate!, selectedTime!);
      if (!isAvailable) {
        _showError("¡Ups! Ese horario acaba de ocuparse.");
        // Refrescar visualmente
        final occupied = await _appointmentService.getOccupiedTimeSlots(selectedDate!);
        setState(() {
          _occupiedTimes = occupied;
          selectedTime = null;
          isLoading = false;
        });
        return;
      }

      final appointment = Appointment(
        id: const Uuid().v4(),
        userId: user.uid,
        userName: user.displayName ?? user.email ?? "Usuario",
        designId: widget.designId,
        designTitle: widget.designTitle,
        imageUrl: widget.imageUrl,
        date: selectedDate!,
        time: selectedTime!,
        description: _descriptionController.text.trim(),
        status: "pending",
        createdAt: DateTime.now(),
        price: widget.price,
      );

      final success = await _appointmentService.createAppointment(appointment);
      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        _showError("Error al agendar.");
      }
    } catch (e) {
      if (mounted) _showError("Error: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showSuccessDialog() {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text("¡Listo!")]),
        content: const Text("Tu cita ha sido enviada."),
        actions: [TextButton(onPressed: () {Navigator.pop(ctx); Navigator.pop(ctx);}, child: const Text("Aceptar"))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text("Agendar Cita"), backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 250, decoration: BoxDecoration(image: DecorationImage(image: NetworkImage(widget.imageUrl), fit: BoxFit.cover))),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(widget.designTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.pinkAccent, borderRadius: BorderRadius.circular(20)), child: Text("\$${widget.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                  ]),
                  const SizedBox(height: 30),
                  
                  const Text("Selecciona una fecha", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today, color: Colors.pinkAccent), const SizedBox(width: 15),
                        Text(selectedDate == null ? "Toca para elegir fecha" : DateFormat('dd/MM/yyyy').format(selectedDate!), style: const TextStyle(fontSize: 16)),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Text("Horarios Disponibles", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  if (isLoadingSlots)
                    const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
                  else
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      // ⚠️ USAR LA LISTA DEL SERVICIO PARA COINCIDENCIA EXACTA
                      children: AppointmentService.timeSlots.map((time) {
                        final isSelected = time == selectedTime;
                        final isOccupied = _occupiedTimes.contains(time);

                        return GestureDetector(
                          onTap: (selectedDate == null || isOccupied) ? null : () => setState(() => selectedTime = time),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isOccupied ? Colors.grey.shade300 : (isSelected ? Colors.pinkAccent : Colors.white),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isOccupied ? Colors.transparent : (isSelected ? Colors.pinkAccent : Colors.grey.shade300)),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                color: isOccupied ? Colors.grey.shade600 : (isSelected ? Colors.white : Colors.black87),
                                fontWeight: FontWeight.w600,
                                decoration: isOccupied ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 25),
                  const Text("Notas (Opcional)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: _descriptionController, maxLines: 3, decoration: InputDecoration(hintText: "Detalles...", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 30),
                  
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: isLoading ? null : _confirmAppointment, style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Confirmar Reserva", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}