class MasterVitaminModel {
  final String id;
  final String namaVitamin; // e.g., 'Vitamin A Merah'
  final int usiaWajibBulan;
  final String keterangan;

  MasterVitaminModel({
    required this.id,
    required this.namaVitamin,
    required this.usiaWajibBulan,
    required this.keterangan,
  });

  factory MasterVitaminModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return MasterVitaminModel(
      id: documentId,
      namaVitamin: data['nama_vitamin'] ?? '',
      usiaWajibBulan: data['usia_wajib_bulan'] ?? 0,
      keterangan: data['keterangan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_vitamin': namaVitamin,
      'usia_wajib_bulan': usiaWajibBulan,
      'keterangan': keterangan,
    };
  }
}
