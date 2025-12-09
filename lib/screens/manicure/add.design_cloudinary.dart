import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/cloudinary_service.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class AddDesignCloudinaryPage extends StatefulWidget {
  const AddDesignCloudinaryPage({super.key});

  @override
  State<AddDesignCloudinaryPage> createState() => _AddDesignCloudinaryPageState();
}

class _AddDesignCloudinaryPageState extends State<AddDesignCloudinaryPage> {
  // Clave para el formulario (Validación visual)
  final _formKey = GlobalKey<FormState>();
  
  final nombreCtrl = TextEditingController();
  final precioCtrl = TextEditingController();

  File? imageFile;
  bool isLoading = false;
  bool isActive = true; // 👈 NUEVO: Control de visibilidad inicial

  // ⚠️ CORRECCIÓN: Eliminada la opción "Todas" (no es una categoría real)
  final List<String> categories = [
    "Flores",
    "Minimalista",
    "Acrílico",
    "3D",
    "Natural",
    "Francesa",
    "Elegante"
  ];

  List<String> selectedCategories = [];

  final List<String> seasons = [
    "Primavera", "Verano", "Otoño", "Invierno", "Todo el año"
  ];

  String? selectedSeason;

  // --- LÓGICA DE IMAGEN ---
  Future<void> pickImage() async {
    final XFile? picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final compressed = await _compress(File(picked.path));
    setState(() => imageFile = compressed);
  }

  Future<File> _compress(File file) async {
    final targetPath = '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path, targetPath, quality: 75,
    );
    return result != null ? File(result.path) : file;
  }

  // --- LÓGICA DE GUARDADO ---
  Future<void> saveDesign() async {
    // 1. Validar formulario visualmente
    if (!_formKey.currentState!.validate()) return;

    // 2. Validaciones extra
    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Falta la imagen")));
      return;
    }
    if (selectedSeason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona una temporada")));
      return;
    }
    if (selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Selecciona al menos una categoría")));
      return;
    }

    setState(() => isLoading = true);

    try {
      // 3. Subir a Cloudinary
      // (Opcional: Puedes agregar folderName: 'manicura_designs' si actualizaste el servicio)
      final uploadData = await CloudinaryService.uploadImageFull(imageFile!);

      // 4. Guardar en Firestore
      await FirebaseFirestore.instance.collection("manicure_designs").add({
        "nombre": nombreCtrl.text.trim(),
        "temporada": selectedSeason,
        "categories": selectedCategories,
        "precio": double.parse(precioCtrl.text.trim()),
        "imageUrl": uploadData["url"],
        "publicId": uploadData["public_id"],
        "isActive": isActive, // 👈 IMPORTANTE: Guardar el estado
        "createdAt": FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Diseño guardado correctamente"), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
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
      appBar: AppBar(title: const Text("Nuevo Diseño"), centerTitle: true),
      body: Form(
        key: _formKey, // Vinculamos el formulario
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 🖼️ SELECCIONAR IMAGEN
            GestureDetector(
              onTap: pickImage,
              child: AspectRatio(
                aspectRatio: 1.3, // Formato rectangular estándar
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade400),
                    image: imageFile != null 
                      ? DecorationImage(image: FileImage(imageFile!), fit: BoxFit.cover)
                      : null
                  ),
                  child: imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                            SizedBox(height: 10),
                            Text("Toca para subir foto", style: TextStyle(color: Colors.grey))
                          ],
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📝 NOMBRE
            TextFormField(
              controller: nombreCtrl,
              decoration: InputDecoration(
                labelText: "Nombre del diseño",
                prefixIcon: const Icon(Icons.brush),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) => val!.isEmpty ? "Escribe un nombre" : null,
            ),
            const SizedBox(height: 15),

            // 🏷️ CATEGORÍAS
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Categorías (Selecciona varias)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selected ? selectedCategories.add(cat) : selectedCategories.remove(cat);
                          });
                        },
                        selectedColor: Colors.pinkAccent.withOpacity(0.2),
                        checkmarkColor: Colors.pinkAccent,
                        labelStyle: TextStyle(color: isSelected ? Colors.pinkAccent : Colors.black87),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // 🍂 TEMPORADA
            DropdownButtonFormField<String>(
              value: selectedSeason,
              decoration: InputDecoration(
                labelText: "Temporada",
                prefixIcon: const Icon(Icons.calendar_month),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              items: seasons.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) => setState(() => selectedSeason = val),
              validator: (val) => val == null ? "Selecciona una temporada" : null,
            ),
            const SizedBox(height: 15),

            // 💰 PRECIO
            TextFormField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Precio",
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              validator: (val) => val!.isEmpty ? "Ingresa el precio" : null,
            ),
            const SizedBox(height: 15),

            // 👁️ VISIBILIDAD (Opcional)
            SwitchListTile(
              title: const Text("Visible al público"),
              subtitle: const Text("Si lo desactivas, se guardará como borrador."),
              value: isActive,
              activeColor: Colors.green,
              onChanged: (val) => setState(() => isActive = val),
            ),

            const SizedBox(height: 30),

            // 💾 BOTÓN GUARDAR
            SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : saveDesign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: isLoading ? const SizedBox.shrink() : const Icon(Icons.save),
                label: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Guardar Diseño", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}