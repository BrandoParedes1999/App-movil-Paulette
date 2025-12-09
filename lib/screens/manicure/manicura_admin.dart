import 'package:flutter/material.dart';
import 'package:paulette/screens/manicure/add.design_cloudinary.dart';
import 'package:paulette/screens/manicure/edit_design_page.dart';
import 'package:paulette/services/cloudinary_service.dart';
import '../../services/design_service.dart';
import '../../models/design_model.dart';

class ManicuraAdmin extends StatefulWidget {
  const ManicuraAdmin({super.key});

  @override
  State<ManicuraAdmin> createState() => _ManicuraAdminState();
}

class _ManicuraAdminState extends State<ManicuraAdmin> {
  final DesignService _designService = DesignService();

  String searchQuery = "";
  String selectedSeason = "Todas";
  String selectedCategory = "Todas";

  final List<String> seasonOptions = [
    "Todas",
    "Verano",
    "Invierno",
    "Otoño",
    "Primavera",
  ];

  final List<String> categoryOptions = [
    "Todas",
    "Flores",
    "Minimalista",
    "Acrílico",
    "3D",
    "Natural",
  ];

  Future<void> _toggleDesignStatus(String designId, bool currentStatus) async {
    try {
      await _designService.toggleActiveStatus(designId, !currentStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!currentStatus ? "Diseño visible" : "Diseño oculto"),
            backgroundColor: !currentStatus ? Colors.green : Colors.orange,
            duration: const Duration(milliseconds: 500),
          ),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _deleteDesign(DesignModel design) async {
    final confirmar = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar diseño?"),
        content: const Text("Esta acción no se puede deshacer."),
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
      if (design.publicId.isNotEmpty) {
        await CloudinaryService.deleteImage(design.publicId);
      }
      await _designService.deleteDesign(design.id);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Diseño eliminado")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Catálogo de Manicura",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: Colors.pinkAccent,
              size: 32,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddDesignCloudinaryPage(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. BUSCADOR Y FILTROS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: "Buscar...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) =>
                      setState(() => searchQuery = val.trim().toLowerCase()),
                ),
                const SizedBox(height: 10),
                // Filtros Horizontales (Chips)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        "Temporada",
                        seasonOptions,
                        selectedSeason,
                        (val) => selectedSeason = val,
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        "Categoría",
                        categoryOptions,
                        selectedCategory,
                        (val) => selectedCategory = val,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. GRILLA DE DISEÑOS
          Expanded(
            child: StreamBuilder<List<DesignModel>>(
              stream: _designService.getDesigns(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.pinkAccent),
                  );
                if (!snapshot.hasData || snapshot.data!.isEmpty)
                  return const Center(
                    child: Text("No hay diseños registrados"),
                  );

                var designs = snapshot.data!.where((d) {
                  final matchTitle = d.title.toLowerCase().contains(
                    searchQuery,
                  );
                  final matchSeason =
                      selectedSeason == "Todas" ||
                      d.season.toLowerCase() == selectedSeason.toLowerCase();
                  final matchCat =
                      selectedCategory == "Todas" ||
                      d.categories.any(
                        (c) =>
                            c.toLowerCase() == selectedCategory.toLowerCase(),
                      );
                  return matchTitle && matchSeason && matchCat;
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Columnas
                    childAspectRatio:
                        0.68, // Relación de aspecto (más alto que ancho)
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                  itemCount: designs.length,
                  itemBuilder: (context, index) => _AdminGridCard(
                    design: designs[index],
                    onToggle: () => _toggleDesignStatus(
                      designs[index].id,
                      designs[index].isActive,
                    ),
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditDesignPage(design: designs[index]),
                      ),
                    ),
                    onDelete: () => _deleteDesign(designs[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para los filtros tipo Chip
  Widget _buildFilterChip(
    String label,
    List<String> options,
    String currentVal,
    Function(String) onSelect,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.pinkAccent),
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          items: options
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) => setState(() => onSelect(val!)),
        ),
      ),
    );
  }
}

// 🎨 TARJETA DE DISEÑO (GRID)
class _AdminGridCard extends StatelessWidget {
  final DesignModel design;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminGridCard({
    required this.design,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. IMAGEN + MENÚ + BADGE
          Expanded(
            child: Stack(
              children: [
                // Imagen con Lógica condicional limpia
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: Builder(
                      builder: (context) {
                        // Definimos la imagen base
                        Widget imageWidget = Image.network(
                          design.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (c, child, p) => p == null
                              ? child
                              : Container(color: Colors.grey[200]),
                          errorBuilder: (c, e, s) => const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        );

                        // Si está activo, devolvemos la imagen normal (SIN ColorFiltered)
                        if (design.isActive) {
                          return imageWidget;
                        }

                        // Si está inactivo (oculto), aplicamos el filtro blanco y negro
                        return ColorFiltered(
                          colorFilter: const ColorFilter.matrix(<double>[
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                          child: imageWidget,
                        );
                      },
                    ),
                  ),
                ),

                // Menú de 3 puntos
                Positioned(
                  top: 5,
                  right: 5,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    radius: 14,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.black,
                      ),
                      onSelected: (val) =>
                          val == 'edit' ? onEdit() : onDelete(),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text("Editar"),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            "Eliminar",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Badge "OCULTO" (Solo si no está activo)
                if (!design.isActive)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        "OCULTO",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // 2. INFORMACIÓN
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  design.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "\$${design.price.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.pinkAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),

                // Switch de Visibilidad
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      design.isActive ? "Visible" : "Oculto",
                      style: TextStyle(
                        fontSize: 11,
                        color: design.isActive ? Colors.green : Colors.grey,
                      ),
                    ),
                    SizedBox(
                      height: 25,
                      width: 35,
                      child: Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: design.isActive,
                          onChanged: (_) => onToggle(),
                          activeColor: Colors.green,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}