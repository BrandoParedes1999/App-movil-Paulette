import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para copiar al portapapeles
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PaymentClientScreen extends StatelessWidget {
  const PaymentClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Métodos de Pago", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 📡 ESCUCHANDO LOS CAMBIOS DEL ADMIN EN TIEMPO REAL
        stream: FirebaseFirestore.instance.collection('settings').doc('payment_info').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.pinkAccent));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Información de pago no disponible temporalmente."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. Tarjeta de Efectivo
                _buildPaymentOption(
                  icon: Icons.money,
                  color: Colors.green,
                  title: "Pago en Efectivo",
                  description: "Paga directamente en el salón al finalizar tu servicio.",
                ),
                
                const SizedBox(height: 20),

                // 2. Tarjeta de Transferencia (DATOS DINÁMICOS)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                    border: Border.all(color: Colors.pinkAccent.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.pinkAccent.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.account_balance, color: Colors.pinkAccent),
                          ),
                          const SizedBox(width: 15),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Transferencia Bancaria", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Text("Depósito previo o al momento", style: TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),
                      
                      // DATOS DESDE FIREBASE
                      _buildDetailRow("Banco", data['banco'] ?? 'No especificado'),
                      _buildDetailRow("Titular", data['titular'] ?? ''),
                      _buildCopyRow(context, "Cuenta/CLABE", data['clabe'] ?? ''),
                      const SizedBox(height: 15),
                      
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            const Icon(FontAwesomeIcons.whatsapp, color: Colors.orange, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text("Enviar comprobante al: ${data['telefono']}", style: TextStyle(fontSize: 12, color: Colors.orange.shade800))),
                          ],
                        ),
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

  Widget _buildPaymentOption({required IconData icon, required Color color, required String title, required String description}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  // Permite copiar la CLABE al tocar
  Widget _buildCopyRow(BuildContext context, String label, String value) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copiado al portapapeles"), duration: Duration(seconds: 1)));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
            Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.blue))),
            const Icon(Icons.copy, size: 14, color: Colors.blue),
          ],
        ),
      ),
    );
  }
}