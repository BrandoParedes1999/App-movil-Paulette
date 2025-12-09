import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 📦 IMPORTANTE: Asegúrate de tener url_launcher en pubspec.yaml
import '../models/user_model.dart';
import '../models/appointment.dart';
import '../services/user_service.dart';
import '../services/appointment_service.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // 👈 NUEVO IMPORT

class ClientesAdmin extends StatefulWidget {
  const ClientesAdmin({super.key});

  @override
  State<ClientesAdmin> createState() => _ClientesAdminState();
}

class _ClientesAdminState extends State<ClientesAdmin> {
  final UserService _userService = UserService();
  final AppointmentService _appointmentService = AppointmentService();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Directorio de Clientes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 Buscador Mejorado
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar nombre o teléfono...",
                prefixIcon: const Icon(Icons.search, color: Colors.pinkAccent),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // 📋 Lista de Clientes
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _userService.getAllClients(),
              builder: (context, snapshotUsers) {
                if (snapshotUsers.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  );
                }

                var clients = snapshotUsers.data ?? [];

                // 🔹 FILTRADO INTELIGENTE (Busca en nombre, telefono1 Y telefono2)
                if (_searchQuery.isNotEmpty) {
                  clients = clients
                      .where(
                        (u) =>
                            u.nombre.toLowerCase().contains(_searchQuery) ||
                            u.telefono.contains(_searchQuery) ||
                            u.telefono2.contains(
                              _searchQuery,
                            ), // <-- Ahora busca aquí también
                      )
                      .toList();
                }

                if (clients.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "No se encontraron clientes",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return _ClientCard(
                      client: client,
                      appointmentService: _appointmentService,
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
}

class _ClientCard extends StatelessWidget {
  final UserModel client;
  final AppointmentService appointmentService;

  const _ClientCard({required this.client, required this.appointmentService});

  // 🔹 LÓGICA WHATSAPP INTELIGENTE
  void _handleWhatsApp(BuildContext context) async {
    final phone1 = client.telefono.replaceAll(RegExp(r'[^0-9]'), '');
    final phone2 = client.telefono2.replaceAll(RegExp(r'[^0-9]'), '');

    // Caso 1: No tiene números
    if (phone1.isEmpty && phone2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Este cliente no tiene teléfono registrado"),
        ),
      );
      return;
    }

    // Caso 2: Solo tiene el 1
    if (phone1.isNotEmpty && phone2.isEmpty) {
      _launchUrl(phone1);
      return;
    }

    // Caso 3: Solo tiene el 2 (raro, pero posible)
    if (phone1.isEmpty && phone2.isNotEmpty) {
      _launchUrl(phone2);
      return;
    }

    // Caso 4: TIENE LOS DOS -> Preguntar al administrador
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
                  "Selecciona un número",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.green),
              title: Text("Principal: ${client.telefono}"),
              onTap: () {
                Navigator.pop(context);
                _launchUrl(phone1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.teal),
              title: Text("Respaldo: ${client.telefono2}"),
              onTap: () {
                Navigator.pop(context);
                _launchUrl(phone2);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Función auxiliar para abrir la URL
  Future<void> _launchUrl(String phone) async {
    // Ajusta el código de país si es necesario (ej. 52 para México)
    final url = Uri.parse("https://wa.me/+52$phone");
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se pudo abrir WhatsApp';
      }
    } catch (e) {
      print("Error lanzando WhatsApp: $e");
    }
  }

  // Mostrar detalle del cliente
  void _showClientDetails(BuildContext context, List<Appointment> history) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => _ClientDetailSheet(
          client: client,
          history: history,
          scrollController: controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: appointmentService.getAppointmentsByUser(client.id),
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        final completed = history
            .where((a) => a.status == "completed")
            .toList();
        final totalSpent = completed.fold(0.0, (sum, a) => sum + a.price);
        final lastVisit = completed.isNotEmpty ? completed.first.date : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 8,
            ),
            leading: CircleAvatar(
              backgroundColor: Colors.pinkAccent.withOpacity(0.1),
              radius: 25,
              child: Text(
                client.nombre.isNotEmpty ? client.nombre[0].toUpperCase() : "?",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
            ),
            title: Text(
              client.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // Mostrar ambos teléfonos si existen, o solo uno
                Text(
                  client.telefono2.isNotEmpty
                      ? "📱 ${client.telefono} / ${client.telefono2}"
                      : "📱 ${client.telefono}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 14,
                      color: Colors.green[700],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "\$${totalSpent.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.history, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text("${completed.length} citas"),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const FaIcon(
                FontAwesomeIcons.whatsapp,
                color: Colors.green,
                size: 30,
              ),
              onPressed: () => _handleWhatsApp(context),
            ),
            onTap: () => _showClientDetails(context, history),
          ),
        );
      },
    );
  }
}

class _ClientDetailSheet extends StatelessWidget {
  final UserModel client;
  final List<Appointment> history;
  final ScrollController scrollController;

  const _ClientDetailSheet({
    required this.client,
    required this.history,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(
                Icons.account_circle,
                size: 50,
                color: Colors.pinkAccent,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client.nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      client.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // TARJETA DE SALUD
          if (client.tieneDiabetes.toLowerCase() == 'sí' ||
              client.tieneAlergia.toLowerCase() == 'sí')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.medical_services, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Información Médica",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (client.tieneDiabetes.toLowerCase() == 'sí')
                    const Text(
                      "• Padece Diabetes",
                      style: TextStyle(color: Colors.red),
                    ),
                  if (client.tieneAlergia.toLowerCase() == 'sí')
                    const Text(
                      "• Tiene Alergias",
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),

          const Divider(height: 30),
          const Text(
            "Historial de Citas",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text("Este cliente aún no tiene citas."))
                : ListView.builder(
                    controller: scrollController,
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final appt = history[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          appt.status == 'completed'
                              ? Icons.check_circle
                              : (appt.status == 'cancelled'
                                    ? Icons.cancel
                                    : Icons.schedule),
                          color: appt.status == 'completed'
                              ? Colors.green
                              : (appt.status == 'cancelled'
                                    ? Colors.red
                                    : Colors.orange),
                        ),
                        title: Text(
                          appt.designTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy • hh:mm a').format(appt.date),
                        ),
                        trailing: Text(
                          "\$${appt.price.toStringAsFixed(0)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
