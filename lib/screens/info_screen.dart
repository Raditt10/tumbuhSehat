import 'package:flutter/material.dart';

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
