import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:paulette/services/cloudinary_service.dart';

class AddPedicureServicePage extends StatefulWidget {
  const AddPedicureServicePage({super.key});

  @override
  State<AddPedicureServicePage> createState() =>
      _AddPedicureServicePageState();
}

class _AddPedicureServicePageState extends State<AddPedicureServicePage> {
  final nombreCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final precioCtrl = TextEditingController();
  final durationCtrl = TextEditingController();

  File? imageFile;
  bool isLoading = false;

  final List<String> categories = [
    "Estético",
    "Spa/Relajación",
    "Clínico/Salud",
    "Adicional",
  ];
  List<String> selectedCategories = [];

  // --- LÓGICA DE IMAGEN ---
  Future<void> pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (picked == null) return;

    final compressed = await _compress(File(picked.path));
    setState(() => imageFile = compressed);
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

  // --- LÓGICA DE GUARDADO ---
  Future<void> saveService() async {
    // 1. Validación de campos
    if (nombreCtrl.text.isEmpty ||
        descriptionCtrl.text.isEmpty ||
        selectedCategories.isEmpty ||
        precioCtrl.text.isEmpty ||
        durationCtrl.text.isEmpty ||
        imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Completa todos los campos y selecciona una imagen"),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // 2. Subir imagen a Cloudinary
      final uploadData = await CloudinaryService.uploadImageFull(imageFile!);

      // 3. Guardar datos en Firestore
      await FirebaseFirestore.instance.collection("pedicure_services").add({
        "nombre": nombreCtrl.text.trim(),
        "descripcion": descriptionCtrl.text.trim(),
        "duracion": int.parse(durationCtrl.text.trim()),
        "categories": selectedCategories,
        "precio": double.parse(precioCtrl.text.trim()),
        "imageUrl": uploadData["url"],
        "publicId": uploadData["public_id"],
        "isActive": true, // ESTABLECIDO POR DEFECTO COMO ACTIVO
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Servicio de Pedicura guardado correctamente"),
            backgroundColor: Colors.green),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.red),
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
        title: const Text("Agregar Servicio de Pedicura"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: ListView(
          children: [
            // 🖼️ IMAGEN DEL SERVICIO
            InkWell(
              onTap: pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: imageFile == null
                    ? const Center(
                        child: Text(
                          "Seleccionar imagen del servicio",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(imageFile!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // 📝 NOMBRE DEL SERVICIO
            TextField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: "Nombre del Servicio",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),

            // 📜 DESCRIPCIÓN DETALLADA
            TextField(
              controller: descriptionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Descripción detallada (ej. Incluye exfoliación, masaje de 15 min, etc.)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),


            // ⏱️ DURACIÓN (minutos)
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Duración (minutos)",
                helperText: "Tiempo estimado para este servicio (ej. 60)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // 🏷️ CATEGORÍAS (Tipo de Cuidado)
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
                        selectedColor: Colors.purple.shade100,
                        checkmarkColor: Colors.purple.shade700,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // 💰 PRECIO
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

            // ✅ BOTÓN GUARDAR
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : saveService,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Guardar Servicio de Pedicura",
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}