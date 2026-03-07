class PemeriksaanBalitaModel {
  final String id;
  final String balitaId;
  final String jadwalId;
  final int usiaSaatPeriksa; // in months
  final double beratBadan;
  final double tinggiBadan;
  final double lingkarKepala;
  final String statusGizi; // e.g., Sangat Kurus, Kurus, Normal, Gemuk
  final bool indikasiStunting;
  final String kaderId; // the worker who did the checkup

  PemeriksaanBalitaModel({
    required this.id,
    required this.balitaId,
    required this.jadwalId,
    required this.usiaSaatPeriksa,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.lingkarKepala,
    required this.statusGizi,
    required this.indikasiStunting,
    required this.kaderId,
  });

  factory PemeriksaanBalitaModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return PemeriksaanBalitaModel(
      id: documentId,
      balitaId: data['balita_id'] ?? '',
      jadwalId: data['jadwal_id'] ?? '',
      usiaSaatPeriksa: data['usia_saat_periksa'] ?? 0,
      beratBadan: (data['berat_badan'] ?? 0).toDouble(),
      tinggiBadan: (data['tinggi_badan'] ?? 0).toDouble(),
      lingkarKepala: (data['lingkar_kepala'] ?? 0).toDouble(),
      statusGizi: data['status_gizi'] ?? 'Normal',
      indikasiStunting: data['indikasi_stunting'] ?? false,
      kaderId: data['kader_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balita_id': balitaId,
      'jadwal_id': jadwalId,
      'usia_saat_periksa': usiaSaatPeriksa,
      'berat_badan': beratBadan,
      'tinggi_badan': tinggiBadan,
      'lingkar_kepala': lingkarKepala,
      'status_gizi': statusGizi,
      'indikasi_stunting': indikasiStunting,
      'kader_id': kaderId,
    };
  }
}
