class MasterImunisasiModel {
  final String id;
  final String namaImunisasi; // e.g., 'BCG', 'Polio 1'
  final int usiaWajibBulan; // Age in months when it should be given
  final String keterangan;

  MasterImunisasiModel({
    required this.id,
    required this.namaImunisasi,
    required this.usiaWajibBulan,
    required this.keterangan,
  });

  factory MasterImunisasiModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return MasterImunisasiModel(
      id: documentId,
      namaImunisasi: data['nama_imunisasi'] ?? '',
      usiaWajibBulan: data['usia_wajib_bulan'] ?? 0,
      keterangan: data['keterangan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama_imunisasi': namaImunisasi,
      'usia_wajib_bulan': usiaWajibBulan,
      'keterangan': keterangan,
    };
  }
}
