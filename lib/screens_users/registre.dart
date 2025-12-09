import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para validar solo números
import 'package:paulette/services/auth_service.dart';

class Registre extends StatefulWidget {
  const Registre({super.key});

  @override
  State<Registre> createState() => _RegistreState();
}

class _RegistreState extends State<Registre> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  
  // Controladores de texto
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // 🆕 Nuevo
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  
  // Variables para dropdowns
  String? _tieneDiabetes;
  String? _tieneAlergia;
  
  // Estados
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true; // 🆕 Nuevo
  bool _termsAccepted = false; // 🆕 Nuevo

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _phone2Controller.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      _showMessage('Por favor revisa los campos en rojo', Colors.orange);
      return;
    }

    if (!_termsAccepted) {
      _showMessage('Debes aceptar los términos y condiciones', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      nombre: _nameController.text.trim(),
      telefono: _phoneController.text.trim(),
      telefono2: _phone2Controller.text.trim().isEmpty ? null : _phone2Controller.text.trim(),
      tieneDiabetes: _tieneDiabetes!,
      tieneAlergia: _tieneAlergia!,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      _showMessage('¡Registro exitoso! Ya puedes iniciar sesión', Colors.green);
      Navigator.pop(context); // Regresar al login
    } else {
      _showMessage(result['message'] ?? 'Error al registrarse', Colors.red);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Completa tus datos",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                
                // NOMBRE
                _buildLabel("Nombre Completo"),
                _buildTextField(
                  controller: _nameController,
                  icon: Icons.person_outline,
                  hint: "Ej. María Pérez",
                  validator: (val) => val!.isEmpty ? 'Ingresa tu nombre' : null,
                ),

                // CORREO
                _buildLabel("Correo Electrónico"),
                _buildTextField(
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  hint: "correo@ejemplo.com",
                  inputType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Ingresa tu correo';
                    if (!val.contains('@') || !val.contains('.')) return 'Correo inválido';
                    return null;
                  },
                ),

                // TELÉFONO
                _buildLabel("Teléfono (WhatsApp)"),
                _buildTextField(
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  hint: "10 dígitos",
                  inputType: TextInputType.phone,
                  // Validación estricta: solo números y longitud exacta
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Ingresa tu teléfono';
                    if (val.length < 10) return 'Debe tener 10 dígitos';
                    return null;
                  },
                ),

                // TELÉFONO 2
                _buildLabel("Teléfono Alternativo (Opcional)"),
                _buildTextField(
                  controller: _phone2Controller,
                  icon: Icons.phone_android_outlined,
                  hint: "Opcional",
                  inputType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                ),

                const Divider(height: 40),

                // CONTRASEÑA
                _buildLabel("Contraseña"),
                _buildTextField(
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  hint: "Mínimo 6 caracteres",
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Ingresa una contraseña';
                    if (val.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),

                // CONFIRMAR CONTRASEÑA (NUEVO)
                _buildLabel("Confirmar Contraseña"),
                _buildTextField(
                  controller: _confirmPasswordController,
                  icon: Icons.lock_clock,
                  hint: "Repite tu contraseña",
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onTogglePassword: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  validator: (val) {
                    if (val != _passwordController.text) return 'Las contraseñas no coinciden';
                    return null;
                  },
                ),

                const Divider(height: 40),
                const Text("Información de Salud (Importante)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
                const SizedBox(height: 15),

                // DIABETES
                _buildLabel("¿Tienes Diabetes?"),
                _buildDropdown(
                  value: _tieneDiabetes,
                  icon: Icons.medical_services_outlined,
                  onChanged: (val) => setState(() => _tieneDiabetes = val),
                ),

                // ALERGIAS
                _buildLabel("¿Tienes Alergias?"),
                _buildDropdown(
                  value: _tieneAlergia,
                  icon: Icons.warning_amber_rounded,
                  onChanged: (val) => setState(() => _tieneAlergia = val),
                ),

                const SizedBox(height: 20),

                // CHECKBOX TÉRMINOS (NUEVO)
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      activeColor: Colors.black,
                      onChanged: (val) => setState(() => _termsAccepted = val!),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                        child: const Text("Acepto los Términos y Condiciones y la Política de Privacidad.", style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // BOTÓN
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 5,
                    ),
                    onPressed: _isLoading ? null : _handleRegister,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("CREAR CUENTA", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 20),
                
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("¿Ya tienes cuenta? Inicia sesión", style: TextStyle(color: Colors.grey)),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widgets Auxiliares para limpiar el código
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 10.0),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      obscureText: isPassword ? obscureText : false,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        hintText: hint,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: onTogglePassword,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.pinkAccent),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required IconData icon,
    required void Function(String?)? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      hint: const Text("Selecciona una opción"),
      items: ['Sí', 'No'].map((String val) {
        return DropdownMenuItem(value: val, child: Text(val));
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? 'Campo requerido' : null,
    );
  }
}