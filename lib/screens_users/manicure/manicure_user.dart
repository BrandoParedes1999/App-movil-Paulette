import 'package:flutter/material.dart';
import 'package:paulette/models/design_model.dart';
import 'package:paulette/services/design_service.dart';
import 'package:paulette/screens_users/manicure/agenda_cita.dart';

class ManicureUserScreen extends StatefulWidget {
  const ManicureUserScreen({super.key});

  @override
  State<ManicureUserScreen> createState() => _ManicureUserScreenState();
}

class _ManicureUserScreenState extends State<ManicureUserScreen> {
  final DesignService _designService = DesignService();
  
  String _searchQuery = "";
  String _selectedCategory = "Todas";

  final List<String> _categories = [
    "Todas", "Minimalista", "Acrílico", "3D", "Flores", "Natural", "Francesa"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // 1. APP BAR FLOTANTE
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.pinkAccent,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Diseños de Manicura", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.pinkAccent, Colors.pink.shade200],
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight
                  ),
                ),
              ),
            ),
          ),

          // 2. BUSCADOR Y FILTROS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Buscador con Sombra (SOLUCIÓN DEL ERROR)
                  Material(
                    elevation: 3,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Buscar diseño (ej. Rosas)...",
                        prefixIcon: const Icon(Icons.search, color: Colors.pinkAccent),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                        // elevation: 2,  <-- ESTO SE ELIMINÓ PORQUE DABA ERROR
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Filtros de Categoría (Horizontal)
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedCategory = cat);
                            },
                            selectedColor: Colors.pinkAccent,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : Colors.grey.shade300
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. GRILLA DE DISEÑOS
          StreamBuilder<List<DesignModel>>(
            stream: _designService.getDesigns(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.pinkAccent)));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("No hay diseños disponibles."))
                );
              }

              // FILTRADO (Solo activos + búsqueda + categoría)
              final designs = snapshot.data!.where((d) {
                final isActive = d.isActive;
                final matchesSearch = d.title.toLowerCase().contains(_searchQuery);
                final matchesCategory = _selectedCategory == "Todas" || d.categories.contains(_selectedCategory);
                
                return isActive && matchesSearch && matchesCategory;
              }).toList();

              if (designs.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text("No se encontraron resultados")));
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _DesignCard(design: designs[index]),
                    childCount: designs.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// 🎨 WIDGET DE TARJETA PROFESIONAL
class _DesignCard extends StatelessWidget {
  final DesignModel design;

  const _DesignCard({required this.design});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookAppointmentScreen(
              designId: design.id,
              designTitle: design.title,
              imageUrl: design.imageUrl,
              price: design.price,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        design.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          design.season,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            // INFO
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "\$${design.price.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.pinkAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}