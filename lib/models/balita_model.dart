import 'package:cloud_firestore/cloud_firestore.dart';

class BalitaModel {
  final String id;
  final String orangTuaId; // Reference to OrangTuaModel
  final String nikAnak;
  final String namaAnak;
  final String jenisKelamin; // 'L' or 'P'
  final String tempatLahir;
  final DateTime tanggalLahir;
  final double beratLahir; // in kg
  final double tinggiLahir; // in cm
  final int anakKe;

  BalitaModel({
    required this.id,
    required this.orangTuaId,
    required this.nikAnak,
    required this.namaAnak,
    required this.jenisKelamin,
    required this.tempatLahir,
    required this.tanggalLahir,
    required this.beratLahir,
    required this.tinggiLahir,
    required this.anakKe,
  });

  factory BalitaModel.fromMap(Map<String, dynamic> data, String documentId) {
    return BalitaModel(
      id: documentId,
      orangTuaId: data['orang_tua_id'] ?? '',
      nikAnak: data['nik_anak'] ?? '',
      namaAnak: data['nama_anak'] ?? '',
      jenisKelamin: data['jenis_kelamin'] ?? 'L',
      tempatLahir: data['tempat_lahir'] ?? '',
      tanggalLahir:
          (data['tanggal_lahir'] as Timestamp?)?.toDate() ?? DateTime.now(),
      beratLahir: (data['berat_lahir'] ?? 0).toDouble(),
      tinggiLahir: (data['tinggi_lahir'] ?? 0).toDouble(),
      anakKe: data['anak_ke'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orang_tua_id': orangTuaId,
      'nik_anak': nikAnak,
      'nama_anak': namaAnak,
      'jenis_kelamin': jenisKelamin,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': Timestamp.fromDate(tanggalLahir),
      'berat_lahir': beratLahir,
      'tinggi_lahir': tinggiLahir,
      'anak_ke': anakKe,
    };
  }
}
