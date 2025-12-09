import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// Tus imports correctos
import 'package:paulette/screens_users/menu_client.dart';
import 'package:paulette/screens_users/registre.dart';
import 'package:paulette/screens/login.dart';
import 'package:paulette/screens/menu_admin.dart';
import 'package:paulette/screens_users/location_client.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
      ],
      initialRoute: '/login',
      routes: {
        '/login': (context) => const Login(),
        '/menuadmin': (context) => const MenuAdmin(),
        '/menuclient': (context) => const MenuClient(),
        '/registre': (context) => const Registre(),
       
      },
    );
  }
}
