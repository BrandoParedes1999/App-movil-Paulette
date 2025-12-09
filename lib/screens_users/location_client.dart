import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart'; // Asumo que usas esto para el mapa
import 'package:latlong2/latlong.dart'; // Asumo que usas esto
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class UbicacionOsmScreen extends StatefulWidget {
  const UbicacionOsmScreen({super.key});

  @override
  State<UbicacionOsmScreen> createState() => _UbicacionOsmScreenState();
}

class _UbicacionOsmScreenState extends State<UbicacionOsmScreen> {
  // Coordenadas fijas del salón (Si quisieras dinámicas, también irían en settings)
  final LatLng _salonLocation = const LatLng(18.64481, -91.7897874); 

  // Función para abrir redes sociales
  Future<void> _launchSocial(String? link, String mode) async {
    if (link == null || link.isEmpty) return;
    
    final Uri url = Uri.parse(
      mode == 'wa' ? "https://wa.me/+52${link.replaceAll(RegExp(r'[^0-9]'), '')}" : link
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir el enlace")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ubicación y Contacto"), backgroundColor: Colors.pinkAccent, foregroundColor: Colors.white),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('settings').doc('general_info').snapshots(),
        builder: (context, snapshot) {
          // Datos por defecto si aún no carga
          String address = "Cargando dirección...";
          String phone = "";
          String fb = "";
          String insta = "";

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            address = data['address'] ?? "Dirección no configurada";
            phone = data['phone'] ?? "";
            fb = data['facebook'] ?? "";
            insta = data['instagram'] ?? "";
          }

          return Column(
            children: [
              // 🗺️ MAPA (Parte superior)
              Expanded(
                flex: 2,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: _salonLocation,
                    initialZoom: 15.0,
                  ),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _salonLocation,
                          width: 80,
                          height: 80,
                          child: const Icon(Icons.location_on, color: Colors.pinkAccent, size: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ℹ️ INFO CARD (Parte inferior dinámica)
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Visítanos", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.map, color: Colors.pinkAccent),
                          const SizedBox(width: 10),
                          Expanded(child: Text(address, style: const TextStyle(fontSize: 15, color: Colors.grey))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text("Síguenos", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _SocialButton(
                            icon: FontAwesomeIcons.whatsapp, 
                            color: Colors.green, 
                            onTap: () => _launchSocial(phone, 'wa')
                          ),
                          _SocialButton(
                            icon: FontAwesomeIcons.facebook, 
                            color: Colors.blue, 
                            onTap: () => _launchSocial(fb, 'url')
                          ),
                          _SocialButton(
                            icon: FontAwesomeIcons.instagram, 
                            color: Colors.purple, 
                            onTap: () => _launchSocial(insta, 'url')
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        radius: 25,
        backgroundColor: color.withOpacity(0.1),
        child: FaIcon(icon, color: color, size: 24),
      ),
    );
  }
}