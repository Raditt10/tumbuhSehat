import 'package:flutter/material.dart';
import '../models/balita_model.dart';
import '../models/pemeriksaan_balita_model.dart';
import '../services/database_service.dart';
import 'balita_form_screen.dart';

class BalitaDetailScreen extends StatefulWidget {
  final BalitaModel data;

  const BalitaDetailScreen({super.key, required this.data});

  @override
  State<BalitaDetailScreen> createState() => _BalitaDetailScreenState();
}

class _BalitaDetailScreenState extends State<BalitaDetailScreen> {
  late BalitaModel _currentData;

  @override
  void initState() {
    super.initState();
    _currentData = widget.data;
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF0288D1);
    const Color bgBiruMuda = Color(0xFFF5F9FD);

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
          'Detail Data Anak',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: primaryBlue),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BalitaFormScreen(existingData: _currentData),
                ),
              );

              if (result == true) {
                // Return to profile or list to force reload if edited
                if (mounted) Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderRow(
                    'Informasi Pribadi',
                    Icons.person_rounded,
                    primaryBlue,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Nama Anak', _currentData.namaAnak),
                  const SizedBox(height: 12),
                  _buildDetailItem('NIK Anak', _currentData.nikAnak),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Jenis Kelamin',
                    _currentData.jenisKelamin == 'L'
                        ? 'Laki-laki'
                        : 'Perempuan',
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  _buildHeaderRow(
                    'Kelahiran',
                    Icons.child_friendly_rounded,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Tempat Lahir', _currentData.tempatLahir),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'Tanggal Lahir',
                    '${_currentData.tanggalLahir.day}/${_currentData.tanggalLahir.month}/${_currentData.tanggalLahir.year}',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem('Anak Ke', _currentData.anakKe.toString()),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  _buildHeaderRow(
                    'Data Saat Lahir',
                    Icons.straighten_rounded,
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Berat Lahir',
                          '${_currentData.beratLahir} kg',
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'Tinggi Lahir',
                          '${_currentData.tinggiLahir} cm',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Latest Pemeriksaan Section
            _buildLatestPemeriksaan(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLatestPemeriksaan() {
    return StreamBuilder<List<PemeriksaanBalitaModel>>(
      stream: DatabaseService().streamPemeriksaanBalita(_currentData.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final pemList = snapshot.data ?? [];
        if (pemList.isEmpty) {
          return const SizedBox.shrink();
        }

        final sorted = List<PemeriksaanBalitaModel>.from(pemList)
          ..sort((a, b) => b.usiaSaatPeriksa.compareTo(a.usiaSaatPeriksa));
        final latest = sorted.first;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderRow(
                'Pemeriksaan Terakhir',
                Icons.monitor_weight_outlined,
                Colors.blue,
              ),
              const SizedBox(height: 6),
              Text(
                'Usia ${latest.usiaSaatPeriksa} bulan',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Berat Badan',
                      '${latest.beratBadan} kg',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Tinggi Badan',
                      '${latest.tinggiBadan} cm',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      'Lingkar Kepala',
                      '${latest.lingkarKepala} cm',
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      'Status Gizi',
                      latest.statusGizi,
                    ),
                  ),
                ],
              ),
              if (latest.indikasiStunting) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Indikasi Stunting',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : '-',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
