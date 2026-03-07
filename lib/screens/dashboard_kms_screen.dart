import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/top_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../services/ai_service.dart';
import '../models/user_model.dart';
import '../models/orang_tua_model.dart';
import '../models/pemeriksaan_balita_model.dart';
import '../models/balita_model.dart';
import '../models/riwayat_imunisasi_model.dart';
import '../models/master_imunisasi_model.dart';
import 'balita_list_screen.dart';
import 'balita_detail_screen.dart';

// ==========================================
// 1. DASHBOARD & KMS ANAK
// ==========================================
class DashboardKmsScreen extends StatefulWidget {
  const DashboardKmsScreen({super.key});

  @override
  State<DashboardKmsScreen> createState() => _DashboardKmsScreenState();
}

class _DashboardKmsScreenState extends State<DashboardKmsScreen> {
  int _selectedTab = 0; // 0: Umum, 1: Riwayat, 2: Jadwal

  bool _isLoadingAI = false;
  String? _aiResult;

  // Cached futures to avoid recreating on every build (prevents _dependents.isEmpty)
  late final Future<UserModel?> _userFuture;
  late final Future<OrangTuaModel?> _orangTuaFuture;
  late final Future<Map<String, int>> _kaderCountFuture;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _userFuture = DatabaseService().getUserData(uid);
    _orangTuaFuture = DatabaseService().getOrangTuaByUserId(uid);
    _kaderCountFuture = DatabaseService().getKaderCountByJabatan();
  }

  // ── WHO Weight-for-Age reference data ──────────────────────────────────────
  // Format: [usia_bulan, -3SD, -2SD, Median, +2SD]  (laki-laki / boys)
  static const List<List<double>> _whoBoysWfa = [
    [0, 2.1, 2.5, 3.3, 4.4],
    [1, 2.9, 3.4, 4.5, 5.8],
    [2, 3.8, 4.3, 5.6, 7.1],
    [3, 4.4, 5.0, 6.4, 8.0],
    [4, 4.9, 5.6, 7.0, 8.7],
    [5, 5.3, 6.0, 7.5, 9.3],
    [6, 5.7, 6.4, 7.9, 9.8],
    [7, 5.9, 6.7, 8.3, 10.3],
    [8, 6.2, 7.0, 8.6, 10.7],
    [9, 6.4, 7.2, 8.9, 11.0],
    [10, 6.6, 7.5, 9.2, 11.4],
    [11, 6.8, 7.7, 9.4, 11.7],
    [12, 6.9, 7.8, 9.6, 12.0],
    [15, 7.4, 8.4, 10.3, 12.8],
    [18, 7.7, 8.8, 10.9, 13.7],
    [21, 8.1, 9.2, 11.5, 14.5],
    [24, 8.6, 9.7, 12.2, 15.3],
    [27, 9.0, 10.2, 12.8, 16.1],
    [30, 9.4, 10.7, 13.3, 16.8],
    [33, 9.7, 11.1, 13.8, 17.4],
    [36, 10.0, 11.4, 14.3, 18.0],
    [42, 10.7, 12.1, 15.3, 19.4],
    [48, 11.3, 12.9, 16.3, 20.7],
    [54, 12.0, 13.6, 17.3, 22.1],
    [60, 12.7, 14.4, 18.3, 23.5],
  ];

  // Format: [usia_bulan, -3SD, -2SD, Median, +2SD]  (perempuan / girls)
  static const List<List<double>> _whoGirlsWfa = [
    [0, 2.0, 2.4, 3.2, 4.2],
    [1, 2.7, 3.2, 4.2, 5.5],
    [2, 3.4, 3.9, 5.1, 6.6],
    [3, 4.0, 4.5, 5.8, 7.5],
    [4, 4.4, 5.0, 6.4, 8.2],
    [5, 4.8, 5.4, 6.9, 8.8],
    [6, 5.1, 5.7, 7.3, 9.3],
    [7, 5.3, 6.0, 7.6, 9.8],
    [8, 5.6, 6.3, 7.9, 10.2],
    [9, 5.8, 6.5, 8.2, 10.5],
    [10, 6.0, 6.7, 8.5, 10.9],
    [11, 6.1, 6.9, 8.7, 11.2],
    [12, 6.3, 7.1, 8.9, 11.5],
    [15, 6.8, 7.6, 9.6, 12.4],
    [18, 7.2, 8.1, 10.2, 13.2],
    [21, 7.6, 8.6, 10.9, 14.0],
    [24, 8.1, 9.0, 11.5, 14.8],
    [27, 8.5, 9.5, 12.2, 15.7],
    [30, 8.8, 9.9, 12.8, 16.4],
    [33, 9.1, 10.3, 13.3, 17.1],
    [36, 9.5, 10.7, 13.9, 17.9],
    [42, 10.2, 11.4, 14.8, 19.2],
    [48, 10.8, 12.1, 15.8, 20.5],
    [54, 11.4, 12.8, 16.8, 21.9],
    [60, 12.1, 13.7, 17.7, 23.2],
  ];

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final bgBiruMuda = const Color(0xFFF5F9FD);
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: bgBiruMuda,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 10.0,
                bottom: 100.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 48, // Increased size for better visibility
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Stack(
                            children: [
                              const Icon(
                                Icons.notifications_none_rounded,
                                size: 28,
                              ),
                              Positioned(
                                right: 2,
                                top: 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // Greeting
                  Builder(
                    builder: (context) {
                      final greeting = _getTimeGreeting();
                      final name = userSnapshot.data?.namaPanggilan ?? 'User';
                      return Text(
                        '$greeting, $name!',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 5),
                  ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF0288D1), // Darker Blue
                        Color(0xFF81D4FA), // Light Blue/White tint
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Posyandu Ciguruwik',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(
                              0.1,
                            ), // light grey translucent
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search,
                            color: Colors.black87,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 15),
                        _buildTab('Umum', 0),
                        const SizedBox(width: 10),
                        _buildTab('Riwayat', 1),
                        const SizedBox(width: 10),
                        _buildTab('Jadwal', 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Hero Section: Kader on Duty
                  Container(
                    width: double.infinity,
                    height: 340,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: const Color(0xFFE1F5FE), // Light blue tint
                      image: const DecorationImage(
                        image: NetworkImage(
                          'https://images.pexels.com/photos/7578808/pexels-photo-7578808.jpeg?auto=compress&cs=tinysrgb&w=800',
                        ), // Professional female health worker / Midwife
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Top Left Label
                        Positioned(
                          top: 20,
                          left: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.medical_services_rounded,
                                  size: 16,
                                  color: Color(0xFF0288D1),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Bidan Bertugas',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF0288D1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Glassmorphism Stats Pill at Bottom
                        Positioned(
                          bottom: 20,
                          left: 20,
                          right: 20,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: FutureBuilder<Map<String, int>>(
                              future: _kaderCountFuture,
                              builder: (context, kaderSnap) {
                                final counts = kaderSnap.data ?? {'bidan': 0, 'kader': 0};
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildKaderStat(
                                      'Bidan',
                                      '${counts['bidan']}',
                                      Icons.local_hospital_outlined,
                                    ),
                                    _buildKaderStat(
                                      'Kader',
                                      '${counts['kader']}',
                                      Icons.people_outline,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Status Anak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kondisi Anak',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Custom Dropdown Trigger
                      PopupMenuButton<String>(
                        offset: const Offset(0, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        color: Colors.white,
                        elevation: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Data Anak',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.blue.shade700,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                        onSelected: (value) async {
                          if (value == 'semua_anak') {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user != null && mounted) {
                              // We need the orang_tua_id for this user
                              final otData = await DatabaseService()
                                  .getOrangTuaByUserId(user.uid);
                              if (otData != null && mounted) {
                                // Check if parent has any children
                                final balitaSnapshot = await DatabaseService()
                                    .streamBalitaByOrangTua(otData.id)
                                    .first;

                                if (balitaSnapshot.isEmpty && mounted) {
                                  TopNotification.show(
                                    context,
                                    'Mohon maaf, data anak saat ini belum lengkap, mohon lengkapi di menu profile anda!',
                                    isError: true,
                                  );
                                } else if (balitaSnapshot.length == 1 &&
                                    mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BalitaDetailScreen(
                                        data: balitaSnapshot.first,
                                      ),
                                    ),
                                  );
                                } else if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BalitaListScreen(
                                        orangTuaId: otData.id,
                                      ),
                                    ),
                                  );
                                }
                              } else if (mounted) {
                                TopNotification.show(
                                  context,
                                  'Mohon maaf, data anak saat ini belum lengkap, mohon lengkapi di menu profile anda!',
                                  isError: true,
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'semua_anak',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.list_alt_rounded,
                                  color: Colors.blue.shade400,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Lihat semua data anak',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // Status Cards (Dynamic via stream)
                  // Need orang_tua doc ID (not user doc ID) for balita query
                  FutureBuilder<OrangTuaModel?>(
                    future: _orangTuaFuture,
                    builder: (context, otSnap) {
                      if (otSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final orangTuaId = otSnap.data?.id ?? '';

                      return StreamBuilder<List<BalitaModel>>(
                        stream: DatabaseService()
                            .streamBalitaByOrangTua(orangTuaId),
                        builder: (context, balitaSnap) {
                      final firstBalitaId =
                          (balitaSnap.data != null &&
                              balitaSnap.data!.isNotEmpty)
                          ? balitaSnap.data!.first.id
                          : 'empty';

                      return StreamBuilder<List<PemeriksaanBalitaModel>>(
                        stream: DatabaseService().streamPemeriksaanBalita(
                          firstBalitaId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          // Get latest pemeriksaan (sort by usia descending)
                          String beratText = '-';
                          String beratVal = 'Belum ada data';
                          Color beratColor = Colors.grey;

                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final sorted = List<PemeriksaanBalitaModel>.from(snapshot.data!)
                              ..sort((a, b) => b.usiaSaatPeriksa.compareTo(a.usiaSaatPeriksa));
                            final lastCheck = sorted.first;
                            beratText = lastCheck.statusGizi.isNotEmpty
                                ? lastCheck.statusGizi
                                : 'Normal';
                            beratVal = '${lastCheck.beratBadan} kg';
                            if (lastCheck.indikasiStunting) {
                              beratColor = Colors.red.shade600;
                            } else if (lastCheck.statusGizi.toLowerCase().contains('kurang')) {
                              beratColor = Colors.orange.shade600;
                            } else {
                              beratColor = Colors.green.shade600;
                            }
                          } else if (balitaSnap.data != null && balitaSnap.data!.isNotEmpty) {
                            // No pemeriksaan yet — show birth data
                            final b = balitaSnap.data!.first;
                            beratText = 'Data Lahir';
                            beratVal = '${b.beratLahir} kg';
                            beratColor = Colors.blue.shade600;
                          }

                          // Get first balita for imunisasi lookup
                          final firstBalita = (balitaSnap.data != null && balitaSnap.data!.isNotEmpty)
                              ? balitaSnap.data!.first
                              : null;

                          return Column(
                            children: [
                              Row(
                                children: [
                                  // Imunisasi Card — from database
                                  Expanded(
                                    child: _buildImunisasiCard(firstBalita),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green.shade100,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Berat Badan',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            beratText,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            beratVal,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: beratColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ), // end Row

                              const SizedBox(height: 30),

                              // AI Analysis Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.auto_awesome,
                                          color: const Color(0xFF0288D1),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Analisis AI (With Gemini)',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                    if (_isLoadingAI)
                                      const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    else if (_aiResult != null)
                                      Text(
                                        _aiResult!,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: Colors.black87,
                                        ),
                                      )
                                    else
                                      const Text(
                                        'Klik tombol di bawah untuk menganalisis kesehatan anak berdasarkan riwayat.',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    const SizedBox(height: 15),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFFE1F5FE),
                                          foregroundColor:
                                              const Color(0xFF0288D1),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                        ),
                                        onPressed: _isLoadingAI
                                            ? null
                                            : () async {
                                                if (balitaSnap.data == null ||
                                                    balitaSnap.data!.isEmpty) {
                                                  TopNotification.show(
                                                    context,
                                                    'Data anak belum tersedia. Lengkapi di menu profil.',
                                                    isError: true,
                                                  );
                                                  return;
                                                }
                                                setState(() {
                                                  _isLoadingAI = true;
                                                  _aiResult = null;
                                                });
                                                try {
                                                  final result =
                                                      await AIService.analyzeKesehatan(
                                                        balitaSnap.data!.first,
                                                        snapshot.data ?? [],
                                                      );
                                                  if (mounted) {
                                                    setState(() {
                                                      _aiResult = result;
                                                    });
                                                  }
                                                } finally {
                                                  if (mounted) {
                                                    setState(() {
                                                      _isLoadingAI = false;
                                                    });
                                                  }
                                                }
                                              },
                                        child: const Text('Mulai Analisis'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Growth Chart
                              const Text(
                                'Grafik Berat Badan (KMS)',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _buildGrowthChart(
                                (balitaSnap.data?.isNotEmpty ?? false)
                                    ? balitaSnap.data!.first
                                    : null,
                                snapshot.data ?? [],
                              ),

                              const SizedBox(height: 30),

                              // ── Manajemen Data Pertumbuhan ──────────────
                              _buildGrowthDataManager(
                                (balitaSnap.data?.isNotEmpty ?? false)
                                    ? balitaSnap.data!.first
                                    : null,
                                snapshot.data ?? [],
                              ),
                            ],
                          );
                        },
                      ); // end StreamBuilder pemeriksaan
                    },
                  ); // end StreamBuilder<List<BalitaModel>>
                    },
                  ), // end FutureBuilder<OrangTuaModel>
                ],
              ), // end Column
            ), // end SingleChildScrollView
          ), // end SafeArea
        ); // end Scaffold
      }, // end user FutureBuilder builder
    ); // end user FutureBuilder
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black87 : Colors.grey,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  /// Builds the Imunisasi card by looking up the next due or last given immunization from DB.
  Widget _buildImunisasiCard(BalitaModel? balita) {
    if (balita == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade100, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Imunisasi', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 10),
            const Text('-', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('Belum ada data', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
          ],
        ),
      );
    }

    return FutureBuilder<List<MasterImunisasiModel>>(
      future: DatabaseService().getAllMasterImunisasi(),
      builder: (context, masterSnap) {
        return StreamBuilder<List<RiwayatImunisasiModel>>(
          stream: DatabaseService().streamRiwayatImunisasi(balita.id),
          builder: (context, riwayatSnap) {
            String namaImunisasi = '-';
            String subtitle = 'Belum ada data';
            Color subtitleColor = Colors.grey.shade400;

            final masterList = masterSnap.data ?? [];
            final riwayatList = riwayatSnap.data ?? [];

            // Calculate child's age in months
            final now = DateTime.now();
            final ageMonths = (now.year - balita.tanggalLahir.year) * 12 +
                now.month - balita.tanggalLahir.month;

            // IDs of immunizations already given
            final givenIds = riwayatList.map((r) => r.imunisasiId).toSet();

            if (masterList.isNotEmpty) {
              // Sort master by usia_wajib_bulan
              final sortedMaster = List<MasterImunisasiModel>.from(masterList)
                ..sort((a, b) => a.usiaWajibBulan.compareTo(b.usiaWajibBulan));

              // Find next due immunization (not yet given, age >= usia_wajib)
              MasterImunisasiModel? nextDue;
              for (final m in sortedMaster) {
                if (!givenIds.contains(m.id) && ageMonths >= m.usiaWajibBulan) {
                  nextDue = m;
                  break;
                }
              }

              // If no overdue, find upcoming
              if (nextDue == null) {
                for (final m in sortedMaster) {
                  if (!givenIds.contains(m.id)) {
                    nextDue = m;
                    break;
                  }
                }
              }

              if (nextDue != null) {
                namaImunisasi = nextDue.namaImunisasi;
                if (ageMonths >= nextDue.usiaWajibBulan) {
                  subtitle = 'Segera berikan';
                  subtitleColor = Colors.orange.shade600;
                } else {
                  subtitle = 'Usia ${nextDue.usiaWajibBulan} bulan';
                  subtitleColor = Colors.blue.shade400;
                }
              } else if (riwayatList.isNotEmpty) {
                // All immunizations completed — show last given
                final lastRiwayat = riwayatList.reduce((a, b) =>
                    a.tanggalDiberikan.isAfter(b.tanggalDiberikan) ? a : b);
                final lastMaster = masterList
                    .where((m) => m.id == lastRiwayat.imunisasiId)
                    .toList();
                namaImunisasi = lastMaster.isNotEmpty
                    ? lastMaster.first.namaImunisasi
                    : 'Selesai';
                subtitle = 'Sudah lengkap';
                subtitleColor = Colors.green.shade600;
              }
            } else if (riwayatList.isNotEmpty) {
              // No master data but has riwayat
              namaImunisasi = '${riwayatList.length} diberikan';
              subtitle = 'Data master tidak tersedia';
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade100, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Imunisasi', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text(
                    namaImunisasi,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: subtitleColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKaderStat(String label, String count, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF4FC3F7),
            ), // Light blue icon
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          count,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGrowthChart(
    BalitaModel? balita,
    List<PemeriksaanBalitaModel> data,
  ) {
    final isGirl = balita?.jenisKelamin == 'P';
    final whoRef = isGirl ? _whoGirlsWfa : _whoBoysWfa;

    // Sort actual data ascending by age
    final sortedData = List<PemeriksaanBalitaModel>.from(data)
      ..sort((a, b) => a.usiaSaatPeriksa.compareTo(b.usiaSaatPeriksa));

    // X range: always at least 0→12, capped at 60 months
    const double xMin = 0;
    final double xMax = sortedData.isEmpty
        ? 12
        : sortedData.last.usiaSaatPeriksa.toDouble().clamp(12.0, 60.0);

    // Filter WHO reference rows to [0 .. xMax]
    final ref = whoRef.where((r) => r[0] <= xMax).toList();

    final minus3sdSpots = ref.map((r) => FlSpot(r[0], r[1])).toList();
    final minus2sdSpots = ref.map((r) => FlSpot(r[0], r[2])).toList();
    final medianSpots   = ref.map((r) => FlSpot(r[0], r[3])).toList();
    final plus2sdSpots  = ref.map((r) => FlSpot(r[0], r[4])).toList();

    // fl_chart crashes when an actual-data line has only 1 spot → ghost offset
    List<FlSpot> actualSpots = sortedData
        .map((d) => FlSpot(d.usiaSaatPeriksa.toDouble(), d.beratBadan))
        .toList();
    if (actualSpots.length == 1) {
      actualSpots = [
        actualSpots.first,
        FlSpot(actualSpots.first.x + 0.01, actualSpots.first.y),
      ];
    }

    // Y range
    double maxY = plus2sdSpots.isNotEmpty ? plus2sdSpots.last.y + 2 : 25;
    if (sortedData.isNotEmpty) {
      final maxActual =
          sortedData.map((e) => e.beratBadan).reduce((a, b) => a > b ? a : b);
      if (maxActual + 2 > maxY) maxY = maxActual + 3;
    }
    maxY = maxY.ceilToDouble();

    final double xInterval = xMax <= 12 ? 2 : (xMax <= 36 ? 6 : 12);

    // ── Line definitions ────────────────────────────────────────────────────
    // Rendering order matters: fl_chart paints belowBarData in list order.
    // +2SD (green) paints first → -2SD (orange) overwrites below -2SD →
    // -3SD (red) overwrites below -3SD → zones appear correctly without
    // betweenBarsData (not supported in fl_chart 1.x).
    final lines = <LineChartBarData>[
      // 0: +2SD ← blue dashed, green fill below (Normal zone)
      LineChartBarData(
        spots: plus2sdSpots,
        isCurved: true,
        color: Colors.blue.shade300,
        barWidth: 1.2,
        dotData: const FlDotData(show: false),
        dashArray: [5, 4],
        belowBarData: BarAreaData(
          show: true,
          color: Colors.green.withOpacity(0.10),
        ),
      ),
      // 1: -2SD ← orange dashed, orange fill below (overwrites green → Gizi Kurang zone)
      LineChartBarData(
        spots: minus2sdSpots,
        isCurved: true,
        color: Colors.orange.shade400,
        barWidth: 1.2,
        dotData: const FlDotData(show: false),
        dashArray: [5, 4],
        belowBarData: BarAreaData(
          show: true,
          color: Colors.orange.withOpacity(0.15),
        ),
      ),
      // 2: -3SD ← red dashed, red fill below (overwrites orange → Gizi Buruk zone)
      LineChartBarData(
        spots: minus3sdSpots,
        isCurved: true,
        color: Colors.red.shade400,
        barWidth: 1.2,
        dotData: const FlDotData(show: false),
        dashArray: [5, 4],
        belowBarData: BarAreaData(
          show: true,
          color: Colors.red.withOpacity(0.15),
        ),
      ),
      // 3: Median ← green dashed, no fill
      LineChartBarData(
        spots: medianSpots,
        isCurved: true,
        color: Colors.green.shade500,
        barWidth: 1.2,
        dotData: const FlDotData(show: false),
        dashArray: [5, 4],
      ),
      // 4: Actual child weight ← solid blue (only when data exists)
      if (actualSpots.isNotEmpty)
        LineChartBarData(
          spots: actualSpots,
          isCurved: true,
          color: const Color(0xFF0288D1),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, pct, barData, idx) => FlDotCirclePainter(
              radius: 5,
              color: Colors.white,
              strokeWidth: 2.5,
              strokeColor: const Color(0xFF0288D1),
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(
            right: 16,
            left: 8,
            top: 20,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gender + standard badge
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (isGirl ? Colors.pink : Colors.blue)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isGirl
                                ? Icons.female_rounded
                                : Icons.male_rounded,
                            size: 14,
                            color: isGirl ? Colors.pink : Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isGirl ? 'Perempuan' : 'Laki-laki',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isGirl ? Colors.pink : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Standar WHO',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              // Chart
              SizedBox(
                height: 260,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Usia (bulan)',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                        axisNameSize: 18,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 26,
                          interval: xInterval,
                          getTitlesWidget: (value, meta) => SideTitleWidget(
                            meta: meta,
                            child: Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        axisNameWidget: const Text(
                          'Berat (kg)',
                          style: TextStyle(fontSize: 9, color: Colors.grey),
                        ),
                        axisNameSize: 20,
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34,
                          interval: 2,
                          getTitlesWidget: (value, meta) => Text(
                            '${value.toInt()}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    minX: xMin,
                    maxX: xMax,
                    minY: 0,
                    maxY: maxY,
                    lineBarsData: lines,
                    lineTouchData: LineTouchData(
                      handleBuiltInTouches: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF0288D1),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            // Only show tooltip for actual child data (index 4)
                            // Actual data is at index 4 (after 4 reference lines)
                            if (spot.barIndex != 4) return null;
                            return LineTooltipItem(
                              '${spot.x.toInt()} bln\n'
                              '${spot.y.toStringAsFixed(1)} kg',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Legend ──────────────────────────────────────────────────────────
        Wrap(
          spacing: 10,
          runSpacing: 6,
          children: [
            _chartLegendItem(Colors.red.shade400, 'Gizi Buruk (<-3SD)'),
            _chartLegendItem(Colors.orange.shade400, 'Gizi Kurang (-3~-2SD)'),
            _chartLegendItem(Colors.green.shade500, 'Median Normal'),
            _chartLegendItem(Colors.blue.shade300, '+2SD (Lebih)'),
            _chartLegendItem(
              const Color(0xFF0288D1),
              'BB Anak',
              isThick: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _chartLegendItem(Color color, String label,
      {bool isThick = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: isThick ? 4 : 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // GROWTH DATA MANAGER — add / edit / delete pemeriksaan
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildGrowthDataManager(
    BalitaModel? balita,
    List<PemeriksaanBalitaModel> data,
  ) {
    final sorted = List<PemeriksaanBalitaModel>.from(data)
      ..sort((a, b) => a.usiaSaatPeriksa.compareTo(b.usiaSaatPeriksa));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Data Pertumbuhan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (balita != null)
              ElevatedButton.icon(
                onPressed: () => _showPemeriksaanDialog(balita, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (sorted.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Belum ada data pertumbuhan.\nTambahkan data pemeriksaan pertama.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          )
        else
          ...sorted.map((item) => _buildPemeriksaanCard(balita!, item)),
      ],
    );
  }

  Widget _buildPemeriksaanCard(BalitaModel balita, PemeriksaanBalitaModel item) {
    final isStunting = item.indikasiStunting;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStunting
              ? Colors.red.shade100
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Age circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0288D1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${item.usiaSaatPeriksa}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0288D1),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Usia ${item.usiaSaatPeriksa} bulan',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'BB: ${item.beratBadan} kg  •  TB: ${item.tinggiBadan} cm  •  LK: ${item.lingkarKepala} cm',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor(item.statusGizi).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.statusGizi,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _statusColor(item.statusGizi),
                        ),
                      ),
                    ),
                    if (isStunting) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Stunting',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Edit / Delete
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert,
              color: Colors.grey.shade400,
              size: 20,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (val) async {
              if (val == 'edit') {
                _showPemeriksaanDialog(balita, item);
              } else if (val == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Hapus Data'),
                    content: Text(
                      'Hapus data pemeriksaan usia ${item.usiaSaatPeriksa} bulan?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  try {
                    await DatabaseService()
                        .deletePemeriksaanBalitaById(item.id);
                    if (mounted) {
                      TopNotification.show(context, 'Data berhasil dihapus');
                    }
                  } catch (_) {
                    if (mounted) {
                      TopNotification.show(
                        context,
                        'Gagal menghapus data',
                        isError: true,
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Hapus',
                  style: TextStyle(color: Colors.red.shade600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'sangat kurus':
        return Colors.red.shade700;
      case 'kurus':
        return Colors.orange.shade700;
      case 'gemuk':
        return Colors.blue.shade600;
      case 'normal':
      default:
        return Colors.green.shade600;
    }
  }

  // ── Add / Edit Dialog ────────────────────────────────────────────────────
  void _showPemeriksaanDialog(BalitaModel balita, PemeriksaanBalitaModel? existing) {
    final isEdit = existing != null;
    final usiaCtrl = TextEditingController(
      text: isEdit ? existing.usiaSaatPeriksa.toString() : '',
    );
    final bbCtrl = TextEditingController(
      text: isEdit ? existing.beratBadan.toString() : '',
    );
    final tbCtrl = TextEditingController(
      text: isEdit ? existing.tinggiBadan.toString() : '',
    );
    final lkCtrl = TextEditingController(
      text: isEdit ? existing.lingkarKepala.toString() : '',
    );
    String statusGizi = isEdit ? existing.statusGizi : 'Normal';
    bool stunting = isEdit ? existing.indikasiStunting : false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isEdit ? 'Edit Data Pemeriksaan' : 'Tambah Data Pemeriksaan',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Usia
                    _dialogField('Usia (bulan)', usiaCtrl, TextInputType.number),
                    const SizedBox(height: 12),
                    // BB
                    _dialogField('Berat Badan (kg)', bbCtrl, const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 12),
                    // TB
                    _dialogField('Tinggi Badan (cm)', tbCtrl, const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 12),
                    // LK
                    _dialogField('Lingkar Kepala (cm)', lkCtrl, const TextInputType.numberWithOptions(decimal: true)),
                    const SizedBox(height: 12),

                    // Status Gizi dropdown
                    const Text(
                      'Status Gizi',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: statusGizi,
                          items: ['Sangat Kurus', 'Kurus', 'Normal', 'Gemuk']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setModalState(() => statusGizi = v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Stunting toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Indikasi Stunting',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: stunting,
                      activeColor: Colors.red,
                      onChanged: (v) => setModalState(() => stunting = v),
                    ),
                    const SizedBox(height: 16),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0288D1),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final usia = int.tryParse(usiaCtrl.text.trim());
                          final bb = double.tryParse(bbCtrl.text.trim());
                          final tb = double.tryParse(tbCtrl.text.trim());
                          final lk = double.tryParse(lkCtrl.text.trim());

                          if (usia == null || bb == null || tb == null || lk == null) {
                            TopNotification.show(
                              context,
                              'Semua field harus diisi dengan benar',
                              isError: true,
                            );
                            return;
                          }

                          final model = PemeriksaanBalitaModel(
                            id: isEdit ? existing.id : '',
                            balitaId: balita.id,
                            jadwalId: isEdit ? existing.jadwalId : '',
                            usiaSaatPeriksa: usia,
                            beratBadan: bb,
                            tinggiBadan: tb,
                            lingkarKepala: lk,
                            statusGizi: statusGizi,
                            indikasiStunting: stunting,
                            kaderId: isEdit ? existing.kaderId : '',
                          );

                          Navigator.pop(ctx);

                          try {
                            if (isEdit) {
                              await DatabaseService()
                                  .updatePemeriksaanBalita(model);
                            } else {
                              await DatabaseService()
                                  .addPemeriksaanBalita(model);
                            }
                            if (mounted) {
                              TopNotification.show(
                                context,
                                isEdit
                                    ? 'Data berhasil diperbarui'
                                    : 'Data berhasil ditambahkan',
                              );
                            }
                          } catch (_) {
                            if (mounted) {
                              TopNotification.show(
                                context,
                                'Gagal menyimpan data',
                                isError: true,
                              );
                            }
                          }
                        },
                        child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Data'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0288D1)),
            ),
          ),
        ),
      ],
    );
  }
}
