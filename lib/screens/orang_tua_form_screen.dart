import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/orang_tua_model.dart';
import '../widgets/top_notification.dart';

class OrangTuaFormScreen extends StatefulWidget {
  final OrangTuaModel? existingData;
  const OrangTuaFormScreen({super.key, this.existingData});

  @override
  State<OrangTuaFormScreen> createState() => _OrangTuaFormScreenState();
}

class _OrangTuaFormScreenState extends State<OrangTuaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _noKkController;
  late TextEditingController _nikIbuController;
  late TextEditingController _namaIbuController;
  late TextEditingController _nikAyahController;
  late TextEditingController _namaAyahController;
  late TextEditingController _alamatController;
  late TextEditingController _noHpController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noKkController = TextEditingController(
      text: widget.existingData?.noKk ?? '',
    );
    _nikIbuController = TextEditingController(
      text: widget.existingData?.nikIbu ?? '',
    );
    _namaIbuController = TextEditingController(
      text: widget.existingData?.namaIbu ?? '',
    );
    _nikAyahController = TextEditingController(
      text: widget.existingData?.nikAyah ?? '',
    );
    _namaAyahController = TextEditingController(
      text: widget.existingData?.namaAyah ?? '',
    );
    _alamatController = TextEditingController(
      text: widget.existingData?.alamat ?? '',
    );
    _noHpController = TextEditingController(
      text: widget.existingData?.noHp ?? '',
    );
  }

  @override
  void dispose() {
    _noKkController.dispose();
    _nikIbuController.dispose();
    _namaIbuController.dispose();
    _nikAyahController.dispose();
    _namaAyahController.dispose();
    _alamatController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User belum login');

        final orangTua = OrangTuaModel(
          id: widget.existingData?.id ?? '',
          userId: user.uid,
          noKk: _noKkController.text.trim(),
          nikIbu: _nikIbuController.text.trim(),
          namaIbu: _namaIbuController.text.trim(),
          nikAyah: _nikAyahController.text.trim(),
          namaAyah: _namaAyahController.text.trim(),
          alamat: _alamatController.text.trim(),
          noHp: _noHpController.text.trim(),
        );

        await DatabaseService().saveOrangTua(orangTua);

        if (mounted) {
          TopNotification.show(context, 'Data Orang Tua berhasil disimpan');
          Navigator.pop(context, true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          TopNotification.show(context, 'Terjadi kesalahan: $e', isError: true);
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingData == null
              ? 'Isi Data Orang Tua'
              : 'Edit Data Orang Tua',
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Informasi Keluarga'),
              _buildTextField(
                controller: _noKkController,
                label: 'Nomor Kartu Keluarga (KK)',
                icon: Icons.contact_emergency_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),

              _buildSectionTitle('Data Ibu'),
              _buildTextField(
                controller: _nikIbuController,
                label: 'NIK Ibu',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              _buildTextField(
                controller: _namaIbuController,
                label: 'Nama Lengkap Ibu',
                icon: Icons.person_3_outlined,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),

              _buildSectionTitle('Data Ayah'),
              _buildTextField(
                controller: _nikAyahController,
                label: 'NIK Ayah',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              _buildTextField(
                controller: _namaAyahController,
                label: 'Nama Lengkap Ayah',
                icon: Icons.person_outline,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),

              _buildSectionTitle('Kontak & Alamat'),
              _buildTextField(
                controller: _noHpController,
                label: 'Nomor Handphone (Aktif)',
                icon: Icons.phone_android_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),
              _buildTextField(
                controller: _alamatController,
                label: 'Alamat Lengkap',
                icon: Icons.home_outlined,
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Wajib diisi' : null,
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 5,
                    shadowColor: const Color(0xFF0288D1).withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Data',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0288D1),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: maxLines > 1
              ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: 40,
                  ), // Align to top for multiline
                  child: Icon(icon, color: const Color(0xFF4FC3F7)),
                )
              : Icon(icon, color: const Color(0xFF4FC3F7)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.blue.shade100, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Color(0xFF0288D1), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.red.shade300, width: 2),
          ),
        ),
      ),
    );
  }
}
