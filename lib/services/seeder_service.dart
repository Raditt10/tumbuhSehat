import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/balita_model.dart';
import '../models/orang_tua_model.dart';
import '../models/pemeriksaan_balita_model.dart';

class SeederService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> seedDummyData() async {
    print("Mulai proses seeder dummy data...");

    // Check if data already exists in balita to prevent duplicate dummy data
    var check = await _db.collection('balita').limit(1).get();
    if (check.docs.isNotEmpty) {
      print("Data balita sudah ada, skip seeder.");
      return;
    }

    // 1. Create a dummy parent user
    String parentUserId = 'dummy_parent_123';
    UserModel parentUser = UserModel(
      id: parentUserId,
      email: 'bunda@example.com',
      role: 'orang_tua',
    );
    await _db.collection('users').doc(parentUserId).set(parentUser.toMap());

    // 2. Create OrangTua details
    String orangTuaId = 'orang_tua_123';
    OrangTuaModel orangTua = OrangTuaModel(
      id: orangTuaId,
      userId: parentUserId,
      noKk: '320000000001',
      nikIbu: '320000000002',
      namaIbu: 'Bunda Sarah',
      nikAyah: '320000000003',
      namaAyah: 'Ayah Budi',
      alamat: 'Jl. Melati No 1, Ciguruwik',
      noHp: '08123456789',
    );
    await _db.collection('orang_tua').doc(orangTuaId).set(orangTua.toMap());

    // 3. Create Balita
    String balitaId = 'balita_123';
    BalitaModel balita = BalitaModel(
      id: balitaId,
      orangTuaId: orangTuaId,
      nikAnak: '320000000004',
      namaAnak: 'Dedek Bayi',
      jenisKelamin: 'L',
      tempatLahir: 'Bandung',
      tanggalLahir: DateTime.now().subtract(
        const Duration(days: 150),
      ), // ~5 months old
      beratLahir: 3.2,
      tinggiLahir: 50.0,
      anakKe: 1,
    );
    await _db.collection('balita').doc(balitaId).set(balita.toMap());

    // 4. Create Pemeriksaan Balita
    String pemeriksaanId = 'pemeriksaan_123';
    PemeriksaanBalitaModel pemeriksaan = PemeriksaanBalitaModel(
      id: pemeriksaanId,
      balitaId: balitaId,
      jadwalId: 'jadwal_bulan_ini',
      usiaSaatPeriksa: 5,
      beratBadan: 6.5,
      tinggiBadan: 64.0,
      lingkarKepala: 42.0,
      statusGizi: 'Normal',
      indikasiStunting: false,
      kaderId: 'kader_001',
    );
    await _db
        .collection('pemeriksaan_balita')
        .doc(pemeriksaanId)
        .set(pemeriksaan.toMap());

    print("Seeder selesai!");
  }
}
