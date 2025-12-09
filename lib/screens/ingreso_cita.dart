import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../models/user_model.dart';
import '../services/appointment_service.dart';
import '../services/user_service.dart';

class IngresoCita extends StatefulWidget {
  final Appointment cita; // 1. Recibimos la cita real

  const IngresoCita({super.key, required this.cita});

  @override
  State<IngresoCita> createState() => _IngresoCitaState();
}

class _IngresoCitaState extends State<IngresoCita> {
  final AppointmentService _appointmentService = AppointmentService();
  final UserService _userService = UserService();
  bool _isLoading = false;

  // Función para finalizar la cita
  Future<void> _finalizarCita() async {
    setState(() => _isLoading = true);
    
    try {
      // 2. Actualizamos el estado a 'completed' en Firebase
      final success = await _appointmentService.updateStatus(
        widget.cita.id, 
        "completed"
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Cita finalizada con éxito"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volver atrás
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al finalizar la cita"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Detalle de Cita"), elevation: 0),
      body: FutureBuilder<UserModel?>(
        // 3. Buscamos información médica del cliente
        future: _userService.getUserById(widget.cita.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          final tieneDiabetes = user?.tieneDiabetes.toLowerCase() == 'sí';
          final tieneAlergia = user?.tieneAlergia.toLowerCase() == 'sí';

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              // Imagen del Diseño
              Container(
                height: 250,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20, top: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    widget.cita.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[300], child: const Icon(Icons.broken_image)),
                  ),
                ),
              ),

              // Datos del Cliente y Cita
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Cliente: ${widget.cita.userName ?? 'Desconocido'}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text("Servicio: ${widget.cita.designTitle}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text("Horario: ${DateFormat('dd/MM/yyyy').format(widget.cita.date)} - ${widget.cita.time}", style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    Text("Precio: \$${widget.cita.price.toStringAsFixed(2)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                    
                    const SizedBox(height: 20),
                    // Alertas Médicas
                    _buildMedicalAlert("Diabetes", tieneDiabetes),
                    _buildMedicalAlert("Alergias", tieneAlergia),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              
              // Notas / Descripción
              if (widget.cita.description != null && widget.cita.description!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300)
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Notas del cliente:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(widget.cita.description!),
                    ],
                  ),
                ),

              const SizedBox(height: 40),

              // Botón Finalizar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _finalizarCita,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Finalizar Cita (Completar)", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMedicalAlert(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isActive ? Colors.red.shade200 : Colors.green.shade200)
      ),
      child: Row(
        children: [
          Icon(isActive ? Icons.warning : Icons.check_circle, color: isActive ? Colors.red : Colors.green),
          const SizedBox(width: 10),
          Text("$label: ${isActive ? 'SÍ' : 'No'}", style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.red : Colors.green)),
        ],
      ),
    );
  }
}