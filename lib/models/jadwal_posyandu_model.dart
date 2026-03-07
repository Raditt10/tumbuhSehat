import 'package:cloud_firestore/cloud_firestore.dart';

class JadwalPosyanduModel {
  final String id;
  final DateTime tanggalKegiatan;
  final String lokasi;
  final String keterangan;
  final String? kaderNama;
  final String? kaderNoHp;

  JadwalPosyanduModel({
    required this.id,
    required this.tanggalKegiatan,
    required this.lokasi,
    required this.keterangan,
    this.kaderNama,
    this.kaderNoHp,
  });

  factory JadwalPosyanduModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return JadwalPosyanduModel(
      id: documentId,
      tanggalKegiatan:
          (data['tanggal_kegiatan'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lokasi: data['lokasi'] ?? '',
      keterangan: data['keterangan'] ?? '',
      kaderNama: data['kader_nama'],
      kaderNoHp: data['kader_no_hp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tanggal_kegiatan': Timestamp.fromDate(tanggalKegiatan),
      'lokasi': lokasi,
      'keterangan': keterangan,
      if (kaderNama != null) 'kader_nama': kaderNama,
      if (kaderNoHp != null) 'kader_no_hp': kaderNoHp,
    };
  }
}
