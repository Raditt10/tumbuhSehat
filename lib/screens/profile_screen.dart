import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  final user = FirebaseAuth.instance.currentUser!;
  final picker = ImagePicker();

  bool isEdit = false;
  File? imageFile;

  final namaController = TextEditingController();
  final panggilanController = TextEditingController();
  final nikController = TextEditingController();
  final alamatController = TextEditingController();
  final roleController = TextEditingController();

  DateTime? selectedDate;

  // ===================== UPDATE PROFILE =====================

  Future<void> updateProfile() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      'nama': namaController.text,
      'namaPanggilan': panggilanController.text,
      'nik': nikController.text,
      'alamat': alamatController.text,
      'role': roleController.text,
      'tanggallahir': selectedDate,
    });

    setState(() {
      isEdit = false;
    });
  }

  // ===================== PICK DATE =====================

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // ===================== PICK IMAGE =====================

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      imageFile = File(picked.path);
      await uploadImage();
    }
  }

  Future<void> uploadImage() async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('profile_images')
        .child('${user.uid}.jpg');

    await ref.putFile(imageFile!);
    String url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fotoProfil': url});
  }

  // ===================== UI TEXTFIELD =====================

  Widget buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        enabled: isEdit,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[300],
          border: OutlineInputBorder(borderSide: BorderSide.none),
          labelText: label,
        ),
      ),
    );
  }

  Widget buildViewBox(String value) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 6),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(value),
    );
  }

  // ===================== MAIN BUILD =====================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text("PROFILE"),
        centerTitle: true,
        backgroundColor: Colors.green[300],
        actions: [
          IconButton(
            icon: Icon(isEdit ? Icons.check : Icons.edit),
            onPressed: () {
              if (isEdit) {
                updateProfile();
              } else {
                setState(() => isEdit = true);
              }
            },
          )
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Data tidak ditemukan"));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;

          if (!isEdit) {
            // isi controller saat pertama load
            namaController.text = data['nama'] ?? "";
            panggilanController.text = data['namaPanggilan'] ?? "";
            nikController.text = data['nik'].toString();
            alamatController.text = data['alamat'] ?? "";
            roleController.text = data['role'] ?? "";
            if (data['tanggallahir'] != null) {
              selectedDate =
                  (data['tanggallahir'] as Timestamp).toDate();
            }
          }

          String? fotoUrl = data['fotoProfil'];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [

                // ================= FOTO =================
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: imageFile != null
                          ? FileImage(imageFile!)
                          : (fotoUrl != null && fotoUrl != "")
                              ? NetworkImage(fotoUrl)
                              : null,
                      child: (fotoUrl == null || fotoUrl == "")
                          ? Icon(Icons.person, size: 60)
                          : null,
                    ),

                    if (isEdit)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(Icons.edit, color: Colors.black),
                          ),
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 10),
                Text(user.email!, style: TextStyle(color: Colors.grey)),

                SizedBox(height: 20),

                // ================= FIELD =================

                isEdit
                    ? buildField("Nama Lengkap", namaController)
                    : buildViewBox(data['nama'] ?? ""),

                isEdit
                    ? buildField("Nama Panggilan", panggilanController)
                    : buildViewBox(data['namaPanggilan'] ?? ""),

                isEdit
                    ? buildField("NIK", nikController)
                    : buildViewBox(data['nik'].toString()),

                isEdit
                    ? buildField("Alamat", alamatController)
                    : buildViewBox(data['alamat'] ?? ""),

                isEdit
                    ? buildField("Role", roleController)
                    : buildViewBox(data['role'] ?? ""),

                // ================= TANGGAL =================

                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: 6),
                  padding: EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: isEdit
                      ? GestureDetector(
                          onTap: pickDate,
                          child: Text(
                            selectedDate != null
                                ? DateFormat('dd MMMM yyyy')
                                    .format(selectedDate!)
                                : "Pilih Tanggal",
                          ),
                        )
                      : Text(
                          selectedDate != null
                              ? DateFormat('dd MMMM yyyy')
                                  .format(selectedDate!)
                              : "",
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}