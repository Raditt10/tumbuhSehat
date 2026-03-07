import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/top_notification.dart';
import '../models/pemeriksaan_balita_model.dart';

class PemeriksaanFormScreen extends StatefulWidget {
  final String balitaId;
  const PemeriksaanFormScreen({super.key, required this.balitaId});

  @override
  State<PemeriksaanFormScreen> createState() => _PemeriksaanFormScreenState();
}

class _PemeriksaanFormScreenState extends State<PemeriksaanFormScreen> {
  final _formKey = GlobalKey<FormState>();

  double _beratBadan = 0.0;
  double _tinggiBadan = 0.0;
  double _lingkarKepala = 0.0;
  bool _isLoading = false;

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      // Simple mock logic for Nutritional Status based on input
      String statusGizi = 'Normal';
      bool indikasiStunting = false;

      if (_beratBadan < 4.0) {
        statusGizi = 'Kurang';
      } else if (_beratBadan > 10.0) {
        statusGizi = 'Gemuk';
      }

      if (_tinggiBadan < 55.0) {
        indikasiStunting = true;
      }

      try {
        final newCheckup = PemeriksaanBalitaModel(
          id: '', // Firestore auto-generates this if we add to collection, but our model wants a string. We'll use docRef.id later or ignore id in toMap.
          balitaId: widget.balitaId,
          jadwalId: 'jadwal_sekarang', // Dummy session
          usiaSaatPeriksa: 6, // E.g., 6 months
          beratBadan: _beratBadan,
          tinggiBadan: _tinggiBadan,
          lingkarKepala: _lingkarKepala,
          statusGizi: statusGizi,
          indikasiStunting: indikasiStunting,
          kaderId: 'kader_001', // User ID of the logged in worker
        );

        await DatabaseService().addPemeriksaanBalita(newCheckup);

        if (mounted) {
          Navigator.pop(context);
          TopNotification.show(context, 'Data berhasil ditambahkan!');
        }
      } catch (e) {
        if (mounted) {
          TopNotification.show(context, 'Terjadi kesalahan: $e', isError: true);
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Indicator
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Tambah Data KMS Anak',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Form Inputs
              _buildNumberField(
                label: 'Berat Badan (kg)',
                icon: Icons.monitor_weight_outlined,
                onSaved: (value) =>
                    _beratBadan = double.tryParse(value ?? '0') ?? 0,
              ),
              const SizedBox(height: 15),

              _buildNumberField(
                label: 'Tinggi Badan (cm)',
                icon: Icons.height_outlined,
                onSaved: (value) =>
                    _tinggiBadan = double.tryParse(value ?? '0') ?? 0,
              ),
              const SizedBox(height: 15),

              _buildNumberField(
                label: 'Lingkar Kepala (cm)',
                icon: Icons.face_outlined,
                onSaved: (value) =>
                    _lingkarKepala = double.tryParse(value ?? '0') ?? 0,
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0288D1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Simpan Data KMS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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

  Widget _buildNumberField({
    required String label,
    required IconData icon,
    required Function(String?) onSaved,
  }) {
    return TextFormField(
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Wajib diisi';
        }
        if (double.tryParse(value) == null) {
          return 'Harus berupa angka';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }
}
