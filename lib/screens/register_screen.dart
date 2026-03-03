import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      _showCustomSnackBar('Harap isi semua kolom.', isError: true);
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showCustomSnackBar('Kata sandi tidak cocok.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Buat user di Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Simpan profil ke Firestore
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'id': userCredential.user!.uid,
              'namaPanggilan': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'role': 'orang_tua',   
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          _showCustomSnackBar(
            'Registrasi berhasil! Silakan masuk.',  
            isError: false,
          );
          Navigator.pop(context); // Kembali ke halaman login
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan.';
      if (e.code == 'weak-password') {
        message = 'Kata sandi terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email sudah digunakan.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      }
      if (mounted) {
        _showCustomSnackBar(message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCustomSnackBar(String message, {required bool isError}) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : theme.colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: theme.colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Daftar Akun Baru',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  height: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Buat akun orang tua untuk mulai memantau tumbuh kembang si kecil.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),

              // Registrasi Form
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap (Ibu/Ayah)',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Kata Sandi',
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 40),

              // Register Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Daftar Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Go to Login
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sudah punya akun? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Masuk',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
