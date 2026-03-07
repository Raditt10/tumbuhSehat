import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/orang_tua_model.dart';
import '../models/kader_model.dart';
import '../models/balita_model.dart';
import '../models/pemeriksaan_balita_model.dart';
import '../models/riwayat_imunisasi_model.dart';
import '../models/master_imunisasi_model.dart';
import '../models/ibu_hamil_model.dart';
import '../models/pemeriksaan_bumil_model.dart';
import '../models/jadwal_posyandu_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Users ---
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

  // Update user's photo URL
  Future<void> updateUserPhotoUrl(String uid, String photoUrl) async {
    try {
      await _db.collection('users').doc(uid).update({'photoUrl': photoUrl});
    } catch (e) {
      print("Error updating user photo url: $e");
      rethrow;
    }
  }

  // Save profile picture as Base64 directly to Firestore (no Storage needed)
  Future<void> uploadProfilePicture(String uid, File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('File gambar tidak ditemukan');
      }

      final bytes = await imageFile.readAsBytes();
      print('[Photo] File size: ${bytes.length} bytes');

      if (bytes.length > 900 * 1024) {
        // Firestore doc limit is 1MB, warn if close
        throw Exception(
          'Ukuran foto terlalu besar (${(bytes.length / 1024).toStringAsFixed(0)} KB). '
          'Pilih foto yang lebih kecil atau kurangi kualitas.',
        );
      }

      final base64Str = base64Encode(bytes);
      print('[Photo] Base64 length: ${base64Str.length} chars');

      // Store base64 directly in Firestore user doc
      await _db.collection('users').doc(uid).update({'photoBase64': base64Str});

      print('[Photo] Uploaded base64 to Firestore successfully');
    } catch (e) {
      print('[Photo] Error: $e');
      rethrow;
    }
  }

  // --- Kader / Bidan ---
  Future<KaderModel?> getKaderByUserId(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('kader')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        return KaderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Error getting kader data: \$e");
      return null;
    }
  }

  // --- Orang Tua ---
  Future<OrangTuaModel?> getOrangTuaByUserId(String userId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('orang_tua')
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        var doc = snapshot.docs.first;
        return OrangTuaModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print("Error getting orang_tua data: \$e");
      return null;
    }
  }

  Future<void> saveOrangTua(OrangTuaModel orangTua) async {
    try {
      if (orangTua.id.isEmpty) {
        await _db.collection('orang_tua').add(orangTua.toMap());
      } else {
        await _db
            .collection('orang_tua')
            .doc(orangTua.id)
            .update(orangTua.toMap());
      }
    } catch (e) {
      print("Error saving orang_tua: $e");
      rethrow;
    }
  }

  // --- Balita ---
  Stream<List<BalitaModel>> streamBalitaByOrangTua(String orangTuaId) {
    return _db
        .collection('balita')
        .where('orang_tua_id', isEqualTo: orangTuaId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BalitaModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Stream<List<BalitaModel>> streamAllBalita() {
    return _db
        .collection('balita')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BalitaModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // --- Balita ---
  Future<void> saveBalita(BalitaModel balita) async {
    try {
      if (balita.id.isEmpty) {
        await _db.collection('balita').add(balita.toMap());
      } else {
        await _db.collection('balita').doc(balita.id).update(balita.toMap());
      }
    } catch (e) {
      print("Error saving balita: $e");
      rethrow;
    }
  }

  Stream<List<PemeriksaanBalitaModel>> streamPemeriksaanBalita(
    String balitaId,
  ) {
    return _db
        .collection('pemeriksaan_balita')
        .where('balita_id', isEqualTo: balitaId)
        // You might want to sort by date, requiring a timestamp on this collection or via Schedule
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PemeriksaanBalitaModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Example: Add a new Pemeriksaan
  Future<void> addPemeriksaanBalita(PemeriksaanBalitaModel pemeriksaan) async {
    try {
      await _db.collection('pemeriksaan_balita').add(pemeriksaan.toMap());
    } catch (e) {
      print("Error adding pemeriksaan: $e");
      rethrow;
    }
  }

  Future<void> updatePemeriksaanBalita(PemeriksaanBalitaModel pemeriksaan) async {
    try {
      await _db.collection('pemeriksaan_balita').doc(pemeriksaan.id).update(pemeriksaan.toMap());
    } catch (e) {
      print("Error updating pemeriksaan: $e");
      rethrow;
    }
  }

  Future<void> deletePemeriksaanBalitaById(String id) async {
    try {
      await _db.collection('pemeriksaan_balita').doc(id).delete();
    } catch (e) {
      print("Error deleting pemeriksaan: $e");
      rethrow;
    }
  }

  // --- Riwayat Imunisasi ---
  Stream<List<RiwayatImunisasiModel>> streamRiwayatImunisasi(String balitaId) {
    return _db
        .collection('riwayat_imunisasi')
        .where('balita_id', isEqualTo: balitaId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RiwayatImunisasiModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // --- Master Imunisasi ---
  Future<List<MasterImunisasiModel>> getAllMasterImunisasi() async {
    try {
      final snapshot = await _db.collection('master_imunisasi').get();
      return snapshot.docs
          .map((doc) => MasterImunisasiModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching master imunisasi: $e');
      return [];
    }
  }

  Future<MasterImunisasiModel?> getMasterImunisasiById(String id) async {
    try {
      final doc = await _db.collection('master_imunisasi').doc(id).get();
      if (doc.exists) {
        return MasterImunisasiModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error fetching master imunisasi by id: $e');
      return null;
    }
  }

  // --- Kader Count ---
  Future<Map<String, int>> getKaderCountByJabatan() async {
    try {
      final snapshot = await _db.collection('kader').get();
      int bidan = 0;
      int kader = 0;
      for (final doc in snapshot.docs) {
        final jabatan = (doc.data()['jabatan'] ?? '') as String;
        if (jabatan.toLowerCase().contains('bidan')) {
          bidan++;
        } else {
          kader++;
        }
      }
      return {'bidan': bidan, 'kader': kader};
    } catch (e) {
      print('Error counting kader: $e');
      return {'bidan': 0, 'kader': 0};
    }
  }

  Future<void> deleteLatestPemeriksaanBalita(String balitaId) async {
    try {
      // Fetch all checkups for this child to sort in memory (avoids composite index error)
      QuerySnapshot snapshot = await _db
          .collection('pemeriksaan_balita')
          .where('balita_id', isEqualTo: balitaId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final docs = snapshot.docs.toList();
        // Sort descending by usia_saat_periksa
        docs.sort((a, b) {
          final ageA =
              (a.data() as Map<String, dynamic>)['usia_saat_periksa'] ?? 0;
          final ageB =
              (b.data() as Map<String, dynamic>)['usia_saat_periksa'] ?? 0;
          return (ageB as int).compareTo(ageA as int);
        });

        await docs.first.reference.delete();
      } else {
        throw Exception('Tidak ada data pemeriksaan yang bisa dihapus.');
      }
    } catch (e) {
      print("Error deleting latest pemeriksaan: $e");
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // IBU HAMIL
  // ══════════════════════════════════════════════════════════════════════════

  Future<IbuHamilModel?> getIbuHamilByOrangTuaId(String orangTuaId) async {
    try {
      final snapshot = await _db
          .collection('ibu_hamil')
          .where('orang_tua_id', isEqualTo: orangTuaId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        return IbuHamilModel.fromMap(doc.data(), doc.id);
      }
      return null;
    } catch (e) {
      print("Error getting ibu hamil: $e");
      return null;
    }
  }

  Stream<List<IbuHamilModel>> streamIbuHamilByOrangTua(String orangTuaId) {
    return _db
        .collection('ibu_hamil')
        .where('orang_tua_id', isEqualTo: orangTuaId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IbuHamilModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<IbuHamilModel>> streamAllIbuHamil() {
    return _db.collection('ibu_hamil').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => IbuHamilModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveIbuHamil(IbuHamilModel data) async {
    try {
      if (data.id.isEmpty) {
        await _db.collection('ibu_hamil').add(data.toMap());
      } else {
        await _db.collection('ibu_hamil').doc(data.id).update(data.toMap());
      }
    } catch (e) {
      print("Error saving ibu hamil: $e");
      rethrow;
    }
  }

  Future<void> deleteIbuHamil(String id) async {
    await _db.collection('ibu_hamil').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // PEMERIKSAAN BUMIL
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<PemeriksaanBumilModel>> streamPemeriksaanBumil(String ibuHamilId) {
    return _db
        .collection('pemeriksaan_bumil')
        .where('ibu_hamil_id', isEqualTo: ibuHamilId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PemeriksaanBumilModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addPemeriksaanBumil(PemeriksaanBumilModel data) async {
    try {
      await _db.collection('pemeriksaan_bumil').add(data.toMap());
    } catch (e) {
      print("Error adding pemeriksaan bumil: $e");
      rethrow;
    }
  }

  Future<void> updatePemeriksaanBumil(PemeriksaanBumilModel data) async {
    try {
      await _db.collection('pemeriksaan_bumil').doc(data.id).update(data.toMap());
    } catch (e) {
      print("Error updating pemeriksaan bumil: $e");
      rethrow;
    }
  }

  Future<void> deletePemeriksaanBumil(String id) async {
    await _db.collection('pemeriksaan_bumil').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // JADWAL POSYANDU
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<JadwalPosyanduModel>> streamJadwalPosyandu() {
    return _db.collection('jadwal_posyandu').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => JadwalPosyanduModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveJadwalPosyandu(JadwalPosyanduModel data) async {
    try {
      if (data.id.isEmpty) {
        await _db.collection('jadwal_posyandu').add(data.toMap());
      } else {
        await _db.collection('jadwal_posyandu').doc(data.id).update(data.toMap());
      }
    } catch (e) {
      print("Error saving jadwal: $e");
      rethrow;
    }
  }

  Future<void> deleteJadwalPosyandu(String id) async {
    await _db.collection('jadwal_posyandu').doc(id).delete();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // KADER CRUD
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<KaderModel>> streamAllKader() {
    return _db.collection('kader').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => KaderModel.fromMap(doc.data(), doc.id))
        .toList());
  }

  /// Stream users with role 'kader' from the users collection
  Stream<List<UserModel>> streamKaderUsers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'kader')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> saveKader(KaderModel data) async {
    try {
      if (data.id.isEmpty) {
        await _db.collection('kader').add(data.toMap());
      } else {
        await _db.collection('kader').doc(data.id).update(data.toMap());
      }
    } catch (e) {
      print("Error saving kader: $e");
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ORANG TUA (additional stream)
  // ══════════════════════════════════════════════════════════════════════════

  Stream<List<OrangTuaModel>> streamAllOrangTua() {
    return _db.collection('orang_tua').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => OrangTuaModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
