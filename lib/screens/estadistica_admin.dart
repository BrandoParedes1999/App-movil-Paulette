import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paulette/screens/ingreso_reporte.dart'; 
import '../models/appointment.dart';
import '../models/expense_model.dart';
import '../models/design_model_pedicure.dart';
import '../services/appointment_service.dart';
import '../services/expense_service.dart';
import '../services/pedicure_service.dart';

class EstadisticaAdmin extends StatefulWidget {
  const EstadisticaAdmin({super.key});

  @override
  State<EstadisticaAdmin> createState() => _EstadisticaAdminState();
}

class _EstadisticaAdminState extends State<EstadisticaAdmin> {
  final AppointmentService _appointmentService = AppointmentService();
  final ExpenseService _expenseService = ExpenseService();
  final PedicureService _pedicureService = PedicureService();

  // ----------------------------------------------------
  // 📊 SECCIÓN 1: KPIs Financieros (Ingresos - Gastos)
  // ----------------------------------------------------
  Widget _buildFinancialKPIs(List<Appointment> appointments, List<ExpenseModel> expenses) {
    // 1. Calcular Ingresos (Solo citas completadas)
    final completedAppointments = appointments.where((a) => a.status == "completed");
    final totalRevenue = completedAppointments.fold(0.0, (sum, a) => sum + a.price);

    // 2. Calcular Gastos Totales
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);

    // 3. Ganancia Neta
    final netProfit = totalRevenue - totalExpenses;

    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          // TARJETA PRINCIPAL: GANANCIA NETA
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ganancia Neta Real", 
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 5),
                Text("\$${netProfit.toStringAsFixed(2)}", 
                  style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          
          // FILA DE DETALLES
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: "Ventas Totales",
                  value: "\$${totalRevenue.toStringAsFixed(0)}",
                  color: Colors.blue,
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(
                  title: "Gastos Totales",
                  value: "-\$${totalExpenses.toStringAsFixed(0)}",
                  color: Colors.redAccent,
                  icon: Icons.money_off,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // 🏆 SECCIÓN 2: Top Manicura (Diseños Generales)
  // ----------------------------------------------------
  Widget _buildTopManicure(List<Appointment> appointments, List<PedicureServiceModel> pedicureServices) {
    // Filtramos para EXCLUIR los servicios que son de pedicura
    // Creamos un Set con los IDs de pedicura para búsqueda rápida
    final pedicureIds = pedicureServices.map((s) => s.id).toSet();
    final pedicureTitles = pedicureServices.map((s) => s.title).toSet(); // Backup por si id falla

    // Filtramos citas completadas/aprobadas que NO sean de pedicura
    final manicuraAppointments = appointments.where((a) {
      final isCompleted = a.status == "completed" || a.status == "approved";
      final isPedicure = pedicureIds.contains(a.designId) || pedicureTitles.contains(a.designTitle);
      return isCompleted && !isPedicure;
    });

    return _buildRankingList("💅 Top Diseños Manicura", manicuraAppointments);
  }

  // ----------------------------------------------------
  // 👣 SECCIÓN 3: Top Pedicura (Nuevo Requerimiento)
  // ----------------------------------------------------
  Widget _buildTopPedicure(List<Appointment> appointments, List<PedicureServiceModel> pedicureServices) {
    // Identificadores de pedicura
    final pedicureIds = pedicureServices.map((s) => s.id).toSet();
    final pedicureTitles = pedicureServices.map((s) => s.title).toSet();

    // Filtramos citas completadas/aprobadas que SÍ sean de pedicura
    final pedicureAppointments = appointments.where((a) {
      final isCompleted = a.status == "completed" || a.status == "approved";
      final isPedicure = pedicureIds.contains(a.designId) || pedicureTitles.contains(a.designTitle);
      return isCompleted && isPedicure;
    });

    return _buildRankingList("👣 Top Servicios Pedicura", pedicureAppointments);
  }

  // Helper para construir las listas de ranking
  Widget _buildRankingList(String title, Iterable<Appointment> filteredAppointments) {
    final Map<String, int> counts = {};
    for (var app in filteredAppointments) {
      counts[app.designTitle] = (counts[app.designTitle] ?? 0) + 1;
    }

    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    if (top5.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
        child: Text("Sin datos para $title", style: const TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(title, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: top5.length,
          itemBuilder: (context, index) {
            final entry = top5[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              elevation: 2,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: title.contains("Manicura") 
                      ? Colors.pinkAccent.withOpacity(0.2) 
                      : Colors.teal.withOpacity(0.2),
                  child: Text("#${index + 1}", 
                    style: TextStyle(
                      color: title.contains("Manicura") ? Colors.pinkAccent : Colors.teal, 
                      fontWeight: FontWeight.bold
                    )),
                ),
                title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("${entry.value} citas", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            );
          },
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // 📝 SECCIÓN 4: Lista de Gastos Recientes
  // ----------------------------------------------------
  Widget _buildRecentExpenses(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) return const SizedBox.shrink();
    final recent = expenses.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text("📉 Últimos Gastos", 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recent.length,
          itemBuilder: (context, index) {
            final e = recent[index];
            return ListTile(
              dense: true,
              leading: const Icon(Icons.receipt_long, color: Colors.red),
              title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('dd/MM/yyyy').format(e.date)),
              trailing: Text("-\$${e.amount.toStringAsFixed(2)}", 
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }

  // DIÁLOGO PARA AGREGAR GASTO
  void _showAddExpenseDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Registrar Nuevo Gasto"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: "Concepto (ej. Luz, Material)"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Monto (\$)", prefixText: "\$"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                await _expenseService.addExpense(titleCtrl.text, amount, DateTime.now());
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
            child: const Text("Guardar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
      title: const Text("Estadísticas"),
      actions: [
        // BOTÓN PARA IR AL REPORTE
        IconButton(
          icon: const Icon(Icons.receipt_long), // Icono de recibo/reporte
          tooltip: "Ver Reporte de Hoy",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Si no pasas fecha, usa 'hoy' por defecto
                builder: (context) => const IngresoReporte(), 
              ),
            );
          },
        )
      ],
    ),
      // Usamos StreamBuilder anidados para escuchar todas las colecciones necesarias
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentService.getAllAppointments(),
        builder: (context, snapshotApp) {
          return StreamBuilder<List<ExpenseModel>>(
            stream: _expenseService.getAllExpenses(),
            builder: (context, snapshotExp) {
              return StreamBuilder<List<PedicureServiceModel>>(
                stream: _pedicureService.getServices(),
                builder: (context, snapshotPed) {
                  
                  if (!snapshotApp.hasData || !snapshotExp.hasData || !snapshotPed.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
                  }

                  final appointments = snapshotApp.data!;
                  final expenses = snapshotExp.data!;
                  final pedicureServices = snapshotPed.data!;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildFinancialKPIs(appointments, expenses),
                        const Divider(),
                        _buildTopManicure(appointments, pedicureServices),
                        _buildTopPedicure(appointments, pedicureServices),
                        const Divider(),
                        _buildRecentExpenses(expenses),
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                }
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpenseDialog,
        backgroundColor: Colors.pinkAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Registrar Gasto", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// ----------------------------------------------------
// WIDGET AUXILIAR (SIN ERROR PARENT DATA)
// ----------------------------------------------------
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    // Devuelve un Container directo, el Expanded es responsabilidad del padre
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              CircleAvatar(radius: 3, backgroundColor: color),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}