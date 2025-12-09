import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../models/design_model.dart';
import '../../services/cloudinary_service.dart';
import '../../services/design_service.dart';

class EditDesignPage extends StatefulWidget {
  final DesignModel design;

  const EditDesignPage({super.key, required this.design});

  @override
  State<EditDesignPage> createState() => _EditDesignPageState();
}

class _EditDesignPageState extends State<EditDesignPage> {
  final nombreCtrl = TextEditingController();
  final precioCtrl = TextEditingController();

  File? newImageFile;
  bool isLoading = false;

  final _service = DesignService();

  // Lista de categorías disponibles
  final List<String> categories = [
    "Todas",
    "Flores",
    "Minimalista",
    "Acrílico",
    "3D",
    "Natural",
  ];

  // 👇 Categorías seleccionadas (inicializada con las del diseño)
  List<String> selectedCategories = [];

  final List<String> seasons = [
    "Primavera",
    "Verano",
    "Otoño",
    "Invierno",
    "Todo el año",
  ];

  String? selectedSeason;

  @override
  void initState() {
    super.initState();
    nombreCtrl.text = widget.design.title;
    selectedSeason = widget.design.season;
    precioCtrl.text = widget.design.price.toString();
    
    // 👇 Inicializar las categorías con las que ya tiene el diseño
    selectedCategories = List<String>.from(widget.design.categories);
  }

  Future<void> pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked == null) return;

    final compressed = await _compress(File(picked.path));
    setState(() => newImageFile = compressed);
  }

  Future<File> _compress(File file) async {
    final targetPath =
        '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 75,
    );

    if (result == null) return file;
    return File(result.path);
  }

  Future<void> updateDesign() async {
    // 👇 Validación actualizada con categorías
    if (nombreCtrl.text.isEmpty ||
        selectedSeason == null ||
        selectedCategories.isEmpty ||
        precioCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String imageUrl = widget.design.imageUrl;
      String publicId = widget.design.publicId;

      if (newImageFile != null) {
        // 1. Subir nueva foto
        final uploadData = await CloudinaryService.uploadImageFull(
          newImageFile!,
        );

        // 2. Eliminar la vieja
        if (publicId.isNotEmpty) {
          await CloudinaryService.deleteImage(publicId);
        }

        // 3. Asignar nuevos valores
        imageUrl = uploadData["url"];
        publicId = uploadData["public_id"];
      }

      // 👇 Actualizar con las múltiples categorías
      await _service.updateDesign(widget.design.id, {
        "nombre": nombreCtrl.text.trim(),
        "temporada": selectedSeason,
        "categories": selectedCategories, // 👈 Lista de categorías
        "precio": double.parse(precioCtrl.text.trim()),
        "imageUrl": imageUrl,
        "publicId": publicId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Diseño actualizado correctamente")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    precioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar diseño"),
        centerTitle: true,
      ),

      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // ----------- IMAGEN -----------
          InkWell(
            onTap: pickImage,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: newImageFile != null
                    ? Image.file(newImageFile!, fit: BoxFit.cover)
                    : Image.network(widget.design.imageUrl, fit: BoxFit.cover),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ----------- NOMBRE -----------
          TextField(
            controller: nombreCtrl,
            decoration: InputDecoration(
              labelText: "Nombre del diseño",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ----------- CATEGORÍAS (MULTISELECCIÓN) -----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade500),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Categorías",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((category) {
                    final isSelected = selectedCategories.contains(category);
                    return FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedCategories.add(category);
                          } else {
                            selectedCategories.remove(category);
                          }
                        });
                      },
                      selectedColor: Colors.pink.shade100,
                      checkmarkColor: Colors.pink.shade700,
                    );
                  }).toList(),
                ),
                if (selectedCategories.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Seleccionadas: ${selectedCategories.join(', ')}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // ----------- TEMPORADA -----------
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade500),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<String>(
              value: selectedSeason,
              hint: const Text("Selecciona la temporada"),
              isExpanded: true,
              underline: const SizedBox(),
              items: seasons.map((season) {
                return DropdownMenuItem(value: season, child: Text(season));
              }).toList(),
              onChanged: (value) {
                setState(() => selectedSeason = value);
              },
            ),
          ),

          const SizedBox(height: 15),

          // ----------- PRECIO -----------
          TextField(
            controller: precioCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Precio",
              prefixText: "\$ ",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // ----------- BOTÓN GUARDAR -----------
          ElevatedButton(
            onPressed: isLoading ? null : updateDesign,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "Guardar cambios",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),

          const SizedBox(height: 10),

          // ----------- INFORMACIÓN ACTUAL -----------
          if (!isLoading)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Información actual:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text("Nombre: ${widget.design.title}"),
                    Text("Temporada: ${widget.design.season}"),
                    Text("Categorías: ${widget.design.categories.join(', ')}"),
                    Text("Precio: \$${widget.design.price.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}