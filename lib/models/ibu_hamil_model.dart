import 'package:cloud_firestore/cloud_firestore.dart';

class IbuHamilModel {
  final String id;
  final String orangTuaId; // Reference to OrangTuaModel
  final DateTime hpht; // Hari Pertama Haid Terakhir
  final DateTime hpl; // Hari Perkiraan Lahir
  final int kehamilanKe;
  final String riwayatPenyakit;

  IbuHamilModel({
    required this.id,
    required this.orangTuaId,
    required this.hpht,
    required this.hpl,
    required this.kehamilanKe,
    required this.riwayatPenyakit,
  });

  factory IbuHamilModel.fromMap(Map<String, dynamic> data, String documentId) {
    return IbuHamilModel(
      id: documentId,
      orangTuaId: data['orang_tua_id'] ?? '',
      hpht: (data['hpht'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hpl: (data['hpl'] as Timestamp?)?.toDate() ?? DateTime.now(),
      kehamilanKe: data['kehamilan_ke'] ?? 1,
      riwayatPenyakit: data['riwayat_penyakit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orang_tua_id': orangTuaId,
      'hpht': Timestamp.fromDate(hpht),
      'hpl': Timestamp.fromDate(hpl),
      'kehamilan_ke': kehamilanKe,
      'riwayat_penyakit': riwayatPenyakit,
    };
  }
}
