import 'package:flutter/material.dart';
import '../models/orang_tua_model.dart';
import 'orang_tua_form_screen.dart';

class OrangTuaDetailScreen extends StatefulWidget {
  final OrangTuaModel data;

  const OrangTuaDetailScreen({super.key, required this.data});

  @override
  State<OrangTuaDetailScreen> createState() => _OrangTuaDetailScreenState();
}

class _OrangTuaDetailScreenState extends State<OrangTuaDetailScreen> {
  late OrangTuaModel _currentData;

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
          'Detail Orang Tua',
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
                      OrangTuaFormScreen(existingData: _currentData),
                ),
              );

              if (result == true) {
                // Return to profile to force reload if edited
                if (mounted) Navigator.pop(context);
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
                    'Informasi Keluarga',
                    Icons.family_restroom_rounded,
                    Colors.purple,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Nomor KK', _currentData.noKk),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  _buildHeaderRow(
                    'Data Ibu',
                    Icons.person_3_rounded,
                    Colors.pink,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Nama Ibu', _currentData.namaIbu),
                  const SizedBox(height: 12),
                  _buildDetailItem('NIK Ibu', _currentData.nikIbu),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  _buildHeaderRow(
                    'Data Ayah',
                    Icons.person_rounded,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('Nama Ayah', _currentData.namaAyah),
                  const SizedBox(height: 12),
                  _buildDetailItem('NIK Ayah', _currentData.nikAyah),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(),
                  ),

                  _buildHeaderRow(
                    'Kontak & Alamat',
                    Icons.contact_mail_rounded,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem('No HP', _currentData.noHp),
                  const SizedBox(height: 12),
                  _buildDetailItem('Alamat', _currentData.alamat),
                ],
              ),
            ),
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
