import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PosyanduApp());
}

class PosyanduApp extends StatelessWidget {
  const PosyanduApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Pastel yang ramah anak dan menenangkan
    const Color toscaLembut = Color(0xFF80CBC4); // Teal 200
    const Color pinkSalem = Color(0xFFFFCCBC); // Deep Orange 100
    const Color biruBayi = Color(0xFFB3E5FC); // Light Blue 100
    const Color backgroundApp = Color(0xFFF9FBE7); // Lime 50

    return MaterialApp(
      title: 'Ruang Tumbuh Posyandu',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Font bisa diganti nanti, tapi sementara pakai visual yang membulat (default sans-serif)
        colorScheme: ColorScheme.fromSeed(
          seedColor: toscaLembut,
          primary: toscaLembut,
          secondary: pinkSalem,
          tertiary: biruBayi,
          background: backgroundApp,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: backgroundApp,
        appBarTheme: const AppBarTheme(
          backgroundColor: toscaLembut,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
          titleMedium: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
