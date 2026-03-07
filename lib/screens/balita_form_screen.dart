import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/database_service.dart';
import '../models/balita_model.dart';
import '../widgets/top_notification.dart';

class BalitaFormScreen extends StatefulWidget {
  final BalitaModel? existingData;
  const BalitaFormScreen({super.key, this.existingData});

  @override
  State<BalitaFormScreen> createState() => _BalitaFormScreenState();
}

class _BalitaFormScreenState extends State<BalitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nikController;
  late TextEditingController _namaController;
  late TextEditingController _tempatLahirController;
  late TextEditingController _beratLahirController;
  late TextEditingController _tinggiLahirController;
  late TextEditingController _anakKeController;

  String _jenisKelamin = 'L';
  DateTime? _tanggalLahir;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nikController = TextEditingController(
      text: widget.existingData?.nikAnak ?? '',
    );
    _namaController = TextEditingController(
      text: widget.existingData?.namaAnak ?? '',
    );
    _tempatLahirController = TextEditingController(
      text: widget.existingData?.tempatLahir ?? '',
    );
    _beratLahirController = TextEditingController(
      text: widget.existingData != null
          ? widget.existingData!.beratLahir.toString()
          : '',
    );
    _tinggiLahirController = TextEditingController(
      text: widget.existingData != null
          ? widget.existingData!.tinggiLahir.toString()
          : '',
    );
    _anakKeController = TextEditingController(
      text: widget.existingData != null
          ? widget.existingData!.anakKe.toString()
          : '',
    );
    _jenisKelamin = widget.existingData?.jenisKelamin ?? 'L';
    _tanggalLahir = widget.existingData?.tanggalLahir;
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _tempatLahirController.dispose();
    _beratLahirController.dispose();
    _tinggiLahirController.dispose();
    _anakKeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalLahir ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0288D1),
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _tanggalLahir) {
      setState(() {
        _tanggalLahir = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_tanggalLahir == null) {
        TopNotification.show(
          context,
          'Pilih tanggal lahir anak',
          isError: true,
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('User belum login');

        // Get Orang Tua ID
        final otData = await DatabaseService().getOrangTuaByUserId(user.uid);
        if (otData == null) {
          throw Exception(
            'Data Orang Tua tidak ditemukan, lengkapi profil terlebih dahulu',
          );
        }

        final balita = BalitaModel(
          id: widget.existingData?.id ?? '', // Use existing ID if editing
          orangTuaId: otData.id,
          nikAnak: _nikController.text.trim(),
          namaAnak: _namaController.text.trim(),
          jenisKelamin: _jenisKelamin,
          tempatLahir: _tempatLahirController.text.trim(),
          tanggalLahir: _tanggalLahir!,
          beratLahir: double.tryParse(_beratLahirController.text.trim()) ?? 0,
          tinggiLahir: double.tryParse(_tinggiLahirController.text.trim()) ?? 0,
          anakKe: int.tryParse(_anakKeController.text.trim()) ?? 1,
        );

        await DatabaseService().saveBalita(balita);

        if (mounted) {
          TopNotification.show(context, 'Data anak berhasil disimpan');
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
          widget.existingData == null ? 'Tambah Data Anak' : 'Edit Data Anak',
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
              _buildSectionTitle('Informasi Pribadi'),
              _buildTextField(
                controller: _nikController,
                label: 'NIK Anak',
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value!.isEmpty ? 'NIK Anak tidak boleh kosong' : null,
              ),
              _buildTextField(
                controller: _namaController,
                label: 'Nama Anak',
                icon: Icons.person_outline,
                validator: (value) =>
                    value!.isEmpty ? 'Nama Anak tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              _buildSectionTitle('Jenis Kelamin'),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text(
                        'Laki-laki',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: 'L',
                      groupValue: _jenisKelamin,
                      onChanged: (value) =>
                          setState(() => _jenisKelamin = value!),
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF0288D1),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text(
                        'Perempuan',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: 'P',
                      groupValue: _jenisKelamin,
                      onChanged: (value) =>
                          setState(() => _jenisKelamin = value!),
                      contentPadding: EdgeInsets.zero,
                      activeColor: Colors.pink,
                    ),
                  ),
                ],
              ),

              _buildSectionTitle('Kelahiran'),
              _buildTextField(
                controller: _tempatLahirController,
                label: 'Tempat Lahir',
                icon: Icons.location_city_outlined,
                validator: (value) =>
                    value!.isEmpty ? 'Tempat Lahir tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade100, width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: Color(0xFF0288D1),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        _tanggalLahir == null
                            ? 'Pilih Tanggal Lahir'
                            : '${_tanggalLahir!.day}/${_tanggalLahir!.month}/${_tanggalLahir!.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _tanggalLahir == null
                              ? Colors.grey
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _beratLahirController,
                      label: 'Berat Lahir (kg)',
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _tinggiLahirController,
                      label: 'Tinggi Lahir (cm)',
                      icon: Icons.height_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _anakKeController,
                label: 'Anak Ke-',
                icon: Icons.format_list_numbered_outlined,
                keyboardType: TextInputType.number,
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
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: Icon(icon, color: const Color(0xFF4FC3F7)),
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
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
        ),
      ),
    );
  }
}
