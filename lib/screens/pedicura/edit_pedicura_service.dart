import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:paulette/models/design_model_pedicure.dart';
import 'package:paulette/services/cloudinary_service.dart';
import 'package:paulette/services/pedicure_service.dart';

class EditPedicureServicePage extends StatefulWidget {
  final PedicureServiceModel service;

  const EditPedicureServicePage({super.key, required this.service});

  @override
  State<EditPedicureServicePage> createState() =>
      _EditPedicureServicePageState();
}

class _EditPedicureServicePageState extends State<EditPedicureServicePage> {
  // Controladores inicializados con los datos del servicio
  final nombreCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController(); // NUEVO: Descripción
  final precioCtrl = TextEditingController();
  final durationCtrl = TextEditingController();

  File? newImageFile; // Archivo de imagen nuevo si se selecciona
  bool isLoading = false;

  final PedicureService _service = PedicureService();

  // Categorías disponibles
  final List<String> allCategories = [
    "Estético",
    "Spa/Relajación",
    "Clínico/Salud",
    "Adicional",
  ];

  // Categorías seleccionadas (inicializada con las del servicio)
  List<String> selectedCategories = [];

  @override
  void initState() {
    super.initState();
    // Precargar todos los datos del modelo al iniciar la vista
    nombreCtrl.text = widget.service.title;
    descriptionCtrl.text = widget.service.description; // Precarga Descripción
    precioCtrl.text = widget.service.price.toString();
    durationCtrl.text = widget.service.durationMinutes.toString();
    selectedCategories = List<String>.from(widget.service.categories);
  }

  // --- LÓGICA DE IMAGEN ---
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

  // --- LÓGICA DE ACTUALIZACIÓN ---
  Future<void> updateService() async {
    // 1. Validación de campos
    if (nombreCtrl.text.isEmpty ||
        descriptionCtrl.text.isEmpty ||
        selectedCategories.isEmpty ||
        precioCtrl.text.isEmpty ||
        durationCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Completa todos los campos"),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String imageUrl = widget.service.imageUrl;
      String publicId = widget.service.publicId;

      // 2. Gestionar la nueva imagen si fue seleccionada
      if (newImageFile != null) {
        // Subir nueva foto (sin especificar carpeta por ahora)
        final uploadData = await CloudinaryService.uploadImageFull(newImageFile!);

        // Eliminar la vieja (si existe)
        if (publicId.isNotEmpty) {
          await CloudinaryService.deleteImage(publicId);
        }

        // Asignar nuevos valores
        imageUrl = uploadData["url"];
        publicId = uploadData["public_id"];
      }

      // 3. Actualizar el servicio en Firestore (manteniendo el estado isActive)
      await _service.updateService(widget.service.id, {
        "nombre": nombreCtrl.text.trim(),
        "descripcion": descriptionCtrl.text.trim(), // <<-- GUARDANDO DESCRIPCIÓN
        "duracion": int.parse(durationCtrl.text.trim()),
        "categories": selectedCategories,
        "precio": double.parse(precioCtrl.text.trim()),
        "imageUrl": imageUrl,
        "publicId": publicId,
        "isActive": widget.service.isActive, // Mantiene el estado de actividad original
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Servicio actualizado correctamente"),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    descriptionCtrl.dispose();
    precioCtrl.dispose();
    durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Servicio de Pedicura"),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(15),
        children: [
          // ----------- IMAGEN (Preview o Placeholder) -----------
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
                    : Image.network(
                        widget.service.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                                child: Text("Error al cargar imagen actual")),
                          );
                        },
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ----------- NOMBRE -----------
          TextField(
            controller: nombreCtrl,
            decoration: InputDecoration(
              labelText: "Nombre del servicio",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // ----------- DESCRIPCIÓN -----------
          TextField(
            controller: descriptionCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: "Descripción detallada",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // ----------- DURACIÓN (minutos) -----------
          TextField(
            controller: durationCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Duración (minutos)",
              helperText: "Tiempo estimado para este servicio",
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
                  "Tipo de Cuidado/Categorías",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allCategories.map((category) {
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
                      selectedColor: Colors.purple.shade100,
                      checkmarkColor: Colors.purple.shade700,
                    );
                  }).toList(),
                ),
              ],
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
            onPressed: isLoading ? null : updateService,
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
        ],
      ),
    );
  }
}