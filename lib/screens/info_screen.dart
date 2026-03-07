import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/database_service.dart';
import '../models/jadwal_posyandu_model.dart';
import '../models/user_model.dart';
import '../widgets/top_notification.dart';

class InfoScreen extends StatefulWidget {
  final String role;
  const InfoScreen({super.key, this.role = 'orang_tua'});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  bool get _isBumil => widget.role == 'ibu_hamil';

  List<Color> get _gradientColors => _isBumil
      ? [const Color(0xFFE91E63), const Color(0xFFF48FB1)]
      : [const Color(0xFF0288D1), const Color(0xFF81D4FA)];

  Color get _accentColor => _isBumil ? const Color(0xFFE91E63) : const Color(0xFF0288D1);

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
                  'Pusat Informasi',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _isBumil
                    ? 'Informasi Kehamilan & Jadwal Posyandu'
                    : 'Artikel Kesehatan, MPASI & Jadwal Posyandu',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Jadwal Terdekat from DB
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Jadwal Terdekat',
                    style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showSemuaJadwal(context),
                    style: TextButton.styleFrom(
                      foregroundColor: _accentColor,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lihat Semua', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_ios_rounded, size: 12),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildJadwalSection(),

              const SizedBox(height: 15),

              // Button: Buat Jadwal Konsultasi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showBuatJadwalDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Buat Jadwal ke Posyandu',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Hubungi Kader Section
              const Text(
                'Hubungi Kader / Bidan',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Konsultasi langsung via WhatsApp',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 15),
              _buildKaderContactList(),

              const SizedBox(height: 25),

              // Articles section
              const Text(
                'Artikel Terbaru',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),

              ..._buildArticles(),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────── JADWAL FROM DB ────────────
  Widget _buildJadwalSection() {
    return StreamBuilder<List<JadwalPosyanduModel>>(
      stream: DatabaseService().streamJadwalPosyandu(),
      builder: (context, snap) {
        final jadwalList = snap.data ?? [];
        // Filter upcoming jadwal
        final now = DateTime.now();
        final upcoming = jadwalList
            .where((j) => j.tanggalKegiatan.isAfter(now))
            .toList()
          ..sort((a, b) => a.tanggalKegiatan.compareTo(b.tanggalKegiatan));

        if (upcoming.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.event_busy, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada jadwal mendatang',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        final next = upcoming.first;
        return _buildEventCard(next);
      },
    );
  }

  Widget _buildEventCard(JadwalPosyanduModel jadwal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('dd').format(jadwal.tanggalKegiatan),
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
                  ),
                ),
                Text(
                  DateFormat('MMM').format(jadwal.tanggalKegiatan).toUpperCase(),
                  style: const TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jadwal.keterangan.isNotEmpty ? jadwal.keterangan : 'Posyandu',
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        jadwal.lokasi.isNotEmpty ? jadwal.lokasi : 'Lokasi belum ditentukan',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── SEMUA JADWAL ────────────
  void _showSemuaJadwal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Semua Jadwal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<JadwalPosyanduModel>>(
                  stream: DatabaseService().streamJadwalPosyandu(),
                  builder: (context, snap) {
                    final jadwalList = snap.data ?? [];
                    jadwalList.sort((a, b) =>
                        b.tanggalKegiatan.compareTo(a.tanggalKegiatan));

                    if (jadwalList.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_busy, size: 48, color: Colors.grey),
                            SizedBox(height: 12),
                            Text('Belum ada jadwal',
                                style: TextStyle(color: Colors.grey, fontSize: 15)),
                          ],
                        ),
                      );
                    }

                    final now = DateTime.now();
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      itemCount: jadwalList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final j = jadwalList[i];
                        final isPast = j.tanggalKegiatan.isBefore(now);
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isPast
                                ? Colors.grey.shade50
                                : _accentColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPast
                                  ? Colors.grey.shade200
                                  : _accentColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPast
                                      ? Colors.grey.shade200
                                      : _accentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('dd').format(j.tanggalKegiatan),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isPast ? Colors.grey : Colors.white,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM', 'id')
                                          .format(j.tanggalKegiatan)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isPast
                                            ? Colors.grey
                                            : Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
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
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isPast
                                            ? Colors.grey
                                            : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded,
                                            size: 13,
                                            color: isPast
                                                ? Colors.grey.shade400
                                                : _accentColor),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            j.lokasi.isNotEmpty
                                                ? j.lokasi
                                                : '-',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isPast
                                                  ? Colors.grey.shade400
                                                  : Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isPast)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Selesai',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                ),
                              if (!isPast && j.kaderNoHp != null && j.kaderNoHp!.isNotEmpty)
                                InkWell(
                                  onTap: () => _openWhatsApp(
                                      j.kaderNoHp!, j.kaderNama ?? 'Kader'),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.chat_rounded,
                                        color: Colors.green.shade600,
                                        size: 20),
                                  ),
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
        );
      },
    );
  }

  // ──────────── ARTICLES ────────────
  List<Widget> _buildArticles() {
    if (_isBumil) {
      return [
        _buildArticleCard(
          title: 'Panduan Nutrisi untuk Ibu Hamil Trimester 1-3',
          category: 'Gizi Kehamilan',
          readTime: '5 mnt baca',
          icon: Icons.restaurant_menu_rounded,
          colorType: Colors.pink.shade100,
        ),
        const SizedBox(height: 15),
        _buildArticleCard(
          title: 'Tanda Bahaya Kehamilan yang Harus Diwaspadai',
          category: 'Kesehatan Ibu',
          readTime: '4 mnt baca',
          icon: Icons.warning_amber_rounded,
          colorType: Colors.orange.shade100,
        ),
        const SizedBox(height: 15),
        _buildArticleCard(
          title: 'Persiapan Persalinan dan Menyusui',
          category: 'Persiapan Lahiran',
          readTime: '6 mnt baca',
          icon: Icons.child_friendly_rounded,
          colorType: Colors.purple.shade100,
        ),
        const SizedBox(height: 15),
        _buildArticleCard(
          title: 'Pentingnya Pemeriksaan ANC Rutin',
          category: 'Pemeriksaan',
          readTime: '3 mnt baca',
          icon: Icons.medical_services_rounded,
          colorType: Colors.teal.shade100,
        ),
        const SizedBox(height: 15),
        _buildArticleCard(
          title: 'Olahraga Ringan yang Aman untuk Ibu Hamil',
          category: 'Gaya Hidup',
          readTime: '4 mnt baca',
          icon: Icons.fitness_center_rounded,
          colorType: Colors.green.shade100,
        ),
      ];
    }

    // Default: orang_tua / balita articles
    return [
      _buildArticleCard(
        title: 'Panduan Pemberian MPASI untuk Usia 6 Bulan',
        category: 'Gizi & Nutrisi',
        readTime: '5 mnt baca',
        icon: Icons.restaurant_menu_rounded,
        colorType: Colors.orange.shade100,
      ),
      const SizedBox(height: 15),
      _buildArticleCard(
        title: 'Pentingnya Imunisasi Dasar Lengkap pada Bayi',
        category: 'Kesehatan Dasar',
        readTime: '4 mnt baca',
        icon: Icons.health_and_safety_rounded,
        colorType: Colors.blue.shade100,
      ),
      const SizedBox(height: 15),
      _buildArticleCard(
        title: 'Mengenal Tanda Gizi Buruk pada Anak Balita',
        category: 'Tumbuh Kembang',
        readTime: '6 mnt baca',
        icon: Icons.monitor_weight_rounded,
        colorType: Colors.green.shade100,
      ),
    ];
  }

  Widget _buildArticleCard({
    required String title,
    required String category,
    required String readTime,
    required IconData icon,
    required Color colorType,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
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
        children: [
          Container(
            height: 70, width: 70,
            decoration: BoxDecoration(
              color: colorType.withOpacity(0.3),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: Colors.black87, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(category, style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54,
                  )),
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87,
                ), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.menu_book_rounded, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(readTime, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────── KADER CONTACT LIST ────────────
  Widget _buildKaderContactList() {
    return StreamBuilder<List<UserModel>>(
      stream: DatabaseService().streamKaderUsers(),
      builder: (context, snapshot) {
        final kaderList = snapshot.data ?? [];
        if (kaderList.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              children: [
                Icon(Icons.people_outline, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text('Belum ada data kader/bidan',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          );
        }

        return Column(
          children: kaderList.map((kader) {
            final nama = kader.namaPanggilan ?? kader.email;
            final phone = kader.noHp ?? '';

            ImageProvider? avatarImage;
            if (kader.photoBase64 != null && kader.photoBase64!.isNotEmpty) {
              avatarImage = MemoryImage(base64Decode(kader.photoBase64!));
            } else if (kader.photoUrl != null && kader.photoUrl!.isNotEmpty) {
              avatarImage = NetworkImage(kader.photoUrl!);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.blue.shade100,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? Icon(Icons.people_rounded,
                            color: Colors.blue, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kader Posyandu',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (phone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (phone.isNotEmpty) ...[
                    // WhatsApp button
                    InkWell(
                      onTap: () => _openWhatsApp(phone, nama),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.chat_rounded,
                            color: Colors.green.shade600, size: 22),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Phone button
                    InkWell(
                      onTap: () => _makePhoneCall(phone),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.phone_rounded,
                            color: Colors.blue.shade600, size: 22),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _openWhatsApp(String phone, String nama) async {
    String normalized = phone.trim();
    if (normalized.startsWith('0')) {
      normalized = '62${normalized.substring(1)}';
    }
    final uri = Uri.parse(
        'https://wa.me/$normalized?text=${Uri.encodeComponent('Halo $nama, saya ingin konsultasi.')}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _makePhoneCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ──────────── BUAT JADWAL DIALOG ────────────
  void _showBuatJadwalDialog(BuildContext context) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    UserModel? selectedBidan;
    final keteranganController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
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
                    const SizedBox(height: 20),
                    Text(
                      'Buat Jadwal ke Posyandu',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Pick Date
                    const Text('Pilih Tanggal',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate:
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 90)),
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                              colorScheme: ColorScheme.light(
                                  primary: _accentColor),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => selectedDate = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: _accentColor, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              selectedDate != null
                                  ? DateFormat('EEEE, dd MMMM yyyy', 'id')
                                      .format(selectedDate!)
                                  : 'Pilih tanggal...',
                              style: TextStyle(
                                color: selectedDate != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pick Time
                    const Text('Pilih Jam',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime:
                              const TimeOfDay(hour: 8, minute: 0),
                          builder: (c, child) => Theme(
                            data: Theme.of(c).copyWith(
                              colorScheme: ColorScheme.light(
                                  primary: _accentColor),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) {
                          setModalState(() => selectedTime = picked);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_rounded,
                                color: _accentColor, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              selectedTime != null
                                  ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')} WIB'
                                  : 'Pilih jam...',
                              style: TextStyle(
                                color: selectedTime != null
                                    ? Colors.black87
                                    : Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Pick Bidan
                    const Text('Pilih Bidan / Kader',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    StreamBuilder<List<UserModel>>(
                      stream: DatabaseService().streamKaderUsers(),
                      builder: (context, snap) {
                        final list = snap.data ?? [];
                        if (list.isEmpty) {
                          return const Text('Belum ada data bidan/kader',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 13));
                        }
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<UserModel>(
                              value: selectedBidan,
                              isExpanded: true,
                              hint: const Text('Pilih bidan/kader...',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14)),
                              items: list.map((k) {
                                return DropdownMenuItem(
                                  value: k,
                                  child: Text(
                                    k.namaPanggilan ?? k.email,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setModalState(() => selectedBidan = val);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Keterangan
                    const Text('Keterangan (opsional)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: keteranganController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Konsultasi tumbuh kembang anak',
                        hintStyle:
                            TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedDate == null) {
                            TopNotification.show(ctx, 'Pilih tanggal terlebih dahulu', isError: true);
                            return;
                          }
                          if (selectedTime == null) {
                            TopNotification.show(ctx, 'Pilih jam terlebih dahulu', isError: true);
                            return;
                          }
                          if (selectedBidan == null) {
                            TopNotification.show(ctx, 'Pilih bidan/kader terlebih dahulu', isError: true);
                            return;
                          }

                          final jadwalDateTime = DateTime(
                            selectedDate!.year,
                            selectedDate!.month,
                            selectedDate!.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );

                          final bidanNama = selectedBidan!.namaPanggilan ?? selectedBidan!.email;
                          final bidanInfo = bidanNama;
                          final waktu =
                              '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')} WIB';
                          final ket = keteranganController.text.trim();
                          final fullKeterangan =
                              'Konsultasi dengan $bidanInfo jam $waktu${ket.isNotEmpty ? ' - $ket' : ''}';

                          final jadwal = JadwalPosyanduModel(
                            id: '',
                            tanggalKegiatan: jadwalDateTime,
                            lokasi: 'Posyandu Ciguruwik',
                            keterangan: fullKeterangan,
                            kaderNama: bidanNama,
                            kaderNoHp: selectedBidan!.noHp,
                          );

                          try {
                            await DatabaseService().saveJadwalPosyandu(jadwal);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              TopNotification.show(
                                context,
                                'Jadwal berhasil dibuat!',
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              TopNotification.show(
                                ctx,
                                'Gagal membuat jadwal: $e',
                                isError: true,
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Simpan Jadwal',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
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
}