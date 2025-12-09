import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'register_admin.dart'; // Importamos la nueva pantalla

class SettingsAdmin extends StatefulWidget {
  const SettingsAdmin({super.key});

  @override
  State<SettingsAdmin> createState() => _SettingsAdminState();
}

class _SettingsAdminState extends State<SettingsAdmin> {
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();

  bool _isLoading = true;
  final _settingsRef = FirebaseFirestore.instance.collection('settings').doc('general_info');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await _settingsRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _phoneCtrl.text = data['phone'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _instagramCtrl.text = data['instagram'] ?? '';
        _facebookCtrl.text = data['facebook'] ?? '';
      }
    } catch (e) {
      print("Error cargando ajustes: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _settingsRef.set({
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'instagram': _instagramCtrl.text.trim(),
        'facebook': _facebookCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Ajustes guardados correctamente"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajustes del Negocio", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SECCIÓN: CONTACTO ---
                  const Text("Contacto & Ubicación", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  _buildTextField("Teléfono (WhatsApp)", _phoneCtrl, Icons.phone, keyboardType: TextInputType.phone),
                  _buildTextField("Dirección Visible", _addressCtrl, Icons.location_on),
                  
                  const SizedBox(height: 30),
                  
                  // --- SECCIÓN: REDES SOCIALES ---
                  const Text("Redes Sociales (Links)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),
                  _buildTextField("Instagram URL", _instagramCtrl, Icons.camera_alt, color: Colors.purple),
                  _buildTextField("Facebook URL", _facebookCtrl, Icons.facebook, color: Colors.blue),

                  const SizedBox(height: 40),
                  
                  // BOTÓN GUARDAR
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text("Guardar Cambios", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Divider(thickness: 2),
                  const SizedBox(height: 20),

                  // --- SECCIÓN: SEGURIDAD (NUEVO) ---
                  const Text("Seguridad y Accesos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                  const SizedBox(height: 15),

                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300)
                    ),
                    color: Colors.white,
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.add_moderator, color: Colors.black87),
                      ),
                      title: const Text("Registrar Nuevo Administrador", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Crear cuenta con acceso total al panel."),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterAdminPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {Color color = Colors.grey, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: color),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        ),
      ),
    );
  }
}