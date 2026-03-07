import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/balita_model.dart';
import '../models/orang_tua_model.dart';
import '../models/ibu_hamil_model.dart';
import '../models/pemeriksaan_balita_model.dart';
import '../models/jadwal_posyandu_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class DashboardKaderScreen extends StatefulWidget {
  const DashboardKaderScreen({super.key});

  @override
  State<DashboardKaderScreen> createState() => _DashboardKaderScreenState();
}

class _DashboardKaderScreenState extends State<DashboardKaderScreen> {
  final _db = DatabaseService();
  late final Future<UserModel?> _userFuture;

  static const Color _primary = Color(0xFF0288D1);
  static const Color _primaryLight = Color(0xFF4FC3F7);
  static const Color _bg = Color(0xFFF5F9FD);

  String _getTimeGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  void initState() {
    super.initState();
    _userFuture = _db.getUserData(
        FirebaseAuth.instance.currentUser?.uid ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 20, right: 20, top: 10, bottom: 100,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── TOP BAR (same as KMS) ───
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

              // ─── GREETING ───
              FutureBuilder<UserModel?>(
                future: _userFuture,
                builder: (context, snap) {
                  final name = snap.data?.namaPanggilan ?? 'Kader';
                  return Text(
                    '${_getTimeGreeting()}, $name!',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  );
                },
              ),
              const SizedBox(height: 5),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF0288D1), Color(0xFF81D4FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'Panel Kader',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Kelola data posyandu & pemantauan warga',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 25),

              // ─── STATISTIK RINGKAS ───
              _buildStatSection(),
              const SizedBox(height: 25),

              // ─── MENU MANAGEMENT ───
              const Text('Menu Pengelolaan',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 15),
              _buildMenuGrid(),
              const SizedBox(height: 25),

              // ─── JADWAL TERDEKAT ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jadwal Terdekat',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  TextButton.icon(
                    onPressed: () => _showJadwalManagement(),
                    icon: const Icon(Icons.calendar_month_rounded, size: 16),
                    label: const Text('Kelola',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(foregroundColor: _primary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildJadwalTerdekat(),
              const SizedBox(height: 25),

              // ─── AKTIVITAS TERBARU ───
              const Text('Pemeriksaan Terbaru',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const SizedBox(height: 10),
              _buildRecentPemeriksaan(),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STAT CARDS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStatSection() {
    return StreamBuilder<List<BalitaModel>>(
      stream: _db.streamAllBalita(),
      builder: (context, balitaSnap) {
        return StreamBuilder<List<IbuHamilModel>>(
          stream: _db.streamAllIbuHamil(),
          builder: (context, bumilSnap) {
            return StreamBuilder<List<OrangTuaModel>>(
              stream: _db.streamAllOrangTua(),
              builder: (context, otSnap) {
                return StreamBuilder<List<UserModel>>(
                  stream: _db.streamKaderUsers(),
                  builder: (context, kaderSnap) {
                    final totalBalita = balitaSnap.data?.length ?? 0;
                    final totalBumil = bumilSnap.data?.length ?? 0;
                    final totalOT = otSnap.data?.length ?? 0;
                    final totalKader = kaderSnap.data?.length ?? 0;

                    return Column(
                      children: [
                        Row(children: [
                          _statCard('Balita', '$totalBalita',
                              Icons.child_care_rounded, Colors.blue),
                          const SizedBox(width: 12),
                          _statCard('Ibu Hamil', '$totalBumil',
                              Icons.pregnant_woman_rounded, Colors.pink),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          _statCard('Orang Tua', '$totalOT',
                              Icons.family_restroom_rounded, Colors.teal),
                          const SizedBox(width: 12),
                          _statCard('Kader', '$totalKader',
                              Icons.people_rounded, Colors.orange),
                        ]),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _statCard(
      String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(count,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MENU GRID
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMenuGrid() {
    final menus = [
      _MenuData('Data Balita', Icons.child_care_rounded, Colors.blue,
          () => _showDataBalita()),
      _MenuData('Data Ibu Hamil', Icons.pregnant_woman_rounded, Colors.pink,
          () => _showDataBumil()),
      _MenuData('Kelola Jadwal', Icons.calendar_month_rounded, _primary,
          () => _showJadwalManagement()),
      _MenuData('Akun Orang Tua', Icons.person_outline_rounded, Colors.teal,
          () => _showUserManagement('orang_tua')),
      _MenuData(
          'Akun Ibu Hamil', Icons.person_outline_rounded, Colors.deepOrange,
          () => _showUserManagement('ibu_hamil')),
      _MenuData('Akun Kader', Icons.admin_panel_settings_rounded, Colors.orange,
          () => _showUserManagement('kader')),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.9,
      ),
      itemCount: menus.length,
      itemBuilder: (ctx, i) {
        final m = menus[i];
        return InkWell(
          onTap: m.onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: m.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(m.icon, color: m.color, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  m.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // JADWAL TERDEKAT (inline – max 3)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildJadwalTerdekat() {
    return StreamBuilder<List<JadwalPosyanduModel>>(
      stream: _db.streamJadwalPosyandu(),
      builder: (context, snap) {
        final list = snap.data ?? [];
        final now = DateTime.now();
        final upcoming = list
            .where(
                (j) => j.tanggalKegiatan.isAfter(now.subtract(const Duration(days: 1))))
            .toList()
          ..sort((a, b) => a.tanggalKegiatan.compareTo(b.tanggalKegiatan));

        if (upcoming.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              Icon(Icons.event_busy_rounded,
                  size: 36, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text('Belum ada jadwal mendatang',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
            ]),
          );
        }

        return Column(
          children: upcoming.take(3).map((j) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _primaryLight.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(children: [
                      Text(DateFormat('dd').format(j.tanggalKegiatan),
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Text(
                          DateFormat('MMM', 'id')
                              .format(j.tanggalKegiatan)
                              .toUpperCase(),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white70)),
                    ]),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            j.keterangan.isNotEmpty
                                ? j.keterangan
                                : 'Posyandu',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                                j.lokasi.isNotEmpty ? j.lokasi : '-',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RECENT PEMERIKSAAN
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildRecentPemeriksaan() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pemeriksaan_balita')
          .orderBy('tanggal_periksa', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18)),
            child: Text('Belum ada pemeriksaan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500)),
          );
        }

        return Column(
          children: snap.data!.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;
            final berat = d['berat_badan'] ?? '-';
            final tinggi = d['tinggi_badan'] ?? '-';
            final status = d['status_gizi'] ?? '';
            final tgl = (d['tanggal_periksa'] as Timestamp?)?.toDate();
            final tglStr =
                tgl != null ? DateFormat('dd MMM yy', 'id').format(tgl) : '-';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.monitor_weight_outlined,
                        color: Colors.blue.shade400, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BB: $berat kg  •  TB: $tinggi cm',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text(tglStr,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: status.toLowerCase().contains('kurus') ||
                              status.toLowerCase().contains('stunting')
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status.isNotEmpty ? status : '-',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: status.toLowerCase().contains('kurus') ||
                                status.toLowerCase().contains('stunting')
                            ? Colors.red.shade600
                            : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MENU: DATA BALITA (bottom sheet)
  // ═══════════════════════════════════════════════════════════════════════════
  void _showDataBalita() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _sheetHeader('Data Balita', ctx),
            Expanded(
              child: StreamBuilder<List<BalitaModel>>(
                stream: _db.streamAllBalita(),
                builder: (context, snap) {
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return const Center(
                        child: Text('Belum ada data balita.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _balitaCard(list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balitaCard(BalitaModel balita) {
    final ageMonths =
        DateTime.now().difference(balita.tanggalLahir).inDays ~/ 30;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: balita.jenisKelamin == 'L'
                  ? Colors.blue.shade50
                  : Colors.pink.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.child_care,
                color: balita.jenisKelamin == 'L'
                    ? Colors.blue.shade400
                    : Colors.pink.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(balita.namaAnak,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                Text(
                  '${balita.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'} • $ageMonths bulan',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          StreamBuilder<List<PemeriksaanBalitaModel>>(
            stream: _db.streamPemeriksaanBalita(balita.id),
            builder: (context, pemSnap) {
              final pemList = pemSnap.data ?? [];
              if (pemList.isEmpty) {
                return Text('Belum periksa',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400));
              }
              final sorted =
                  List<PemeriksaanBalitaModel>.from(pemList)
                    ..sort((a, b) =>
                        b.usiaSaatPeriksa.compareTo(a.usiaSaatPeriksa));
              final last = sorted.first;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${last.beratBadan} kg',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(last.statusGizi,
                      style: TextStyle(
                        fontSize: 11,
                        color: last.statusGizi
                                    .toLowerCase()
                                    .contains('kurus') ||
                                last.indikasiStunting
                            ? Colors.red.shade400
                            : Colors.green.shade600,
                      )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MENU: DATA BUMIL (bottom sheet)
  // ═══════════════════════════════════════════════════════════════════════════
  void _showDataBumil() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _sheetHeader('Data Ibu Hamil', ctx),
            Expanded(
              child: StreamBuilder<List<IbuHamilModel>>(
                stream: _db.streamAllIbuHamil(),
                builder: (context, snap) {
                  final list = snap.data ?? [];
                  if (list.isEmpty) {
                    return const Center(
                        child: Text('Belum ada data ibu hamil.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _bumilCard(list[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bumilCard(IbuHamilModel bumil) {
    final now = DateTime.now();
    final usiaMinggu = (now.difference(bumil.hpht).inDays / 7).floor();
    final sisaHari = bumil.hpl.difference(now).inDays;

    return FutureBuilder<OrangTuaModel?>(
      future: _getOrangTuaById(bumil.orangTuaId),
      builder: (context, otSnap) {
        final namaIbu = otSnap.data?.namaIbu ?? '-';
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.pregnant_woman,
                    color: Colors.pink.shade400),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(namaIbu,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(
                      'Kehamilan ke-${bumil.kehamilanKe} • $usiaMinggu minggu',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                sisaHari > 0 ? '$sisaHari hari' : 'Lewat HPL',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sisaHari > 0
                        ? Colors.pink.shade400
                        : Colors.red.shade400),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<OrangTuaModel?> _getOrangTuaById(String orangTuaId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orang_tua')
          .doc(orangTuaId)
          .get();
      if (doc.exists) {
        return OrangTuaModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {}
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MENU: KELOLA JADWAL (full bottom sheet with CRUD)
  // ═══════════════════════════════════════════════════════════════════════════
  void _showJadwalManagement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _sheetHeader('Kelola Jadwal Posyandu', ctx),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showJadwalForm(null);
                  },
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah Jadwal'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<JadwalPosyanduModel>>(
                stream: _db.streamJadwalPosyandu(),
                builder: (context, snap) {
                  final list = snap.data ?? [];
                  final sorted = List<JadwalPosyanduModel>.from(list)
                    ..sort((a, b) =>
                        b.tanggalKegiatan.compareTo(a.tanggalKegiatan));
                  if (sorted.isEmpty) {
                    return const Center(
                        child: Text('Belum ada jadwal.'));
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: sorted.length,
                    itemBuilder: (ctx, i) {
                      final j = sorted[i];
                      final isPast =
                          j.tanggalKegiatan.isBefore(DateTime.now());
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isPast ? Colors.grey.shade50 : _bg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8),
                              decoration: BoxDecoration(
                                color: isPast
                                    ? Colors.grey.shade200
                                    : _primary,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Column(children: [
                                Text(
                                    DateFormat('dd')
                                        .format(j.tanggalKegiatan),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isPast
                                            ? Colors.grey
                                            : Colors.white)),
                                Text(
                                    DateFormat('MMM', 'id')
                                        .format(j.tanggalKegiatan)
                                        .toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isPast
                                            ? Colors.grey
                                            : Colors.white70)),
                              ]),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      j.keterangan.isNotEmpty
                                          ? j.keterangan
                                          : 'Posyandu',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isPast
                                              ? Colors.grey
                                              : Colors.black87),
                                      maxLines: 2,
                                      overflow:
                                          TextOverflow.ellipsis),
                                  Text(j.lokasi,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              Colors.grey.shade500)),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              iconSize: 20,
                              onSelected: (val) {
                                if (val == 'edit') {
                                  Navigator.pop(ctx);
                                  _showJadwalForm(j);
                                } else if (val == 'delete') {
                                  _db.deleteJadwalPosyandu(j.id);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit')),
                                const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Hapus',
                                        style: TextStyle(
                                            color: Colors.red))),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showJadwalForm(JadwalPosyanduModel? existing) {
    final tglCtrl = TextEditingController(
        text: existing != null
            ? DateFormat('dd/MM/yyyy').format(existing.tanggalKegiatan)
            : '');
    final lokasiCtrl =
        TextEditingController(text: existing?.lokasi ?? '');
    final ketCtrl =
        TextEditingController(text: existing?.keterangan ?? '');
    DateTime? selectedDate = existing?.tanggalKegiatan;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 16),
                Text(
                  existing == null ? 'Tambah Jadwal' : 'Edit Jadwal',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tglCtrl,
                  readOnly: true,
                  onTap: () async {
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setStateSheet(() {
                        selectedDate = date;
                        tglCtrl.text =
                            DateFormat('dd/MM/yyyy').format(date);
                      });
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Tanggal Kegiatan',
                    suffixIcon:
                        const Icon(Icons.calendar_today, size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lokasiCtrl,
                  decoration: InputDecoration(
                    labelText: 'Lokasi',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ketCtrl,
                  decoration: InputDecoration(
                    labelText: 'Keterangan',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedDate == null ||
                          lokasiCtrl.text.isEmpty) return;
                      final data = JadwalPosyanduModel(
                        id: existing?.id ?? '',
                        tanggalKegiatan: selectedDate!,
                        lokasi: lokasiCtrl.text,
                        keterangan: ketCtrl.text,
                      );
                      _db.saveJadwalPosyandu(data);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(
                        existing == null ? 'Simpan' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MENU: KELOLA AKUN USER
  // ═══════════════════════════════════════════════════════════════════════════
  void _showUserManagement(String role) {
    final roleLabel = role == 'orang_tua'
        ? 'Orang Tua'
        : role == 'ibu_hamil'
            ? 'Ibu Hamil'
            : 'Kader';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            _sheetHeader('Akun $roleLabel', ctx),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: role)
                    .snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return Center(
                        child: Text('Belum ada akun $roleLabel.',
                            style: const TextStyle(color: Colors.grey)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) {
                      final user = UserModel.fromMap(
                          docs[i].data() as Map<String, dynamic>,
                          docs[i].id);
                      return _userCard(user, roleLabel);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(UserModel user, String roleLabel) {
    ImageProvider? avatar;
    if (user.photoBase64 != null && user.photoBase64!.isNotEmpty) {
      try {
        avatar = MemoryImage(base64Decode(user.photoBase64!));
      } catch (_) {}
    } else if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      avatar = NetworkImage(user.photoUrl!);
    }

    final createdStr = user.createdAt != null
        ? DateFormat('dd MMM yyyy', 'id').format(user.createdAt!)
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blue.shade50,
            backgroundImage: avatar,
            child: avatar == null
                ? Icon(Icons.person, color: Colors.blue.shade300, size: 22)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.namaPanggilan ?? 'Tanpa Nama',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(user.email,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500)),
                Text('Bergabung: $createdStr',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          if (user.noHp != null && user.noHp!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone, size: 12, color: Colors.green.shade600),
                  const SizedBox(width: 4),
                  Text(user.noHp!,
                      style: TextStyle(
                          fontSize: 11, color: Colors.green.shade700)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _sheetHeader(String title, BuildContext ctx) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primary)),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuData {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _MenuData(this.label, this.icon, this.color, this.onTap);
}
