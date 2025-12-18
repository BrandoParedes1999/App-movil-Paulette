import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/appointment_service.dart';
import '../services/user_service.dart';
import '../widgets/appointment_card.dart';
import '../widgets/appointment_dialogs.dart';
import '../utils/appointment_utils.dart';
import '../models/appointment.dart';

class AdminAppointmentsPanel extends StatefulWidget {
  const AdminAppointmentsPanel({super.key});
  @override
  State<AdminAppointmentsPanel> createState() => _AdminAppointmentsPanelState();
}

class _AdminAppointmentsPanelState extends State<AdminAppointmentsPanel> with SingleTickerProviderStateMixin {
  final AppointmentService _service = AppointmentService();
  final UserService _userService = UserService();
  late TabController _tabController;
  
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  String _searchQuery = "";
  CalendarFormat _calendarFormat = CalendarFormat.week; 

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  void _showMsg(String text, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Agenda Paulette", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.block_flipped, color: Colors.grey),
            onPressed: () => AppointmentDialogs.showBlockTimeDialog(context, _service),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(), // Calendario con indicadores dinámicos
          _buildSearchBar(),
          _buildTabs(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: ["all", "pending", "approved", "completed"].map((s) => _buildList(s)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return StreamBuilder<List<Appointment>>(
      stream: _service.getAllAppointments(),
      builder: (context, snapshot) {
        final appointments = snapshot.data ?? [];
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: TableCalendar(
            locale: 'es_ES', // Asegúrate de inicializar intl para español
            firstDay: DateTime(2023),
            lastDay: DateTime(2030),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // Filtrar citas para este día específico
                final dayApps = appointments.where((a) => isSameDay(a.date, date)).toList();
                if (dayApps.isEmpty) return null;

                // Lógica de color según estado de urgencia/prioridad
                Color markerColor = Colors.grey;
                if (dayApps.any((a) => a.status == AppointmentStatus.pending)) {
                  markerColor = Colors.orange; // Hay pendientes
                } else if (dayApps.any((a) => a.status == AppointmentStatus.approved)) {
                  markerColor = Colors.blue; // Hay aprobadas (programadas)
                } else if (dayApps.every((a) => a.status == AppointmentStatus.completed)) {
                  markerColor = Colors.green; // Todo terminado
                }

                return Positioned(
                  bottom: 4,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
                  ),
                );
              },
            ),
            calendarStyle: const CalendarStyle(
              selectedDecoration: BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
              todayDecoration: BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle),
              markerMargin: EdgeInsets.symmetric(horizontal: 0.5),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: true, titleCentered: true),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Buscar cliente...",
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: Colors.pinkAccent,
      unselectedLabelColor: Colors.grey,
      indicatorColor: Colors.pinkAccent,
      tabs: const [
        Tab(text: "Todas"),
        Tab(text: "Pendientes"),
        Tab(text: "Aprobadas"),
        Tab(text: "Hechas"),
      ],
    );
  }

  Widget _buildList(String status) {
    return StreamBuilder<List<Appointment>>(
      stream: _service.getAllAppointments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        var list = snapshot.data ?? [];
        
        if (status != "all") list = list.where((a) => a.status == status).toList();
        list = list.where((a) => isSameDay(a.date, _selectedDate)).toList();

        if (_searchQuery.isNotEmpty) {
          list = list.where((a) => (a.userName ?? "").toLowerCase().contains(_searchQuery)).toList();
        }

        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note_outlined, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Sin actividad el ${DateFormat('dd/MM').format(_selectedDate)}", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final appt = list[i];
            return AppointmentCard(
              appointment: appt,
              userService: _userService,
              onApprove: () async {
                final res = await AppointmentDialogs.showApprovalDialog(context, appt.price, appt.description);
                if (res != null) {
                  final ok = await _service.updateStatusAndDetails(appt.id, AppointmentStatus.approved, res['price'], res['duration']);
                  _showMsg(ok ? "Cita aprobada" : "Error al aprobar", !ok);
                }
              },
              onReject: () async {
                final ok = await _service.updateStatus(appt.id, AppointmentStatus.cancelled);
                _showMsg(ok ? "Cita rechazada" : "Error", !ok);
              },
              onComplete: () async {
                final ok = await _service.updateStatus(appt.id, AppointmentStatus.completed);
                _showMsg(ok ? "Servicio finalizado" : "Error", !ok);
              },
              onUnblock: () => _service.deleteAppointment(appt.id),
            );
          },
        );
      },
    );
  }
}