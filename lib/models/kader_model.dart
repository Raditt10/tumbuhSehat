class KaderModel {
  final String id;
  final String userId; // Reference to UserModel
  final String namaLengkap;
  final String jabatan; // 'Kader Posyandu' / 'Bidan Desa'
  final String noHp;

  KaderModel({
    required this.id,
    required this.userId,
    required this.namaLengkap,
    required this.jabatan,
    required this.noHp,
  });

  factory KaderModel.fromMap(Map<String, dynamic> data, String documentId) {
    return KaderModel(
      id: documentId,
      userId: data['user_id'] ?? '',
      namaLengkap: data['nama_lengkap'] ?? '',
      jabatan: data['jabatan'] ?? 'Kader Posyandu',
      noHp: data['no_hp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'nama_lengkap': namaLengkap,
      'jabatan': jabatan,
      'no_hp': noHp,
    };
  }
}
