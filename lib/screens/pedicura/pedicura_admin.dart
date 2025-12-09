// Archivo: lib/screens/pedicura_admin.dart (TODO EL CÓDIGO)

import 'package:flutter/material.dart';
import 'package:paulette/models/design_model_pedicure.dart';
import 'package:paulette/screens/pedicura/add_pedicure_service.dart';
import 'package:paulette/screens/pedicura/edit_pedicura_service.dart';
import 'package:paulette/services/cloudinary_service.dart';
import 'package:paulette/services/pedicure_service.dart';

class PedicuraAdmin extends StatefulWidget {
  const PedicuraAdmin({super.key});

  @override
  State<PedicuraAdmin> createState() => _PedicuraAdminState();
}

class _PedicuraAdminState extends State<PedicuraAdmin> {
  final PedicureService _pedicureService = PedicureService();

  String searchQuery = "";
  String selectedCategory = "Todas";

  final List<String> categoryOptions = [
    "Todas",
    "Estético",
    "Spa/Relajación",
    "Clínico/Salud",
  ];

  // NUEVA FUNCIÓN: Alternar el estado activo
  Future<void> _toggleServiceStatus(
      String serviceId, bool currentStatus) async {
    try {
      await _pedicureService.toggleActiveStatus(
          serviceId, !currentStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus
                ? "Servicio Activado (Visible al cliente)"
                : "Servicio Desactivado (Oculto al cliente)",
          ),
          backgroundColor: !currentStatus ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cambiar estado: $e")),
      );
    }
  }

  // Lógica de eliminación (código existente)
  Future<void> _deleteService(
    BuildContext context,
    PedicureServiceModel service,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar servicio?"),
        content: const Text("Esta acción eliminará el servicio y su imagen."),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      if (service.publicId.isNotEmpty) {
        await CloudinaryService.deleteImage(service.publicId);
      }

      await _pedicureService.deleteService(service.id);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Servicio eliminado")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al eliminar: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 5,
        title: const Text(
          "Gestión de Pedicura",
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ---------------- BUSCADOR ----------------
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Buscar servicio...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          // ---------------- FILTROS (Categoría/Tipo de Cuidado) ----------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              children: [
                const Icon(Icons.category, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    items: categoryOptions.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategory = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ---------------- LISTA DE TARJETAS ----------------
          Expanded(
            child: StreamBuilder<List<PedicureServiceModel>>(
              stream: _pedicureService.getServices(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<PedicureServiceModel> services = snapshot.data!;

                // APLICAR FILTROS
                services = services.where((s) {
                  final titleMatch = s.title.toLowerCase().contains(
                        searchQuery,
                      );
                  final categoryMatch = selectedCategory == "Todas" ||
                      s.categories.any(
                        (cat) =>
                            cat.toLowerCase() == selectedCategory.toLowerCase(),
                      );
                  return titleMatch && categoryMatch;
                }).toList();

                if (services.isEmpty) {
                  return const Center(
                    child: Text("No hay servicios que coincidan."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen y Badge de Estatus (Activo/Inactivo)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Image.network(
                                  service.imageUrl,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 180,
                                      color: Colors.grey.shade300,
                                      child: const Icon(
                                        Icons.spa,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Badge de Estatus (ACTIVO/INACTIVO)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: service.isActive
                                        ? Colors.green
                                        : Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    service.isActive ? "ACTIVO" : "INACTIVO",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // DESCRIPCIÓN
                                if (service.description.isNotEmpty)
                                  Text(
                                    service.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.grey),
                                  ),
                                const SizedBox(height: 8),
                                // Categorías (Tipo de Cuidado)
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: service.categories.map((cat) {
                                    return Chip(
                                      label: Text(cat,
                                          style:
                                              const TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.purple.shade50,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 0),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 8),
                                // Precio y Duración
                                Text(
                                  "Duración: ${service.durationMinutes} minutos",
                                  style: const TextStyle(fontSize: 15),
                                ),
                                Text(
                                  "Precio: \$${service.price.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 12),
                                // ----------- BOTONES EDITAR Y ELIMINAR -----------
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextButton.icon(
                                        icon: const Icon(Icons.edit),
                                        label: const Text("Editar"),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EditPedicureServicePage(
                                                      service: service),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextButton.icon(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        label: const Text("Eliminar",
                                            style:
                                                TextStyle(color: Colors.red)),
                                        onPressed: () =>
                                            _deleteService(context, service),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 1),
                                // TOGGLE DE ACTIVIDAD
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Mostrar al Cliente",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: service.isActive
                                              ? Colors.green
                                              : Colors.red),
                                    ),
                                    Switch(
                                      value: service.isActive,
                                      onChanged: (newStatus) =>
                                          _toggleServiceStatus(
                                              service.id, service.isActive),
                                      activeColor: Colors.green,
                                      inactiveThumbColor: Colors.red,
                                    )
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // ---------------- FOOTER ----------------
      persistentFooterButtons: [
        Row(
          children: [
            _footerButton(Icons.menu, "Inicio", () => Navigator.pop(context)),
            const Spacer(),
            _footerButton(Icons.add, "Añadir", () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddPedicureServicePage(),
                ),
              );
            }),
            const Spacer(),
            _footerButton(Icons.settings, "Ajustes", () {}),
          ],
        ),
      ],
    );
  }

  // Widget para botones del footer
  Widget _footerButton(IconData icon, String label, Function onTap) {
    return InkWell(
      onTap: () => onTap(),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}