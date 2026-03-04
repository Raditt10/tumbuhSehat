import 'package:flutter/material.dart';

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
                  const Color(0xFFFFF59D), // Yellow
                ),
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
