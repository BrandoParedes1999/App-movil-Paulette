import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:paulette/models/appointment.dart';

// IMPORTS DE TUS PANTALLAS
import 'package:paulette/screens/citas_admin.dart';
import 'package:paulette/screens/estadistica_admin.dart';
import 'package:paulette/screens/settings_admin.dart';
import 'package:paulette/screens/clientes_admin.dart';
import 'package:paulette/screens/marketing_admin.dart';
import 'package:paulette/screens/pago_admin.dart';
import 'package:paulette/screens/register_admin.dart';
import 'package:paulette/screens/manicure/manicura_admin.dart';
import 'package:paulette/screens/pedicura/pedicura_admin.dart';
import 'package:paulette/screens/ingreso_reporte.dart';
import 'package:paulette/services/appointment_service.dart'; // O el que uses para reportes

class MenuAdmin extends StatefulWidget {
  const MenuAdmin({super.key});

  @override
  State<MenuAdmin> createState() => _MenuAdminState();
}

class _MenuAdminState extends State<MenuAdmin> {
  int _currentIndex = 0;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Títulos dinámicos según la pestaña
  final List<String> _titles = [
    "Agenda del Día",
    "Centro de Gestión", // El menú grid
    "Panel de Control", // Estadísticas
    "Configuración",
  ];

  @override
  Widget build(BuildContext context) {
    // Definimos las vistas aquí para poder pasar el contexto si es necesario
    final List<Widget> _views = [
      const AdminAppointmentsPanel(), // 0: Agenda (Lo más importante)
      const GestionGridScreen(), // 1: Grid de Gestión (Clientes, Servicios, etc.)
      const EstadisticaAdmin(), // 2: Estadísticas/Resumen
      const SettingsAdmin(), // 3: Ajustes
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50], // Fondo suave
      // APPBAR PERSONALIZADO
      appBar: AppBar(
        automaticallyImplyLeading: false, // Sin botón atrás
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            // Avatar pequeño o Logo
            CircleAvatar(
              backgroundColor: Colors.pinkAccent.withOpacity(0.1),
              child: const Icon(
                Icons.admin_panel_settings,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titles[_currentIndex],
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Carga asíncrona del nombre del admin
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      String nombre =
                          data['name']?.toString().split(' ')[0] ?? 'Admin';
                      return Text(
                        "Hola, $nombre",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Acceso rápido a Logout (aunque esté en settings, es bueno tenerlo)
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.grey),
            tooltip: 'Cerrar Sesión',
            onPressed: () => _confirmSignOut(context),
          ),
        ],
      ),

      // CUERPO (Mantiene el estado de las pestañas)
      body: IndexedStack(index: _currentIndex, children: _views),

      // BARRA DE NAVEGACIÓN INFERIOR
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) => setState(() => _currentIndex = index),
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.pinkAccent,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              items: [
                BottomNavigationBarItem(
                  icon: StreamBuilder<List<Appointment>>(
                    stream: AppointmentService().getAllAppointments(),
                    builder: (context, snapshot) {
                      // Contamos cuántas citas están en estado "pending"
                      final pendingCount =
                          snapshot.data
                              ?.where((a) => a.status == "pending")
                              .length ??
                          0;

                      return Badge(
                        label: Text('$pendingCount'),
                        isLabelVisible: pendingCount > 0,
                        child: const Icon(Icons.calendar_month_outlined),
                      );
                    },
                  ),
                  activeIcon: const Icon(Icons.calendar_month),
                  label: 'Agenda',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view), // Icono de menú
                  activeIcon: Icon(Icons.grid_view_rounded),
                  label: 'Gestión',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded),
                  activeIcon: Icon(Icons.bar_chart),
                  label: 'Reportes',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings_outlined),
                  activeIcon: Icon(Icons.settings),
                  label: 'Ajustes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Confirmación de salida elegante
  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cerrar Sesión"),
        content: const Text("¿Estás seguro de que quieres salir?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text("Salir", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// WIDGET INTERNO: GRID DE GESTIÓN (Para organizar todas tus pantallas)
// ---------------------------------------------------------------------------
class GestionGridScreen extends StatelessWidget {
  const GestionGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Servicios",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          _buildGrid([
            _MenuOption(
              title: "Manicura",
              icon: FontAwesomeIcons.handSparkles,
              color: Colors.purple.shade100,
              iconColor: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManicuraAdmin()),
              ),
            ),
            _MenuOption(
              title: "Pedicura",
              icon: FontAwesomeIcons.shoePrints,
              color: Colors.blue.shade100,
              iconColor: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PedicuraAdmin()),
              ),
            ),
          ]),

          const SizedBox(height: 20),
          const Text(
            "Operaciones",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          _buildGrid([
            _MenuOption(
              title: "Clientes",
              icon: Icons.people_alt_rounded,
              color: Colors.orange.shade100,
              iconColor: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ClientesAdmin()),
              ),
            ),
            _MenuOption(
              title: "Pagos",
              icon: Icons.attach_money_rounded,
              color: Colors.green.shade100,
              iconColor: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FormasPago()),
              ),
            ),
            _MenuOption(
              title: "Marketing",
              icon: Icons.campaign_rounded,
              color: Colors.red.shade100,
              iconColor: Colors.red,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MarketingAdmin()),
              ),
            ),
            _MenuOption(
              title: "Ingreso Manual",
              icon: Icons.post_add_rounded,
              color: Colors.teal.shade100,
              iconColor: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IngresoReporte()),
              ),
            ),
          ]),

          const SizedBox(height: 20),
          const Text(
            "Seguridad",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 10),

          _buildGrid([
            _MenuOption(
              title: "Nuevo Admin",
              icon: Icons.person_add_alt_1_rounded,
              color: Colors.grey.shade200,
              iconColor: Colors.black87,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RegisterAdminPage()),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildGrid(List<Widget> children) {
    return GridView.count(
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // El scroll lo maneja el padre
      crossAxisCount: 2, // 2 columnas
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio:
          1.5, // Proporción de las tarjetas (más anchas que altas)
      children: children,
    );
  }
}

// TARJETA DE MENÚ REUTILIZABLE
class _MenuOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: FaIcon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
