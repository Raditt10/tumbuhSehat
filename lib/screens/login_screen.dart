import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/top_notification.dart';
import 'main_navigation.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _primaryBlue = Color(0xFF0288D1);

  String _selectedRole = 'orang_tua'; // 'orang_tua', 'ibu_hamil', 'kader'
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _emailController.text = prefs.getString('saved_email') ?? '';
      _passwordController.text = prefs.getString('saved_password') ?? '';
      _rememberMe = prefs.getBool('remember_me') ?? false;
    });
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showNotification('Harap isi email dan kata sandi.', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (userCredential.user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userDoc.exists) {
          String role = userDoc.get('role');

          if (_selectedRole != role) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              String roleName = role == 'orang_tua'
                  ? 'Orang Tua'
                  : role == 'ibu_hamil'
                  ? 'Ibu Hamil'
                  : 'Kader';
              _showNotification(
                'Gagal masuk: Akun ini terdaftar sebagai $roleName.',
                isError: true,
              );
            }
            return;
          }

          if (mounted) {
            _showNotification('Berhasil masuk!', isError: false);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => MainNavigation(role: role)),
            );
          }
        } else {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            _showNotification('Data pengguna tidak ditemukan.', isError: true);
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Terjadi kesalahan.';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'Email atau kata sandi salah.';
      } else if (e.code == 'invalid-email') {
        message = 'Format email tidak valid.';
      }
      if (mounted) _showNotification(message, isError: true);
    } catch (e) {
      if (mounted) _showNotification('Error: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      // Step 1: Sign in with Google to Firebase
      final User? user = await _authService.signInWithGoogle();
      if (user == null) {
        setState(() => _isGoogleLoading = false);
        return;
      }

      // Step 2: Check if this UID has a Firestore user doc
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // No Firestore doc = orphaned/unlinked Google account
        // Delete orphaned Firebase Auth account and sign out
        await user.delete();
        await _authService.signOutGoogle();
        if (mounted) {
          _showNotification(
            'Akun Google ini belum dikaitkan. '
            'Login dengan email/password, lalu hubungkan di halaman Profil.',
            isError: true,
          );
        }
        return;
      }

      // Step 3: Doc exists - check if Google is properly linked
      final linkedEmail = userDoc.data()?['linkedGoogleEmail'];
      if (linkedEmail == null || (linkedEmail as String).isEmpty) {
        // User doc exists but Google not linked (email/password only account)
        await FirebaseAuth.instance.signOut();
        await _authService.signOutGoogle();
        if (mounted) {
          _showNotification(
            'Login Google belum diaktifkan untuk akun ini. '
            'Hubungkan di halaman Profil terlebih dahulu.',
            isError: true,
          );
        }
        return;
      }

      // Step 4: Verify role
      final String existingRole = userDoc.get('role');
      if (_selectedRole != existingRole) {
        await FirebaseAuth.instance.signOut();
        await _authService.signOutGoogle();
        if (mounted) {
          String roleName = existingRole == 'orang_tua'
              ? 'Orang Tua'
              : existingRole == 'ibu_hamil'
                  ? 'Ibu Hamil'
                  : 'Kader';
          _showNotification(
            'Akun ini terdaftar sebagai $roleName.',
            isError: true,
          );
        }
        return;
      }

      // Step 5: All good — navigate to dashboard
      if (mounted) {
        _showNotification('Berhasil masuk dengan Google!', isError: false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(role: existingRole),
          ),
        );
      }
    } catch (e) {
      await _authService.signOutGoogle();
      if (mounted) {
        _showNotification('Gagal masuk dengan Google: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showNotification(String message, {required bool isError}) {
    TopNotification.show(context, message, isError: isError);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color primaryBlue = _primaryBlue;
    const Color bgLight = Color(0xFFF5F9FD);

    return Scaffold(
      backgroundColor: bgLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Curved Header
            Stack(
              children: [
                ClipPath(
                  clipper: HeaderClipperModern(),
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/posyandu_header.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Overlay for better text readability
                ClipPath(
                  clipper: HeaderClipperModern(),
                  child: Container(
                    height: 280,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
                Positioned(
                  top: 100,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'Login',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Role Toggle (Orang Tua / Kader)
                Positioned(
                  top: 160,
                  left: 30,
                  right: 30,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        _buildRoleToggle('Orang Tua', 'orang_tua'),
                        _buildRoleToggle('Ibu Hamil', 'ibu_hamil'),
                        _buildRoleToggle('Kader', 'kader'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Form Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text('Email address:', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hintText: 'Enter your email address',
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),

                  const Text('Password:', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hintText: 'Enter the password',
                    icon: Icons.lock_outline,
                    isPassword: true,
                  ),
                  const SizedBox(height: 15),

                  // Remember me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? false;
                                });
                              },
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              activeColor: primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember me',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Main Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 25),

                  // Or login with
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'or login with',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade400)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Social Buttons
                  _buildGoogleButton(),

                  const SizedBox(height: 30),

                  // Register Link (Only for Parents & Ibu Hamil)
                  if (_selectedRole != 'kader') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  RegisterScreen(initialRole: _selectedRole),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleToggle(String label, String role) {
    bool isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primaryBlue.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? _primaryBlue : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _isGoogleLoading ? null : _handleGoogleSignIn,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _isGoogleLoading
                  ? const [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ]
                  : [
                      Image.asset('assets/images/google_logo.png', height: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Sign in with Google',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom Clipper for the Wavy Header
class HeaderClipperModern extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 80);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 40);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    var secondControlPoint = Offset(size.width * 0.75, size.height - 80);
    var secondEndPoint = Offset(size.width, size.height - 20);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
