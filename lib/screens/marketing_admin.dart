import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/promo_model.dart';

class MarketingAdmin extends StatefulWidget {
  const MarketingAdmin({super.key});

  @override
  State<MarketingAdmin> createState() => _MarketingAdminState();
}

class _MarketingAdminState extends State<MarketingAdmin> {
  final CollectionReference _promosRef =
      FirebaseFirestore.instance.collection('promotions');

  // CREAR NUEVA PROMO
  void _showAddPromoDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Nueva Promoción"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Título (ej. 2x1 Jueves)",
                      prefixIcon: Icon(Icons.campaign, color: Colors.purple),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: "Descripción",
                      hintText: "Condiciones de la promo...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Descuento %",
                            suffixText: "%",
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() => selectedDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(labelText: "Vence"),
                            child: Text(
                              selectedDate == null
                                  ? "Elegir fecha"
                                  : DateFormat('dd/MM').format(selectedDate!),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () async {
                  if (titleCtrl.text.isNotEmpty && selectedDate != null) {
                    await _promosRef.add({
                      'title': titleCtrl.text.trim(),
                      'description': descCtrl.text.trim(),
                      'discount': double.tryParse(discountCtrl.text) ?? 0.0,
                      'validUntil': Timestamp.fromDate(selectedDate!),
                      'isActive': true,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text("PUBLICAR", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // BORRAR PROMO
  void _deletePromo(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Borrar Promoción?"),
        content: const Text("Dejará de aparecer en la app de los clientes."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await _promosRef.doc(id).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Borrar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Marketing & Promos", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _promosRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final promos = snapshot.data!.docs
              .map((doc) => PromoModel.fromDoc(doc))
              .toList();

          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 10),
                  const Text("No hay promociones activas", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              final isExpired = promo.validUntil.isBefore(DateTime.now());

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: isExpired ? Colors.grey : Colors.purple.shade50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer, color: isExpired ? Colors.white : Colors.purple),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              promo.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isExpired ? Colors.white : Colors.black87,
                                decoration: isExpired ? TextDecoration.lineThrough : null,
                              ),
                            ),
                          ),
                          if (isExpired)
                            const Chip(label: Text("VENCIDA"), backgroundColor: Colors.white)
                          else
                            Chip(
                              label: Text("-${promo.discount.toStringAsFixed(0)}%"),
                              backgroundColor: Colors.purple,
                              labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(promo.description, style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Válido hasta: ${DateFormat('dd MMM yyyy').format(promo.validUntil)}",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _deletePromo(promo.id),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddPromoDialog,
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Crear Promo", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}