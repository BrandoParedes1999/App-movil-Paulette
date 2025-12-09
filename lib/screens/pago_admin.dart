import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FormasPago extends StatefulWidget {
  const FormasPago({super.key});

  @override
  State<FormasPago> createState() => _FormasPagoState();
}

class _FormasPagoState extends State<FormasPago> {
  // Controladores para editar la info
  final TextEditingController _titularCtrl = TextEditingController();
  final TextEditingController _bancoCtrl = TextEditingController();
  final TextEditingController _clabeCtrl = TextEditingController();
  final TextEditingController _telefonoCtrl = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = true;

  // Referencia a la configuración en Firebase
  final DocumentReference _paymentSettingsRef = 
      FirebaseFirestore.instance.collection('settings').doc('payment_info');

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  // 📥 Cargar datos actuales
  Future<void> _loadPaymentInfo() async {
    try {
      final doc = await _paymentSettingsRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _titularCtrl.text = data['titular'] ?? '';
        _bancoCtrl.text = data['banco'] ?? '';
        _clabeCtrl.text = data['clabe'] ?? '';
        _telefonoCtrl.text = data['telefono'] ?? '';
      } else {
        // Datos por defecto si no existen
        _titularCtrl.text = "MARCOS MARTINEZ SALAZAR";
        _bancoCtrl.text = "BBVA";
        _clabeCtrl.text = "5522 4455 3355 8855";
        _telefonoCtrl.text = "9382222222";
      }
    } catch (e) {
      print("Error cargando info de pago: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 💾 Guardar datos nuevos
  Future<void> _savePaymentInfo() async {
    setState(() => _isLoading = true);
    try {
      await _paymentSettingsRef.set({
        'titular': _titularCtrl.text.trim(),
        'banco': _bancoCtrl.text.trim(),
        'clabe': _clabeCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      setState(() => _isEditing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Información actualizada correctamente"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.pinkAccent,
        foregroundColor: Colors.white,
        title: const Text("Configurar Pagos", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) _loadPaymentInfo(); // Cancelar cambios
                _isEditing = !_isEditing;
              });
            },
          )
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.pinkAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Tarjeta de Efectivo (Estática)
                  _buildStaticCard("PAGO EN EFECTIVO", Icons.money, Colors.green),
                  
                  const SizedBox(height: 20),
                  
                  // Tarjeta de Transferencia (Editable)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.pinkAccent.withOpacity(0.3), width: 2),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.credit_card, color: Colors.pinkAccent),
                            SizedBox(width: 10),
                            Text("DATOS BANCARIOS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 10),
                        
                        _buildEditableField("Banco", _bancoCtrl, Icons.account_balance),
                        _buildEditableField("Titular", _titularCtrl, Icons.person),
                        _buildEditableField("CLABE / Tarjeta", _clabeCtrl, Icons.numbers),
                        _buildEditableField("Teléfono (Comprobantes)", _telefonoCtrl, Icons.phone_android),
                        
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: _savePaymentInfo,
                                icon: const Icon(Icons.save),
                                label: const Text("Guardar Cambios"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.pinkAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const Text(
                    "ℹ️ Esta información será visible para tus clientes cuando seleccionen 'Transferencia' al pagar.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        enabled: _isEditing,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _isEditing ? Colors.pinkAccent : Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: !_isEditing,
          fillColor: Colors.grey[100],
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _isEditing ? Colors.black : Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildStaticCard(String title, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}