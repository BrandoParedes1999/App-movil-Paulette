import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/appointment.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import '../utils/appointment_utils.dart';

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final UserService userService;
  final VoidCallback onApprove, onReject, onComplete, onUnblock;

  const AppointmentCard({
    super.key, 
    required this.appointment, 
    required this.userService, 
    required this.onApprove, 
    required this.onReject, 
    required this.onComplete, 
    required this.onUnblock
  });

  @override
  Widget build(BuildContext context) {
    if (appointment.status == AppointmentStatus.blocked) return _buildBlockedCard();

    // Nota: Para optimizar el N+1, idealmente el UserModel vendría denormalizado en la cita
    return FutureBuilder<UserModel?>(
      future: userService.getUserById(appointment.userId),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(8),
            leading: _buildLeadingImage(),
            title: Text(
              user?.nombre ?? appointment.userName ?? "Cliente",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("${appointment.time} - ${appointment.designTitle}"),
            trailing: _StatusBadge(status: appointment.status),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    if (appointment.description != null)
                      Text("📝 ${appointment.description}", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 10),
                    _buildActionButtons(user),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeadingImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: CachedNetworkImage(
        imageUrl: appointment.imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: Colors.grey[200]),
        errorWidget: (context, url, error) => const Icon(Icons.broken_image),
      ),
    );
  }

  Widget _buildActionButtons(UserModel? user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        if (user != null)
          _CircleAction(
            icon: FontAwesomeIcons.whatsapp, 
            color: Colors.green, 
            onTap: () => _launchWA(user)
          ),
        if (appointment.status == AppointmentStatus.pending) ...[
          _CircleAction(icon: Icons.close, color: Colors.red, onTap: onReject),
          _CircleAction(icon: Icons.check, color: Colors.blue, onTap: onApprove),
        ],
        if (appointment.status == AppointmentStatus.approved)
          _CircleAction(icon: Icons.done_all, color: Colors.green, onTap: onComplete),
      ],
    );
  }

  void _launchWA(UserModel user) async {
    final phone = user.telefono.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse("https://wa.me/+52$phone?text=Hola ${user.nombre}, de Paulette Salón...");
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Widget _buildBlockedCard() {
    return ListTile(
      tileColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: const Icon(Icons.block, color: Colors.red),
      title: Text("Bloqueo: ${appointment.designTitle}"),
      subtitle: Text(appointment.time),
      trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: onUnblock),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _CircleAction({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        // ignore: deprecated_member_use
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppointmentUtils.getStatusColor(status), borderRadius: BorderRadius.circular(8)),
      child: Text(
        AppointmentUtils.getStatusText(status), 
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
      ),
    );
  }
}