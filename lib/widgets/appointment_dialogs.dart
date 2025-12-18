import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/appointment_service.dart';

class AppointmentDialogs {
  // Diálogo para bloquear horario
  static void showBlockTimeDialog(BuildContext context, AppointmentService service) {
    final dateCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    DateTime? selectedDate;
    String? startTime, endTime;
    bool isFullDay = false;
    final List<String> adminTimeSlots = AppointmentService.timeSlots;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Bloquear Agenda"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: "Motivo")),
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: const InputDecoration(labelText: "Fecha", prefixIcon: Icon(Icons.calendar_month)),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (date != null) setDialogState(() { selectedDate = date; dateCtrl.text = DateFormat('dd/MM/yyyy').format(date); });
                  },
                ),
                SwitchListTile(
                  title: const Text("Todo el día"),
                  value: isFullDay,
                  onChanged: (val) => setDialogState(() => isFullDay = val),
                ),
                if (!isFullDay) Row(
                  children: [
                    Expanded(child: DropdownButtonFormField<String>(hint: const Text("Inicio"), items: adminTimeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => startTime = v)),
                    const SizedBox(width: 10),
                    Expanded(child: DropdownButtonFormField<String>(hint: const Text("Fin"), items: adminTimeSlots.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => endTime = v)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                if (selectedDate != null && reasonCtrl.text.isNotEmpty) {
                  await service.blockTimeSlots(date: selectedDate!, reason: reasonCtrl.text, blockFullDay: isFullDay, startTime: startTime, endTime: endTime);
                  Navigator.pop(context);
                }
              },
              child: const Text("Bloquear"),
            ),
          ],
        ),
      ),
    );
  }

  // Diálogo para ajustar precio/duración al aprobar
  static Future<Map<String, dynamic>?> showApprovalDialog(BuildContext context, double originalPrice, String? notes) async {
    final priceCtrl = TextEditingController(text: originalPrice.toStringAsFixed(2));
    final durationCtrl = TextEditingController(text: '60');

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Aprobar y Ajustar"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Notas: ${notes ?? 'Sin notas'}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            TextField(controller: durationCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Duración (min)")),
            TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Precio Final (\$)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {'price': double.tryParse(priceCtrl.text), 'duration': int.tryParse(durationCtrl.text)}),
            child: const Text("Aprobar"),
          ),
        ],
      ),
    );
  }
}