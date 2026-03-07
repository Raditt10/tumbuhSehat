import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/balita_model.dart';
import 'balita_detail_screen.dart';

class BalitaListScreen extends StatelessWidget {
  final String orangTuaId;
  const BalitaListScreen({super.key, required this.orangTuaId});

  @override
  Widget build(BuildContext context) {
    const Color bgBiruMuda = Color(0xFFF5F9FD);
    const Color primaryBlue = Color(0xFF0288D1);

    return Scaffold(
      backgroundColor: bgBiruMuda,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Daftar Anak Saya',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<BalitaModel>>(
        stream: DatabaseService().streamBalitaByOrangTua(orangTuaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final balitaList = snapshot.data ?? [];

          if (balitaList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.child_care_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada data anak',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: balitaList.length,
            itemBuilder: (context, index) {
              final balita = balitaList[index];
              final age = _calculateAge(balita.tanggalLahir);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: balita.jenisKelamin == 'L'
                          ? Colors.blue.shade50
                          : Colors.pink.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      balita.jenisKelamin == 'L'
                          ? Icons.boy_rounded
                          : Icons.girl_rounded,
                      color: balita.jenisKelamin == 'L'
                          ? Colors.blue
                          : Colors.pink,
                      size: 36,
                    ),
                  ),
                  title: Text(
                    balita.namaAnak,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        'NIK: ${balita.nikAnak}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Usia: $age',
                        style: const TextStyle(
                          color: primaryBlue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    // Navigate to individual KMS detail
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BalitaDetailScreen(data: balita),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;

    if (months < 0) {
      years--;
      months += 12;
    }

    if (years > 0) {
      return '$years tahun $months bulan';
    } else {
      return '$months bulan';
    }
  }
}
