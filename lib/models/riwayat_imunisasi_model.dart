import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatImunisasiModel {
  final String id;
  final String balitaId;
  final String imunisasiId; // Reference to MasterImunisasiModel
  final DateTime tanggalDiberikan;
  final String keterangan;

  RiwayatImunisasiModel({
    required this.id,
    required this.balitaId,
    required this.imunisasiId,
    required this.tanggalDiberikan,
    required this.keterangan,
  });

  factory RiwayatImunisasiModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return RiwayatImunisasiModel(
      id: documentId,
      balitaId: data['balita_id'] ?? '',
      imunisasiId: data['imunisasi_id'] ?? '',
      tanggalDiberikan:
          (data['tanggal_diberikan'] as Timestamp?)?.toDate() ?? DateTime.now(),
      keterangan: data['keterangan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balita_id': balitaId,
      'imunisasi_id': imunisasiId,
      'tanggal_diberikan': Timestamp.fromDate(tanggalDiberikan),
      'keterangan': keterangan,
    };
  }
}
