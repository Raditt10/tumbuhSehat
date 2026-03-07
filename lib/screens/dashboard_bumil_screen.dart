import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/user_model.dart';
import '../models/orang_tua_model.dart';
import '../models/ibu_hamil_model.dart';
import '../models/pemeriksaan_bumil_model.dart';
import 'package:intl/intl.dart';

class DashboardBumilScreen extends StatefulWidget {
  const DashboardBumilScreen({super.key});

  @override
  State<DashboardBumilScreen> createState() => _DashboardBumilScreenState();
}

class _DashboardBumilScreenState extends State<DashboardBumilScreen> {
  final _db = DatabaseService();
  late final Future<OrangTuaModel?> _orangTuaFuture;
  late final Future<UserModel?> _userFuture;

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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    _orangTuaFuture = _db.getOrangTuaByUserId(uid);
    _userFuture = _db.getUserData(uid);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      body: SafeArea(
        child: FutureBuilder<OrangTuaModel?>(
          future: _orangTuaFuture,
          builder: (context, otSnap) {
            if (otSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final orangTua = otSnap.data;
            if (orangTua == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Data orang tua belum lengkap.\nSilakan lengkapi di menu Profil.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              );
            }

            return StreamBuilder<List<IbuHamilModel>>(
              stream: _db.streamIbuHamilByOrangTua(orangTua.id),
              builder: (context, ibuSnap) {
                final ibuHamilList = ibuSnap.data ?? [];

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Bar: Logo + Notification
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 48,
                          ),
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
                      const SizedBox(height: 25),

                      // Greeting
                      FutureBuilder<UserModel?>(
                        future: _userFuture,
                        builder: (context, snapshot) {
                          final greeting = _getTimeGreeting();
                          final name = snapshot.data?.namaPanggilan ?? orangTua.namaIbu;
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
                            Color(0xFFE91E63),
                            Color(0xFFF48FB1),
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
                      const SizedBox(height: 24),

                      if (ibuHamilList.isEmpty) ...[
                        _buildEmptyState(),
                      ] else ...[
                        for (final ibuHamil in ibuHamilList)
                          _buildIbuHamilSection(ibuHamil),
                      ],

                      const SizedBox(height: 20),
                      // Add kehamilan button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _showIbuHamilForm(context, orangTua.id, null),
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Data Kehamilan'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.pink.shade400,
                            side: BorderSide(color: Colors.pink.shade200),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
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
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.baby_changing_station, size: 64, color: Colors.pink.shade100),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data kehamilan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan data kehamilan untuk memulai pemantauan.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildIbuHamilSection(IbuHamilModel ibuHamil) {
    final now = DateTime.now();
    final usiaKandunganHari = now.difference(ibuHamil.hpht).inDays;
    final usiaKandunganMinggu = (usiaKandunganHari / 7).floor();
    final sisaHari = ibuHamil.hpl.difference(now).inDays;
    final df = DateFormat('dd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pregnancy info card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink.shade300, Colors.pink.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kehamilan ke-${ibuHamil.kehamilanKe}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  PopupMenuButton<String>(
                    iconColor: Colors.white,
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showIbuHamilForm(context, ibuHamil.orangTuaId, ibuHamil);
                      } else if (val == 'delete') {
                        _confirmDelete(context, ibuHamil.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoChip(Icons.calendar_today, 'HPHT', df.format(ibuHamil.hpht)),
                  const SizedBox(width: 12),
                  _infoChip(Icons.child_care, 'HPL', df.format(ibuHamil.hpl)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoPill('Usia: $usiaKandunganMinggu minggu'),
                  const SizedBox(width: 8),
                  _infoPill(sisaHari > 0
                      ? 'Sisa $sisaHari hari'
                      : 'Sudah melewati HPL'),
                ],
              ),
              if (ibuHamil.riwayatPenyakit.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Riwayat: ${ibuHamil.riwayatPenyakit}',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pemeriksaan section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Riwayat Pemeriksaan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => _showPemeriksaanForm(context, ibuHamil.id, null),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah'),
              style: TextButton.styleFrom(foregroundColor: Colors.pink.shade400),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<PemeriksaanBumilModel>>(
          stream: _db.streamPemeriksaanBumil(ibuHamil.id),
          builder: (context, pemSnap) {
            final pemList = pemSnap.data ?? [];
            if (pemList.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  'Belum ada data pemeriksaan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              );
            }

            final sorted = List<PemeriksaanBumilModel>.from(pemList)
              ..sort((a, b) => b.tanggalPeriksa.compareTo(a.tanggalPeriksa));

            return Column(
              children: sorted.map((pem) => _buildPemeriksaanCard(pem)).toList(),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPemeriksaanCard(PemeriksaanBumilModel pem) {
    final df = DateFormat('dd MMM yyyy');
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.pink.shade50),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                df.format(pem.tanggalPeriksa),
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.pink.shade400),
              ),
              Row(
                children: [
                  Text('Minggu ke-${pem.usiaKandunganMinggu}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 4),
                  PopupMenuButton<String>(
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'edit') {
                        _showPemeriksaanForm(context, pem.ibuHamilId, pem);
                      } else if (val == 'delete') {
                        _db.deletePemeriksaanBumil(pem.id);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _dataBadge('BB', '${pem.beratBadan} kg'),
              _dataBadge('TD', pem.tekananDarah),
              _dataBadge('LILA', '${pem.lingkarLenganAtas} cm'),
            ],
          ),
          if (pem.keluhan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Keluhan: ${pem.keluhan}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }

  Widget _dataBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: TextStyle(fontSize: 12, color: Colors.pink.shade700)),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 10, color: Colors.white70)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  void _confirmDelete(BuildContext ctx, String id) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Data Kehamilan?'),
        content: const Text('Data kehamilan dan pemeriksaan terkait akan dihapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              _db.deleteIbuHamil(id);
              Navigator.pop(ctx);
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }

  void _showIbuHamilForm(BuildContext ctx, String orangTuaId, IbuHamilModel? existing) {
    final hphtCtrl = TextEditingController(
        text: existing != null
            ? DateFormat('dd/MM/yyyy').format(existing.hpht)
            : '');
    final hplCtrl = TextEditingController(
        text: existing != null
            ? DateFormat('dd/MM/yyyy').format(existing.hpl)
            : '');
    final kehamilanCtrl = TextEditingController(
        text: existing?.kehamilanKe.toString() ?? '1');
    final riwayatCtrl =
        TextEditingController(text: existing?.riwayatPenyakit ?? '');

    DateTime? selectedHpht = existing?.hpht;
    DateTime? selectedHpl = existing?.hpl;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existing == null ? 'Tambah Data Kehamilan' : 'Edit Data Kehamilan',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _dateField('HPHT (Hari Pertama Haid Terakhir)', hphtCtrl, (date) {
                  setStateSheet(() {
                    selectedHpht = date;
                    hphtCtrl.text = DateFormat('dd/MM/yyyy').format(date);
                    // Auto-calculate HPL (Naegele's rule: +7 days, -3 months, +1 year)
                    final hpl = DateTime(date.year + 1, date.month - 3, date.day + 7);
                    selectedHpl = hpl;
                    hplCtrl.text = DateFormat('dd/MM/yyyy').format(hpl);
                  });
                }),
                const SizedBox(height: 12),
                _dateField('HPL (Hari Perkiraan Lahir)', hplCtrl, (date) {
                  setStateSheet(() {
                    selectedHpl = date;
                    hplCtrl.text = DateFormat('dd/MM/yyyy').format(date);
                  });
                }),
                const SizedBox(height: 12),
                _textField('Kehamilan Ke', kehamilanCtrl, TextInputType.number),
                const SizedBox(height: 12),
                _textField('Riwayat Penyakit (opsional)', riwayatCtrl, TextInputType.text),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedHpht == null || selectedHpl == null) return;
                      final data = IbuHamilModel(
                        id: existing?.id ?? '',
                        orangTuaId: orangTuaId,
                        hpht: selectedHpht!,
                        hpl: selectedHpl!,
                        kehamilanKe: int.tryParse(kehamilanCtrl.text) ?? 1,
                        riwayatPenyakit: riwayatCtrl.text,
                      );
                      _db.saveIbuHamil(data);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(existing == null ? 'Simpan' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPemeriksaanForm(
      BuildContext ctx, String ibuHamilId, PemeriksaanBumilModel? existing) {
    final tglCtrl = TextEditingController(
        text: existing != null
            ? DateFormat('dd/MM/yyyy').format(existing.tanggalPeriksa)
            : '');
    final usiaCtrl = TextEditingController(
        text: existing?.usiaKandunganMinggu.toString() ?? '');
    final bbCtrl = TextEditingController(
        text: existing?.beratBadan.toString() ?? '');
    final tdCtrl = TextEditingController(text: existing?.tekananDarah ?? '');
    final lilaCtrl = TextEditingController(
        text: existing?.lingkarLenganAtas.toString() ?? '');
    final keluhanCtrl = TextEditingController(text: existing?.keluhan ?? '');

    DateTime? selectedDate = existing?.tanggalPeriksa;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) => Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  existing == null ? 'Tambah Pemeriksaan' : 'Edit Pemeriksaan',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _dateField('Tanggal Periksa', tglCtrl, (date) {
                  setStateSheet(() {
                    selectedDate = date;
                    tglCtrl.text = DateFormat('dd/MM/yyyy').format(date);
                  });
                }),
                const SizedBox(height: 12),
                _textField('Usia Kandungan (minggu)', usiaCtrl, TextInputType.number),
                const SizedBox(height: 12),
                _textField('Berat Badan (kg)', bbCtrl,
                    const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField('Tekanan Darah (mis: 120/80)', tdCtrl, TextInputType.text),
                const SizedBox(height: 12),
                _textField('LILA / Lingkar Lengan Atas (cm)', lilaCtrl,
                    const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 12),
                _textField('Keluhan (opsional)', keluhanCtrl, TextInputType.text),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (selectedDate == null) return;
                      final data = PemeriksaanBumilModel(
                        id: existing?.id ?? '',
                        ibuHamilId: ibuHamilId,
                        tanggalPeriksa: selectedDate!,
                        usiaKandunganMinggu: int.tryParse(usiaCtrl.text) ?? 0,
                        beratBadan: double.tryParse(bbCtrl.text) ?? 0,
                        tekananDarah: tdCtrl.text,
                        lingkarLenganAtas: double.tryParse(lilaCtrl.text) ?? 0,
                        keluhan: keluhanCtrl.text,
                      );
                      if (existing == null) {
                        _db.addPemeriksaanBumil(data);
                      } else {
                        _db.updatePemeriksaanBumil(data);
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(existing == null ? 'Simpan' : 'Update'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String label, TextEditingController ctrl, TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dateField(String label, TextEditingController ctrl, Function(DateTime) onPicked) {
    return TextField(
      controller: ctrl,
      readOnly: true,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date != null) onPicked(date);
      },
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
