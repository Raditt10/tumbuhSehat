import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'services/seeder_service.dart';
import 'services/app_navigator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id');

  // Auto-seed some initial data if Firestore is empty to test dynamic UI
  await SeederService().seedDummyData();

  runApp(const PosyanduApp());
}

class PosyanduApp extends StatelessWidget {
  const PosyanduApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Definisi Warna Tema Biru Muda
    const Color biruMuda = Color(0xFF4FC3F7); // Light Blue 300
    const Color biruPucat = Color(0xFFE1F5FE); // Light Blue 50
    const Color aksenBiru = Color(0xFF0288D1); // Light Blue 700
    const Color backgroundApp = Color(0xFFF5F9FD); // Very light greyish blue

    return MaterialApp(
      title: 'Ruang Tumbuh Posyandu',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        // Font bisa diganti nanti, tapi sementara pakai visual yang membulat (default sans-serif)
        colorScheme: ColorScheme.fromSeed(
          seedColor: biruMuda,
          primary: biruMuda,
          secondary: aksenBiru,
          tertiary: biruPucat,
          background: backgroundApp,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: backgroundApp,
        appBarTheme: const AppBarTheme(
          backgroundColor: biruMuda,
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
        textTheme: GoogleFonts.poppinsTextTheme(
          const TextTheme(
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
        ),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
