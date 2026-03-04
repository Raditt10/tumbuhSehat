import 'package:flutter/material.dart';

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
