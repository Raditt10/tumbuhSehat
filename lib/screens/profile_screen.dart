import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/top_notification.dart';
import 'login_screen.dart';
import 'balita_list_screen.dart';
import 'balita_form_screen.dart';
import 'balita_detail_screen.dart';
import 'orang_tua_form_screen.dart';
import 'orang_tua_detail_screen.dart';

// ==========================================
// 4. PROFIL (TERMASUK GAMIFIKASI/BADGE)
// ==========================================
class ProfileScreen extends StatefulWidget {
  final String role;
  const ProfileScreen({super.key, this.role = 'orang_tua'});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Assume user is logged in, using dummy parent id if not for demo purposes
  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? 'dummy_parent_123';

  bool _isUploading = false;
  int _refreshCounter = 0; // increment to force profile reload
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = DatabaseService().getUserData(
      FirebaseAuth.instance.currentUser?.uid ?? currentUserId,
    );
  }

  void _reloadUserData() {
    _userFuture = DatabaseService().getUserData(
      FirebaseAuth.instance.currentUser?.uid ?? currentUserId,
    );
  }

  Future<void> _pickAndUploadImage() async {
    // Guard: make sure user is actually logged in
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      TopNotification.show(
        context,
        'Harap login terlebih dahulu',
        isError: true,
      );
      return;
    }

    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _isUploading = true;
        });

        print('[Profile] Uploading for UID: ${firebaseUser.uid}');

        await DatabaseService().uploadProfilePicture(
          firebaseUser.uid,
          File(image.path),
        );

        if (mounted) {
          _reloadUserData();
          setState(() {
            _isUploading = false;
            _refreshCounter++; // force FutureBuilder to reload
          });
          TopNotification.show(context, 'Foto profil berhasil diperbarui');
        }
      }
    } catch (e) {
      print('[Profile] Error: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        TopNotification.show(
          context,
          'Gagal mengunggah foto: $e',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FD),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100.0), // space for bottom nav
        child: Column(
          children: [
            FutureBuilder<UserModel?>(
              key: ValueKey(_refreshCounter), // rebuild when photo updated
              future: _userFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 240,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                UserModel? userData = snapshot.data;

                return Column(
                  children: [
                    _buildHeader(userData),
                    const SizedBox(height: 20),
                    _buildMenuSection(userData),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel? userData) {
    final isBumil = widget.role == 'ibu_hamil';
    String parentName = userData?.namaPanggilan ?? (isBumil ? 'Bunda (Guest)' : 'Bunda (Guest)');
    String joinedYear = userData?.createdAt?.year.toString() ?? '2024';

    final gradientColors = isBumil
        ? [const Color(0xFFE91E63), const Color(0xFFC2185B)]
        : [const Color(0xFF4FC3F7), const Color(0xFF0288D1)];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Background Header
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(40),
              bottomRight: Radius.circular(40),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Profil Saya',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : IconButton(
                          onPressed: _pickAndUploadImage,
                          icon: const Icon(
                            Icons.edit_square,
                            color: Colors.white,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),

        // Profile Card Overlapping
        Positioned(
          top: 120,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar with border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5FE),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4FC3F7),
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: _buildAvatarImage(userData),
                    child: _buildAvatarImage(userData) == null
                        ? const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF4FC3F7),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 15),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parentName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Bergabung sejak $joinedYear',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Verified Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.role == 'ibu_hamil'
                              ? const Color(0xFFFCE4EC)
                              : const Color(0xFFE1F5FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified,
                              color: widget.role == 'ibu_hamil'
                                  ? const Color(0xFFE91E63)
                                  : const Color(0xFF0288D1),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Akun Terverifikasi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.role == 'ibu_hamil'
                                    ? const Color(0xFFE91E63)
                                    : const Color(0xFF0288D1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Returns a MemoryImage if user has a base64 photo, otherwise null.
  ImageProvider? _buildAvatarImage(UserModel? userData) {
    // Prefer base64 (stored directly in Firestore — free)
    if (userData?.photoBase64 != null && userData!.photoBase64!.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(userData.photoBase64!));
      } catch (_) {
        // corrupted base64, fall through to photoUrl
      }
    }
    // Fallback: networkUrl (e.g. if they had Firebase Storage before)
    if (userData?.photoUrl != null && userData!.photoUrl!.isNotEmpty) {
      return NetworkImage(userData.photoUrl!);
    }
    return null;
  }

  Widget _buildMenuSection(UserModel? userData) {
    final isKader = widget.role == 'kader';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                if (isKader) ...[  
                  _buildMenuItem(
                    Icons.person_rounded,
                    'Data Saya',
                    Colors.blue.shade400,
                    () => _showKaderDataForm(userData),
                  ),
                  _buildDivider(),
                ],
                if (!isKader && widget.role != 'ibu_hamil') ...[
                  _buildMenuItem(
                    Icons.child_care_rounded,
                    'Data Anak',
                    const Color(0xFF4FC3F7),
                    () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && mounted) {
                        final otData = await DatabaseService()
                            .getOrangTuaByUserId(user.uid);
                        if (otData != null && mounted) {
                          try {
                            final balitaSnapshot = await DatabaseService()
                                .streamBalitaByOrangTua(otData.id)
                                .first;
                            if (mounted) {
                              if (balitaSnapshot.isEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const BalitaFormScreen(),
                                  ),
                                );
                              } else if (balitaSnapshot.length == 1) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BalitaDetailScreen(data: balitaSnapshot.first),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        BalitaListScreen(orangTuaId: otData.id),
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              TopNotification.show(
                                context,
                                'Terjadi kesalahan memuat data',
                                isError: true,
                              );
                            }
                          }
                        } else if (mounted) {
                          TopNotification.show(
                            context,
                            'Profil Orang Tua belum lengkap',
                            isError: true,
                          );
                        }
                      }
                    },
                  ),
                  _buildDivider(),
                ],
                if (!isKader && widget.role == 'ibu_hamil') ...[
                  _buildMenuItem(
                    Icons.pregnant_woman_rounded,
                    'Data Kehamilan',
                    Colors.pink.shade400,
                    () {},
                  ),
                  _buildDivider(),
                ],
                if (!isKader) ...[  
                  _buildMenuItem(
                    Icons.edit_rounded,
                    'Ganti Username',
                    Colors.cyan.shade400,
                    () => _showChangeUsernameDialog(userData),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    Icons.family_restroom_rounded,
                    'Data Orang Tua',
                    Colors.purple.shade400,
                  () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null && mounted) {
                      final otData = await DatabaseService()
                          .getOrangTuaByUserId(user.uid);
                      if (mounted) {
                        if (otData == null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OrangTuaFormScreen(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  OrangTuaDetailScreen(data: otData),
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
                  _buildDivider(),
                  _buildMenuItem(
                    Icons.medical_information_rounded,
                    'Riwayat Kesehatan',
                    Colors.green,
                    () {},
                  ),
                  _buildDivider(),
                ],
                _buildMenuItem(
                  Icons.notifications_active_rounded,
                  'Notifikasi',
                  Colors.orange,
                  () {},
                ),
                _buildDivider(),
                _buildGoogleLinkMenuItem(),
                _buildDivider(),
                _buildMenuItem(
                  Icons.security_rounded,
                  'Privasi & Keamanan',
                  Colors.indigo,
                  () {},
                ),
                _buildDivider(),
                _buildMenuItem(
                  Icons.help_outline_rounded,
                  'Pusat Bantuan',
                  Colors.teal,
                  () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    TopNotification.show(
                      context,
                      'Gagal keluar: $e',
                      isError: true,
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFF0F0),
                foregroundColor: Colors.red.shade400,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.red.shade100, width: 2),
                ),
              ),
              child: const Text(
                'Keluar Akun',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildGoogleLinkMenuItem() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final linkedEmail = data?['linkedGoogleEmail'] as String?;
        final isLinked = linkedEmail != null && linkedEmail.isNotEmpty;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isLinked ? Colors.green : Colors.red).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLinked ? Icons.link : Icons.link_off,
              color: isLinked ? Colors.green : Colors.red,
              size: 22,
            ),
          ),
          title: Text(
            isLinked ? 'Akun Google Terhubung' : 'Hubungkan Akun Google',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          subtitle: isLinked
              ? Text(
                  linkedEmail,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                )
              : null,
          trailing: isLinked
              ? IconButton(
                  icon: Icon(Icons.close, color: Colors.red.shade300, size: 20),
                  onPressed: () => _unlinkGoogle(),
                )
              : const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          onTap: isLinked ? null : () => _linkGoogle(),
        );
      },
    );
  }

  Future<void> _linkGoogle() async {
    // Ask user for password first (needed to handle orphaned account cleanup)
    final password = await _showPasswordDialog();
    if (password == null || password.isEmpty) return;

    try {
      final email = await AuthService().linkGoogleAccount(password);
      if (email != null && mounted) {
        _reloadUserData();
        setState(() => _refreshCounter++);
        TopNotification.show(
          context,
          'Akun Google ($email) berhasil dihubungkan!',
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Gagal menghubungkan akun Google.';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          message = 'Password salah. Silakan coba lagi.';
        }
        TopNotification.show(context, message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Verifikasi Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan password akun Anda untuk menghubungkan akun Google.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Lanjutkan'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _unlinkGoogle() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Putuskan Akun Google?'),
        content: const Text(
          'Anda tidak akan bisa login dengan Google setelah ini. Yakin ingin memutuskan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Putuskan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService().unlinkGoogleAccount();
        if (mounted) {
          _reloadUserData();
          setState(() => _refreshCounter++);
          TopNotification.show(context, 'Akun Google berhasil diputuskan.');
        }
      } catch (e) {
        if (mounted) {
          TopNotification.show(
            context,
            'Gagal memutuskan akun Google: $e',
            isError: true,
          );
        }
      }
    }
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }

  // ──────────── GANTI USERNAME (orang_tua & ibu_hamil) ────────────
  void _showChangeUsernameDialog(UserModel? userData) {
    final controller =
        TextEditingController(text: userData?.namaPanggilan ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ganti Username'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'Masukkan username baru',
            prefixIcon: const Icon(Icons.person_outline),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({'namaPanggilan': newName});
                if (mounted) {
                  Navigator.pop(ctx);
                  _reloadUserData();
                  setState(() => _refreshCounter++);
                  TopNotification.show(
                      context, 'Username berhasil diubah');
                }
              } catch (e) {
                if (mounted) {
                  TopNotification.show(
                    context,
                    'Gagal mengubah username: $e',
                    isError: true,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0288D1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  // ──────────── KADER DATA FORM ────────────
  void _showKaderDataForm(UserModel? userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _KaderDataFormContent(
          initialNama: userData?.namaPanggilan ?? '',
          initialNoHp: userData?.noHp ?? '',
          onSaved: () {
            _reloadUserData();
            setState(() => _refreshCounter++);
            TopNotification.show(context, 'Data berhasil disimpan');
          },
        );
      },
    );
  }
}

class _KaderDataFormContent extends StatefulWidget {
  final String initialNama;
  final String initialNoHp;
  final VoidCallback onSaved;

  const _KaderDataFormContent({
    required this.initialNama,
    required this.initialNoHp,
    required this.onSaved,
  });

  @override
  State<_KaderDataFormContent> createState() => _KaderDataFormContentState();
}

class _KaderDataFormContentState extends State<_KaderDataFormContent> {
  late final TextEditingController _namaController;
  late final TextEditingController _noHpController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.initialNama);
    _noHpController = TextEditingController(text: widget.initialNoHp);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Data Saya',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 20),
            const Text('Nama',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(
                hintText: 'Nama panggilan Anda',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Nomor WhatsApp',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _noHpController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: 'Contoh: 08123456789',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid == null) return;

                  final nama = _namaController.text.trim();
                  final noHp = _noHpController.text.trim();

                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({
                      if (nama.isNotEmpty) 'namaPanggilan': nama,
                      if (noHp.isNotEmpty) 'noHp': noHp,
                    });
                    if (mounted) {
                      Navigator.pop(context);
                      widget.onSaved();
                    }
                  } catch (e) {
                    if (mounted) {
                      TopNotification.show(
                        context,
                        'Gagal menyimpan: $e',
                        isError: true,
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0288D1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Simpan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
