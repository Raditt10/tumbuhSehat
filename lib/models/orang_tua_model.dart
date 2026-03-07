class OrangTuaModel {
  final String id;
  final String userId; // Reference to UserModel
  final String noKk;
  final String nikIbu;
  final String namaIbu;
  final String nikAyah;
  final String namaAyah;
  final String alamat;
  final String noHp;

  OrangTuaModel({
    required this.id,
    required this.userId,
    required this.noKk,
    required this.nikIbu,
    required this.namaIbu,
    required this.nikAyah,
    required this.namaAyah,
    required this.alamat,
    required this.noHp,
  });

  factory OrangTuaModel.fromMap(Map<String, dynamic> data, String documentId) {
    return OrangTuaModel(
      id: documentId,
      userId: data['user_id'] ?? '',
      noKk: data['no_kk'] ?? '',
      nikIbu: data['nik_ibu'] ?? '',
      namaIbu: data['nama_ibu'] ?? '',
      nikAyah: data['nik_ayah'] ?? '',
      namaAyah: data['nama_ayah'] ?? '',
      alamat: data['alamat'] ?? '',
      noHp: data['no_hp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'no_kk': noKk,
      'nik_ibu': nikIbu,
      'nama_ibu': namaIbu,
      'nik_ayah': nikAyah,
      'nama_ayah': namaAyah,
      'alamat': alamat,
      'no_hp': noHp,
    };
  }
}
