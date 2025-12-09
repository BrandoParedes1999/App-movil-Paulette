import 'package:flutter/material.dart';
import 'package:paulette/screens/pago_admin.dart';
import 'package:paulette/screens_users/mis_citas.dart';
import 'package:paulette/services/servicio_mapa.dart';

class FooterMenuClient extends StatelessWidget {
  const FooterMenuClient({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyAppointmentsScreen(),
              ),
            );
          },
        ),

        

        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UbicacionOsmScreen()),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map),
                Text("Ubicación", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),

        const Spacer(),

        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FormasPago()),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.payment),
                Text("Formas de Pago", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),

        const Spacer(),

        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.manage_accounts_rounded),
                Text("Ajustes", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
