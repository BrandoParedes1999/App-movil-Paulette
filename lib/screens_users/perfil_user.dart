import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:paulette/models/user_model.dart'; // Asegúrate de importar tu modelo

class PerfilUserScreen extends StatefulWidget {
  const PerfilUserScreen({super.key});

  @override
  State<PerfilUserScreen> createState() => _PerfilUserScreenState();
}

class _PerfilUserScreenState extends State<PerfilUserScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  // Variables para condiciones médicas (Clave para tu Admin)
  bool _hasDiabetes = false;
  bool _hasAllergies = false;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      _nameCtrl.text = data['nombre'] ?? '';
      _phoneCtrl.text = data['telefono'] ?? '';
      
      setState(() {
        // Convertimos el String "sí"/"no" a booleano para los Switchs
        _hasDiabetes = (data['tieneDiabetes'] ?? '').toString().toLowerCase() == 'sí';
        _hasAllergies = (data['tieneAlergia'] ?? '').toString().toLowerCase() == 'sí';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (currentUser == null) return;
    
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'nombre': _nameCtrl.text.trim(),
        'telefono': _phoneCtrl.text.trim(),
        // Guardamos como "sí"/"no" para compatibilidad con tu modelo actual
        'tieneDiabetes': _hasDiabetes ? 'sí' : 'no',
        'tieneAlergia': _hasAllergies ? 'sí' : 'no',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Perfil actualizado correctamente"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Volver al menú
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Mi Perfil", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // AVATAR
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.pinkAccent.withOpacity(0.1),
                    child: Text(
                      currentUser?.email?.substring(0, 1).toUpperCase() ?? "U",
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                    ),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: const Icon(Icons.edit, size: 18, color: Colors.black),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            const Text("Información Personal", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 10),
            _buildTextField("Nombre Completo", _nameCtrl, Icons.person),
            const SizedBox(height: 15),
            _buildTextField("Teléfono (WhatsApp)", _phoneCtrl, Icons.phone, isPhone: true),

            const SizedBox(height: 30),
            const Text("Información de Salud (Importante)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 5),
            const Text(
              "Ayúdanos a cuidarte. Activa estas opciones si aplican para ti.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            
            // SWITCHES DE SALUD
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text("Tengo Diabetes", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("Requiere instrumental y cuidado especial en pedicura."),
                    secondary: const Icon(Icons.medical_services, color: Colors.redAccent),
                    activeColor: Colors.redAccent,
                    value: _hasDiabetes,
                    onChanged: (val) => setState(() => _hasDiabetes = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text("Tengo Alergias", style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text("A látex, acrílico, acetona, etc."),
                    secondary: const Icon(Icons.warning_amber, color: Colors.orange),
                    activeColor: Colors.orange,
                    value: _hasAllergies,
                    onChanged: (val) => setState(() => _hasAllergies = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
            
            // BOTÓN GUARDAR
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Guardar Cambios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {bool isPhone = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.pinkAccent),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}