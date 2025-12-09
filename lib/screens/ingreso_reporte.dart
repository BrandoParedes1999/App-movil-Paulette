import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';

class IngresoReporte extends StatefulWidget {
  // Aceptamos una fecha opcional, si no se pasa, usa hoy.
  final DateTime? fechaReporte; 

  const IngresoReporte({super.key, this.fechaReporte});

  @override
  State<IngresoReporte> createState() => _IngresoReporteState();
}

class _IngresoReporteState extends State<IngresoReporte> {
  final AppointmentService _appointmentService = AppointmentService();

  @override
  Widget build(BuildContext context) {
    // Usar la fecha pasada o la de hoy
    final DateTime targetDate = widget.fechaReporte ?? DateTime.now();
    final String diaTexto = DateFormat('EEEE, d MMMM', 'es_ES').format(targetDate).toUpperCase();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("REPORTES DIARIOS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<List<Appointment>>(
        // 1. Obtenemos TODAS las citas (Filtrar en cliente es más fácil para reportes pequeños)
        // Idealmente AppointmentService debería tener un getAppointmentsByDate(date)
        stream: _appointmentService.getAllAppointments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildNoData(diaTexto);
          }

          // 2. FILTRADO LOCAL: Misma fecha (día, mes, año) Y estado 'completed'
          final citasDelDia = snapshot.data!.where((cita) {
            final isSameDay = cita.date.year == targetDate.year &&
                cita.date.month == targetDate.month &&
                cita.date.day == targetDate.day;
            return isSameDay && cita.status == 'completed';
          }).toList();

          // 3. CÁLCULOS
          final double totalIngresos = citasDelDia.fold(0.0, (sum, item) => sum + item.price);
          final int totalVentas = citasDelDia.length;
          
          // Opcional: Separar Manicura vs Pedicure basándose en el título o ID
          // Como no tenemos campo 'category' estricto en Appointment, hacemos una búsqueda simple en el título
          final int cantPedicure = citasDelDia.where((c) => c.designTitle.toLowerCase().contains('pedicura') || c.designTitle.toLowerCase().contains('pies')).length;
          final int cantManicure = totalVentas - cantPedicure; // Asumimos el resto es manicure

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(width: 2, color: Colors.black),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(diaTexto, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 20),
                      const Text("RESUMEN DE VENTAS", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const Divider(thickness: 2),
                      const SizedBox(height: 30),
                      
                      // Detalles
                      _buildStatRow("Manicura", cantManicure),
                      const SizedBox(height: 15),
                      _buildStatRow("Pedicura", cantPedicure),
                      
                      const SizedBox(height: 50),
                      
                      // Total
                      const Text("TOTAL GENERADO", style: TextStyle(fontSize: 16, color: Colors.grey)),
                      Text(
                        "\$${totalIngresos.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      
                      const SizedBox(height: 40),
                      // Botón PDF (Visual por ahora)
                      ElevatedButton.icon(
                        onPressed: totalVentas > 0 ? () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Generando PDF... (Próximamente)")));
                        } : null,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Exportar PDF"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatRow(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 18)),
        Text("$count ventas", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildNoData(String dia) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(dia, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          const Icon(Icons.money_off, size: 60, color: Colors.grey),
          const SizedBox(height: 10),
          const Text("No hay ventas registradas este día"),
        ],
      ),
    );
  }
}