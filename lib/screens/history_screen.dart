import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../models/orang_tua_model.dart';
import '../models/ibu_hamil_model.dart';
import '../models/pemeriksaan_bumil_model.dart';
import '../models/pemeriksaan_balita_model.dart';
import '../models/balita_model.dart';
import '../models/riwayat_imunisasi_model.dart';
import '../models/master_imunisasi_model.dart';

// ==========================================
// 2. RIWAYAT MEDIS & IMUNISASI
// ==========================================
class HistoryScreen extends StatelessWidget {
  final String role;
  const HistoryScreen({super.key, this.role = 'orang_tua'});

  bool get _isBumil => role == 'ibu_hamil';

  List<Color> get _gradientColors => _isBumil
      ? [const Color(0xFFE91E63), const Color(0xFFF48FB1)]
      : [const Color(0xFF0288D1), const Color(0xFF81D4FA)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20.0, right: 20.0, top: 10.0, bottom: 100.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', height: 48),
                  Stack(
                    children: [
                      const Icon(Icons.notifications_none_rounded, size: 28),
                      Positioned(
                        right: 2, top: 2,
                        child: Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Title
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => LinearGradient(
                  colors: _gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Riwayat Medis',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _isBumil
                    ? 'Catatan pemeriksaan kehamilan Anda'
                    : 'Catatan kesehatan dan imunisasi Anak',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Content based on role
              _isBumil ? _buildBumilHistory() : _buildBalitaHistory(),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────── IBU HAMIL HISTORY ────────────
  Widget _buildBumilHistory() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final db = DatabaseService();

    return FutureBuilder<OrangTuaModel?>(
      future: db.getOrangTuaByUserId(uid),
      builder: (context, otSnap) {
        if (otSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final ot = otSnap.data;
        if (ot == null) {
          return _emptyMsg('Data orang tua belum lengkap.');
        }

        return StreamBuilder<List<IbuHamilModel>>(
          stream: db.streamIbuHamilByOrangTua(ot.id),
          builder: (context, ibuSnap) {
            final ibuList = ibuSnap.data ?? [];
            if (ibuList.isEmpty) {
              return _emptyMsg('Belum ada data kehamilan.');
            }

            return Column(
              children: ibuList.map((ibu) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kehamilan header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade400, Colors.pink.shade200],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.pregnant_woman, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Kehamilan ke-${ibu.kehamilanKe}',
                                  style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'HPL: ${DateFormat('dd MMM yyyy').format(ibu.hpl)}',
                                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Pemeriksaan list
                    StreamBuilder<List<PemeriksaanBumilModel>>(
                      stream: db.streamPemeriksaanBumil(ibu.id),
                      builder: (context, pemSnap) {
                        final pemList = pemSnap.data ?? [];
                        if (pemList.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _emptyMsg('Belum ada data pemeriksaan.'),
                          );
                        }

                        return Column(
                          children: pemList.map((pem) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHistoryCard(
                                icon: Icons.medical_information_rounded,
                                title: 'Pemeriksaan Minggu ke-${pem.usiaKandunganMinggu}',
                                date: DateFormat('dd MMMM yyyy').format(pem.tanggalPeriksa),
                                subtitle: 'BB: ${pem.beratBadan} kg  •  TD: ${pem.tekananDarah}',
                                detail: pem.keluhan.isNotEmpty ? 'Keluhan: ${pem.keluhan}' : null,
                                colorType: Colors.pink.shade100,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  // ──────────── BALITA / ORANG TUA HISTORY ────────────
  Widget _buildBalitaHistory() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final db = DatabaseService();

    return FutureBuilder<OrangTuaModel?>(
      future: db.getOrangTuaByUserId(uid),
      builder: (context, otSnap) {
        if (otSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final ot = otSnap.data;
        if (ot == null) {
          return _emptyMsg('Data orang tua belum lengkap.');
        }

        return StreamBuilder<List<BalitaModel>>(
          stream: db.streamBalitaByOrangTua(ot.id),
          builder: (context, balitaSnap) {
            final balitaList = balitaSnap.data ?? [];
            if (balitaList.isEmpty) {
              return _emptyMsg('Belum ada data anak.');
            }

            return Column(
              children: balitaList.map((balita) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Child header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade200],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.child_care, color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Nama Anak:  ${balita.namaAnak}',
                            style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Imunisasi
                    StreamBuilder<List<RiwayatImunisasiModel>>(
                      stream: db.streamRiwayatImunisasi(balita.id),
                      builder: (context, imunSnap) {
                        final imunList = imunSnap.data ?? [];
                        return Column(
                          children: imunList.map((imun) {
                            return FutureBuilder<MasterImunisasiModel?>(
                              future: db.getMasterImunisasiById(imun.imunisasiId),
                              builder: (context, masterSnap) {
                                final nama = masterSnap.data?.namaImunisasi ?? 'Imunisasi';
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildHistoryCard(
                                    icon: Icons.vaccines,
                                    title: 'Imunisasi: $nama',
                                    date: DateFormat('dd MMMM yyyy').format(imun.tanggalDiberikan),
                                    subtitle: imun.keterangan.isNotEmpty ? imun.keterangan : 'Sudah diberikan',
                                    colorType: Colors.red.shade100,
                                  ), 
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),

                    // Pemeriksaan balita
                    StreamBuilder<List<PemeriksaanBalitaModel>>(
                      stream: db.streamPemeriksaanBalita(balita.id),
                      builder: (context, pemSnap) {
                        final pemList = pemSnap.data ?? [];
                        // Sort by usia descending
                        pemList.sort((a, b) => b.usiaSaatPeriksa.compareTo(a.usiaSaatPeriksa));
                        return Column(
                          children: pemList.map((pem) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildHistoryCard(
                                icon: Icons.monitor_weight_outlined,
                                title: 'Pemeriksaan Usia ${pem.usiaSaatPeriksa} bulan',
                                date: 'Status Gizi: ${pem.statusGizi}',
                                subtitle: 'BB: ${pem.beratBadan} kg  •  TB: ${pem.tinggiBadan} cm  •  LK: ${pem.lingkarKepala} cm',
                                detail: pem.indikasiStunting ? '⚠️ Indikasi Stunting' : null,
                                colorType: pem.indikasiStunting ? Colors.orange.shade100 : Colors.green.shade100,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),
            );
          },
        );
      },
    );
  }

  Widget _emptyMsg(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required String title,
    required String date,
    required String subtitle,
    String? detail,
    required Color colorType,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorType, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorType.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87,
                )),
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(date, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
                const SizedBox(height: 5),
                Text(subtitle, style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500,
                )),
                if (detail != null) ...[
                  const SizedBox(height: 4),
                  Text(detail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
