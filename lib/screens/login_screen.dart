import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // true = Orang Tua, false = Kader
  bool _isParentRole = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showCustomSnackBar('Harap isi semua kolom.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Sign in with Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 2. Fetch user role from Firestore to Verify
      if (userCredential.user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc.get('role');
          bool isUserParent = role == 'orang_tua';

          if (_isParentRole != isUserParent) {
            // Wrong role selected
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              _showCustomSnackBar(
                _isParentRole
                    ? 'Gagal masuk: Akun ini terdaftar sebagai Kader.'
                    : 'Gagal masuk: Akun ini terdaftar sebagai Orang Tua.',
                isError: true,
              );
            }
            return;
          }

          if (mounted) {
            _showCustomSnackBar('Berhasil masuk!', isError: false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigation()),
            );
          }
        } else {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showCustomSnackBar(
              'Data pengguna tidak ditemukan.',
              isError: true,
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Email atau kata sandi salah.';
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        message = 'Email atau kata sandi tidak cocok.';
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Lottie Animation or Illustration Placeholder
              Center(
                child: Icon(
                  Icons.family_restroom_rounded,
                  size: 100,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Selamat Datang di\nRuang Tumbuh',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 28,
                  height: 1.2,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pantau tumbuh kembang anak dengan lebih mudah dan menyenangkan.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 40),

              // Role Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isParentRole = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isParentRole
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Orang Tua',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isParentRole ? Colors.white : Colors.grey,
                              fontWeight: _isParentRole
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isParentRole = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isParentRole
                                ? theme.colorScheme.secondary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'Kader Posyandu',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isParentRole
                                  ? Colors.white
                                  : Colors.grey,
                              fontWeight: !_isParentRole
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Login Form
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
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Lupa Kata Sandi?',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Login Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isParentRole
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
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
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(height: 20),

              // Go to Register (only for Parent)
              if (_isParentRole)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Daftar Sekarang',
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
