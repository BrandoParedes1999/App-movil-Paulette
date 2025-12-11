import 'package:flutter/material.dart';
import 'package:paulette/services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _authService.signIn(
      _emailController.text,
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Bienvenido!'), backgroundColor: Colors.green),
      );

      if (result['isAdmin']) {
        Navigator.pushReplacementNamed(context, '/menuadmin');
      } else {
        Navigator.pushReplacementNamed(context, '/menuclient');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al iniciar sesión'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) { 
        bool isResetting = false; 

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Recuperar Contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ingresa tu correo. Si existe, te enviaremos un enlace. Si no, te redirigiremos al registro.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: emailResetController,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (isResetting) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isResetting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isResetting
                      ? null
                      : () async {
                          final email = emailResetController.text.trim();
                          if (email.isEmpty) {
                             ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(content: Text('Por favor escribe un correo')),
                             );
                             return;
                          }

                          if (dialogContext.mounted) {
                            setStateDialog(() => isResetting = true);
                          }

                          // 1. VERIFICAMOS SI EXISTE EL USUARIO EN LA BASE DE DATOS
                          final bool exists = await _authService.checkUserExists(email);

                          if (!exists) {
                            // --- CASO: NO EXISTE ---
                            // Cerramos el diálogo de carga
                            if (dialogContext.mounted) {
                               setStateDialog(() => isResetting = false);
                               Navigator.pop(dialogContext); // Cerramos el popup
                            }
                            
                            // Mostramos mensaje y redirigimos
                            if (mounted) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Correo no registrado. Redirigiendo al registro...'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              // Navegamos al registro automáticamente
                              Navigator.pushNamed(this.context, '/registre');
                            }
                            return; 
                          }

                          // --- CASO: SÍ EXISTE ---
                          // 2. Enviamos el correo de recuperación
                          final result = await _authService.resetPassword(email);

                          if (dialogContext.mounted) {
                             Navigator.pop(dialogContext);
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: result['success'] ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                  child: const Text('Continuar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // 1. CUERPO (Formulario)
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // LOGO
                Hero(
                  tag: 'logo',
                  child: Image.asset(
                    "assets/images/logo_principal.png",
                    height: 180,
                  ),
                ),
                const SizedBox(height: 40),

                const Text(
                  "Bienvenido",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // EMAIL
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu correo';
                    if (!value.contains('@')) return 'Correo inválido';
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // PASSWORD
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                    return null;
                  },
                ),

                const SizedBox(height: 10),

                // OLVIDE CONTRASEÑA
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: const Text("¿Olvidaste tu contraseña?"),
                  ),
                ),

                const SizedBox(height: 20),

                // BOTÓN LOGIN
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text("INICIAR SESIÓN"),
                  ),
                ),
                
                // NOTA: Aquí quitamos el Row de registro antiguo para ponerlo abajo
              ],
            ),
          ),
        ),
      ),

bottomNavigationBar: StreamBuilder<DocumentSnapshot>(
        // Escuchamos la misma colección que usaste en UbicacionOsmScreen
        stream: FirebaseFirestore.instance.collection('settings').doc('general_info').snapshots(),
        builder: (context, snapshot) {
          // Variables por defecto
          String fbLink = "";
          
          // Si hay datos, los extraemos
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            fbLink = data?['facebook'] ?? "";
          }

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.only(top: 10, bottom: 5, left: 20, right: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  // A. Registro (Esto sigue igual)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿No tienes cuenta?"),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/registre'),
                        child: const Text("Regístrate aquí", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),
                  
                  // B. Redes Sociales (DINÁMICO)
                  const Text("Síguenos para más información:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(), 
                    icon: const FaIcon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2), size: 28),
                    onPressed: () async {
                      if (fbLink.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enlace no configurado aún")),
                        );
                        return;
                      }

                      final Uri url = Uri.parse(fbLink);
                      // Intentamos abrir el enlace
                      try {
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          throw 'No se pudo lanzar $url';
                        }
                      } catch (e) {
                        print("Error abriendo Facebook: $e");
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No se pudo abrir Facebook")),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 5),

                  // C. Info Desarrollador
                  Text(
                    "Desarrollado por Brando Paredes © ${DateTime.now().year}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}