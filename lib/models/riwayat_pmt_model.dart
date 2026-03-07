import 'package:cloud_firestore/cloud_firestore.dart';

class RiwayatPmtModel {
  final String id;
  final String targetId; // can be balita_id or ibu_hamil_id
  final String jenisPmt; // Vitamin A, Obat Cacing, Biskuit, dll
  final DateTime tanggalDiberikan;

  RiwayatPmtModel({
    required this.id,
    required this.targetId,
    required this.jenisPmt,
    required this.tanggalDiberikan,
  });

  factory RiwayatPmtModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return RiwayatPmtModel(
      id: documentId,
      targetId: data['target_id'] ?? '',
      jenisPmt: data['jenis_pmt'] ?? '',
      tanggalDiberikan:
          (data['tanggal_diberikan'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'target_id': targetId,
      'jenis_pmt': jenisPmt,
      'tanggal_diberikan': Timestamp.fromDate(tanggalDiberikan),
    };
  }
}
