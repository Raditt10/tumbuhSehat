import 'package:flutter/material.dart';

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
