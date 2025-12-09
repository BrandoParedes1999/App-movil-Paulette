import 'package:flutter/material.dart';
import 'package:paulette/models/design_model_pedicure.dart';
import 'package:paulette/services/pedicure_service.dart';
import 'package:paulette/screens_users/manicure/agenda_cita.dart';

class PedicureUserScreen extends StatefulWidget {
  const PedicureUserScreen({super.key});

  @override
  State<PedicureUserScreen> createState() => _PedicureUserScreenState();
}

class _PedicureUserScreenState extends State<PedicureUserScreen> {
  final PedicureService _pedicureService = PedicureService();
  
  String _searchQuery = "";
  String _selectedCategory = "Todas";

  final List<String> _categories = [
    "Todas", "Estético", "Spa/Relajación", "Clínico/Salud"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Servicios de Pedicura", 
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal, Colors.teal.shade200],
                    begin: Alignment.topLeft, 
                    end: Alignment.bottomRight
                  ),
                ),
                child: const Stack(
                  children: [
                    Positioned(
                        right: -20, bottom: -20,
                        child: Icon(Icons.spa, size: 150, color: Colors.white10)
                    )
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    elevation: 3,
                    shadowColor: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: "Buscar tratamiento...",
                        prefixIcon: const Icon(Icons.search, color: Colors.teal),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
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
                            onSelected: (selected) => setState(() => _selectedCategory = cat),
                            selectedColor: Colors.teal,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            ),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<List<PedicureServiceModel>>(
            stream: _pedicureService.getServices(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.teal)));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text("No hay servicios disponibles.")));
              }

              final services = snapshot.data!.where((s) {
                final isActive = s.isActive;
                final matchesSearch = s.title.toLowerCase().contains(_searchQuery);
                final matchesCategory = _selectedCategory == "Todas" || s.categories.contains(_selectedCategory);
                return isActive && matchesSearch && matchesCategory;
              }).toList();

              if (services.isEmpty) {
                return const SliverFillRemaining(child: Center(child: Text("No se encontraron servicios")));
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _PedicureCard(service: services[index]),
                  childCount: services.length,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PedicureCard extends StatelessWidget {
  final PedicureServiceModel service;

  const _PedicureCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookAppointmentScreen(
                designId: service.id,
                designTitle: service.title,
                imageUrl: service.imageUrl,
                price: service.price,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(15)),
              child: Image.network(
                service.imageUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => Container(width: 110, height: 110, color: Colors.grey[200], child: const Icon(Icons.spa, color: Colors.grey)),
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text(
                      service.description.isNotEmpty ? service.description : "Servicio profesional de cuidado de pies.",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 14, color: Colors.teal),
                            const SizedBox(width: 4),
                            Text("${service.durationMinutes} min", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                          ],
                        ),
                        Text("\$${service.price.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}