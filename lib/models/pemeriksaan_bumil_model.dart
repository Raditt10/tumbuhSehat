import 'package:cloud_firestore/cloud_firestore.dart';

class PemeriksaanBumilModel {
  final String id;
  final String ibuHamilId;
  final DateTime tanggalPeriksa;
  final int usiaKandunganMinggu;
  final double beratBadan;
  final String tekananDarah; // e.g., '120/80'
  final double lingkarLenganAtas;
  final String keluhan;

  PemeriksaanBumilModel({
    required this.id,
    required this.ibuHamilId,
    required this.tanggalPeriksa,
    required this.usiaKandunganMinggu,
    required this.beratBadan,
    required this.tekananDarah,
    required this.lingkarLenganAtas,
    required this.keluhan,
  });

  factory PemeriksaanBumilModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return PemeriksaanBumilModel(
      id: documentId,
      ibuHamilId: data['ibu_hamil_id'] ?? '',
      tanggalPeriksa:
          (data['tanggal_periksa'] as Timestamp?)?.toDate() ?? DateTime.now(),
      usiaKandunganMinggu: data['usia_kandungan_minggu'] ?? 0,
      beratBadan: (data['berat_badan'] ?? 0).toDouble(),
      tekananDarah: data['tekanan_darah'] ?? '',
      lingkarLenganAtas: (data['lingkar_lengan_atas'] ?? 0).toDouble(),
      keluhan: data['keluhan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ibu_hamil_id': ibuHamilId,
      'tanggal_periksa': Timestamp.fromDate(tanggalPeriksa),
      'usia_kandungan_minggu': usiaKandunganMinggu,
      'berat_badan': beratBadan,
      'tekanan_darah': tekananDarah,
      'lingkar_lengan_atas': lingkarLenganAtas,
      'keluhan': keluhan,
    };
  }
}
