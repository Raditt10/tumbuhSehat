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

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  // Daftar Layar Aplikasi
  static const List<Widget> _pages = <Widget>[
    DashboardKmsScreen(),
    HistoryScreen(),
    InfoScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.child_care_rounded),
              label: 'KMS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_edu_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_rounded),
              label: 'Edukasi',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Profil',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

// ==========================================
// 1. DASHBOARD & KMS ANAK
// ==========================================
class DashboardKmsScreen extends StatelessWidget {
  const DashboardKmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruang Tumbuh'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Info Anak (UI Card Lembut)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: theme.colorScheme.tertiary,
                    child: const Icon(
                      Icons.face_retouching_natural_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, Budi Kecil!',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Usia: 14 Bulan',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    color: theme.colorScheme.primary,
                    size: 30,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Section: Pertumbuhan Terakhir
            Text('Pertumbuhan Terakhir', style: theme.textTheme.titleMedium),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard(
                  'Berat',
                  '10.5 kg',
                  Icons.scale_rounded,
                  theme.colorScheme.tertiary,
                ),
                _buildStatCard(
                  'Tinggi',
                  '78 cm',
                  Icons.height_rounded,
                  theme.colorScheme.secondary,
                ),
                _buildStatCard(
                  'Kepala',
                  '46 cm',
                  Icons.face_rounded,
                  const Color(0xFFFFF59D),
                ), // Yellow
              ],
            ),
            const SizedBox(height: 30),

            // Placeholder Grafik Pertumbuhan
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 50,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Grafik Pertumbuhan WHO akan tampil di sini',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. RIWAYAT MEDIS & IMUNISASI
// ==========================================
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Medis')),
      body: const Center(
        child: Text('Daftar Riwayat Penyakit & Jadwal Imunisasi'),
      ),
    );
  }
}

// ==========================================
// 3. PUSAT EDUKASI & INFORMASI
// ==========================================
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pusat Edukasi')),
      body: const Center(child: Text('Jadwal Posyandu & Artikel MPASI/Gizi')),
    );
  }
}

// ==========================================
// 4. PROFIL (TERMASUK GAMIFIKASI/BADGE)
// ==========================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: const Center(
        child: Text('Pengaturan, Privasi, Lencana (Badge) Gamifikasi'),
      ),
    );
  }
}
