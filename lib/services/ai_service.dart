import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/balita_model.dart';
import '../models/pemeriksaan_balita_model.dart';

class AIService {
  // Google AI Studio (Gemini) API Key
  static const String _geminiApiKey = 'AIzaSyA5TXGCSZfCm8zZF-pNPTBa8lcMK-obM7o';

  static const _whoRef = <List<double>>[
    [0, 2.1, 2.5, 3.3, 2.0, 2.4, 3.2],
    [1, 2.9, 3.4, 4.5, 2.7, 3.2, 4.2],
    [2, 3.8, 4.3, 5.6, 3.4, 3.9, 5.1],
    [3, 4.4, 5.0, 6.4, 4.0, 4.5, 5.8],
    [4, 4.9, 5.6, 7.0, 4.4, 5.0, 6.4],
    [5, 5.3, 6.0, 7.5, 4.8, 5.4, 6.9],
    [6, 5.7, 6.4, 7.9, 5.1, 5.7, 7.3],
    [7, 5.9, 6.7, 8.3, 5.3, 6.0, 7.6],
    [8, 6.2, 7.0, 8.6, 5.6, 6.3, 7.9],
    [9, 6.4, 7.2, 8.9, 5.8, 6.5, 8.2],
    [10, 6.6, 7.5, 9.2, 6.0, 6.7, 8.5],
    [11, 6.8, 7.7, 9.4, 6.1, 6.9, 8.7],
    [12, 6.9, 7.8, 9.6, 6.3, 7.1, 8.9],
    [15, 7.4, 8.4, 10.3, 6.8, 7.6, 9.6],
    [18, 7.7, 8.8, 10.9, 7.2, 8.1, 10.2],
    [21, 8.1, 9.2, 11.5, 7.6, 8.6, 10.9],
    [24, 8.6, 9.7, 12.2, 8.1, 9.0, 11.5],
    [30, 9.4, 10.7, 13.3, 8.8, 9.9, 12.8],
    [36, 10.0, 11.4, 14.3, 9.5, 10.7, 13.9],
    [48, 11.3, 12.9, 16.3, 10.8, 12.1, 15.8],
    [60, 12.7, 14.4, 18.3, 12.1, 13.7, 17.7],
  ];

  static Map<String, double>? _whoAt(int usiaBulan, String jenisKelamin) {
    final isL = jenisKelamin == 'L';
    List<double>? lower, upper;
    for (int i = 0; i < _whoRef.length; i++) {
      if (_whoRef[i][0] == usiaBulan.toDouble()) {
        return {
          'minus3sd': isL ? _whoRef[i][1] : _whoRef[i][4],
          'minus2sd': isL ? _whoRef[i][2] : _whoRef[i][5],
          'median': isL ? _whoRef[i][3] : _whoRef[i][6],
        };
      }
      if (_whoRef[i][0] < usiaBulan) lower = _whoRef[i];
      if (_whoRef[i][0] > usiaBulan && upper == null) upper = _whoRef[i];
    }
    if (lower == null || upper == null) return null;
    // Linear interpolation
    final t = (usiaBulan - lower[0]) / (upper[0] - lower[0]);
    double lerp(double a, double b) => a + (b - a) * t;
    return {
      'minus3sd': lerp(isL ? lower[1] : lower[4], isL ? upper[1] : upper[4]),
      'minus2sd': lerp(isL ? lower[2] : lower[5], isL ? upper[2] : upper[5]),
      'median': lerp(isL ? lower[3] : lower[6], isL ? upper[3] : upper[6]),
    };
  }

  /// Classify weight against WHO reference
  static String _classifyWeight(double bb, Map<String, double> who) {
    if (bb < who['minus3sd']!) return 'Gizi Buruk (di bawah -3SD)';
    if (bb < who['minus2sd']!) return 'Gizi Kurang (di bawah -2SD)';
    return 'Normal';
  }

  /// Detect trend from pemeriksaan data
  static String _detectTrend(List<PemeriksaanBalitaModel> sorted) {
    if (sorted.length < 2) return 'belum cukup data untuk menilai tren';
    final last = sorted.last;
    final prev = sorted[sorted.length - 2];
    final diff = last.beratBadan - prev.beratBadan;
    final months = last.usiaSaatPeriksa - prev.usiaSaatPeriksa;
    if (months <= 0) return 'data usia tidak konsisten';
    final ratePerMonth = diff / months;
    if (ratePerMonth < 0) return 'berat badan MENURUN (${diff.toStringAsFixed(1)} kg dalam $months bulan) — perlu perhatian serius';
    if (ratePerMonth < 0.1) return 'kenaikan berat badan SANGAT LAMBAT (${diff.toStringAsFixed(1)} kg dalam $months bulan) — perlu evaluasi';
    if (ratePerMonth < 0.3) return 'kenaikan berat badan cukup (${diff.toStringAsFixed(1)} kg dalam $months bulan)';
    return 'kenaikan berat badan baik (${diff.toStringAsFixed(1)} kg dalam $months bulan)';
  }

  static Future<String> analyzeKesehatan(
    BalitaModel balita,
    List<PemeriksaanBalitaModel> pemeriksaanList,
  ) async {
    // Sort ascending by age
    final sorted = List<PemeriksaanBalitaModel>.from(pemeriksaanList)
      ..sort((a, b) => a.usiaSaatPeriksa.compareTo(b.usiaSaatPeriksa));

    final prompt = _buildPrompt(balita, sorted);

    // Call Google Gemini API, fallback to local analysis on failure
    try {
      return await _callGemini(prompt);
    } catch (_) {
      if (sorted.isEmpty) {
        final age = _calculateAge(balita.tanggalLahir);
        return '📊 **Data Anak: ${balita.namaAnak}**\n\n'
            '• Jenis Kelamin: ${balita.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'}\n'
            '• Usia: $age\n'
            '• Berat Lahir: ${balita.beratLahir} kg\n'
            '• Tinggi Lahir: ${balita.tinggiLahir} cm\n\n'
            '⚠️ Belum ada data pemeriksaan dari posyandu.\n'
            'Silakan tambahkan data pertumbuhan melalui tombol "Tambah" di bagian Data Pertumbuhan agar AI dapat menganalisis kondisi anak secara lengkap.\n\n'
            '💡 Pastikan rutin ke posyandu setiap bulan untuk pemantauan tumbuh kembang.';
      }
      return _generateSmartAnalysis(balita, sorted);
    }
  }

  // ── Smart local analysis (no API key needed) ────────────────────────────
  static String _generateSmartAnalysis(
    BalitaModel balita,
    List<PemeriksaanBalitaModel> sorted,
  ) {
    final last = sorted.last;
    final who = _whoAt(last.usiaSaatPeriksa, balita.jenisKelamin);
    final gender = balita.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan';
    final trend = _detectTrend(sorted);

    final buf = StringBuffer();
    buf.writeln('📊 **Analisis Pertumbuhan ${balita.namaAnak}**');
    buf.writeln('Gender: $gender • Usia terakhir: ${last.usiaSaatPeriksa} bulan');
    buf.writeln('');

    // Current weight analysis
    buf.writeln('**📏 Data Terakhir:**');
    buf.writeln('• Berat: ${last.beratBadan} kg');
    buf.writeln('• Tinggi: ${last.tinggiBadan} cm');
    buf.writeln('• Lingkar Kepala: ${last.lingkarKepala} cm');
    buf.writeln('');

    // WHO comparison
    if (who != null) {
      final classification = _classifyWeight(last.beratBadan, who);
      buf.writeln('**📋 Perbandingan Standar WHO ($gender):**');
      buf.writeln('• Median BB usia ${last.usiaSaatPeriksa} bln: ${who['median']!.toStringAsFixed(1)} kg');
      buf.writeln('• Batas -2SD: ${who['minus2sd']!.toStringAsFixed(1)} kg');
      buf.writeln('• Batas -3SD: ${who['minus3sd']!.toStringAsFixed(1)} kg');
      buf.writeln('• BB Anak: ${last.beratBadan} kg → **$classification**');

      final diff = last.beratBadan - who['median']!;
      if (diff >= 0) {
        buf.writeln('• ✅ BB di atas median (+${diff.toStringAsFixed(1)} kg)');
      } else {
        buf.writeln('• ⚠️ BB di bawah median (${diff.toStringAsFixed(1)} kg)');
      }
      buf.writeln('');
    }

    // Trend
    buf.writeln('**📈 Tren Pertumbuhan:**');
    buf.writeln('• $trend');
    if (last.indikasiStunting) {
      buf.writeln('• 🔴 Terdeteksi indikasi stunting');
    }
    buf.writeln('');

    // Growth history
    if (sorted.length > 1) {
      buf.writeln('**📅 Riwayat (${sorted.length} data):**');
      for (final d in sorted) {
        final whoD = _whoAt(d.usiaSaatPeriksa, balita.jenisKelamin);
        String marker = '';
        if (whoD != null) {
          if (d.beratBadan < whoD['minus3sd']!) {
            marker = ' 🔴';
          } else if (d.beratBadan < whoD['minus2sd']!) {
            marker = ' 🟠';
          } else {
            marker = ' 🟢';
          }
        }
        buf.writeln('• ${d.usiaSaatPeriksa} bln: ${d.beratBadan} kg / ${d.tinggiBadan} cm$marker');
      }
      buf.writeln('');
    }

    // Recommendations
    buf.writeln('**💡 Rekomendasi:**');
    final isUnderweight = who != null && last.beratBadan < who['minus2sd']!;
    final isSevere = who != null && last.beratBadan < who['minus3sd']!;

    if (isSevere) {
      buf.writeln('1. ⚠️ SEGERA konsultasikan ke dokter anak atau puskesmas');
      buf.writeln('2. Berikan makanan tinggi kalori & protein: telur, ikan, hati ayam, susu');
      buf.writeln('3. Tambahkan minyak/mentega pada makanan untuk meningkatkan kalori');
      buf.writeln('4. Pantau berat badan setiap minggu');
      buf.writeln('5. Pastikan anak tidak ada infeksi berulang (diare, ISPA)');
    } else if (isUnderweight || last.indikasiStunting) {
      buf.writeln('1. Perbanyak protein hewani: telur, ikan, daging, susu');
      buf.writeln('2. Berikan makanan 3x sehari + 2x snack bergizi');
      buf.writeln('3. Konsultasikan dengan bidan/ahli gizi di posyandu');
      buf.writeln('4. Pastikan imunisasi lengkap dan stimulasi sesuai usia');
      buf.writeln('5. Rutin datang ke posyandu setiap bulan');
    } else {
      buf.writeln('1. ✅ Pertumbuhan baik! Teruskan pola makan bergizi seimbang');
      buf.writeln('2. Berikan variasi makanan: karbohidrat, protein, sayur, buah');
      buf.writeln('3. Pastikan anak aktif bermain untuk stimulasi motorik');
      buf.writeln('4. Tetap rutin ke posyandu untuk pemantauan');
    }

    return buf.toString();
  }

  // ── Google Gemini API call ──────────────────────────────────────────────
  static Future<String> _callGemini(String prompt) async {
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_geminiApiKey',
    );

    final systemInstruction =
        'Kamu adalah dokter spesialis anak berpengalaman di Indonesia. '
        'Berikan analisis berdasarkan data tumbuh kembang KMS (Kartu Menuju Sehat) '
        'dan standar WHO Weight-for-Age. Jawab dalam Bahasa Indonesia yang ramah, '
        'profesional, dan mudah dipahami ibu. Gunakan emoji untuk penanda. '
        'Selalu bandingkan BB anak dengan median & -2SD WHO sesuai gender. '
        'Berikan rekomendasi nutrisi spesifik. Maksimal 3-4 paragraf.';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'system_instruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.7,
          'maxOutputTokens': 1024,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final parts = candidates[0]['content']['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          return parts[0]['text'] ?? 'AI tidak memberikan respon.';
        }
      }
      return 'AI tidak memberikan respon yang valid.';
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  // ── Build detailed prompt for Gemini ─────────────────────────────────────
  static String _buildPrompt(
    BalitaModel balita,
    List<PemeriksaanBalitaModel> sorted,
  ) {
    if (sorted.isEmpty) {
      return 'Analisis data anak dari database:\n'
          'Nama: ${balita.namaAnak}\n'
          'Jenis Kelamin: ${balita.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'}\n'
          'Tanggal Lahir: ${balita.tanggalLahir.day}/${balita.tanggalLahir.month}/${balita.tanggalLahir.year}\n'
          'Usia saat ini: ${_calculateAge(balita.tanggalLahir)}\n'
          'Berat Lahir: ${balita.beratLahir} kg\n'
          'Tinggi Lahir: ${balita.tinggiLahir} cm\n\n'
          'Belum ada data pemeriksaan posyandu. '
          'Berdasarkan data lahir di atas, berikan analisis apakah berat dan tinggi lahirnya normal, '
          'serta saran untuk ibu agar rutin ke posyandu. Sebutkan jadwal imunisasi yang sesuai usianya.';
    }

    final last = sorted.last;
    final who = _whoAt(last.usiaSaatPeriksa, balita.jenisKelamin);

    final history = sorted
        .map((d) =>
            '- Usia ${d.usiaSaatPeriksa} bln: BB ${d.beratBadan}kg, TB ${d.tinggiBadan}cm, '
            'LK ${d.lingkarKepala}cm, Status: ${d.statusGizi}, Stunting: ${d.indikasiStunting ? 'Ya' : 'Tidak'}')
        .join('\n');

    final whoInfo = who != null
        ? '\nReferensi WHO untuk usia ${last.usiaSaatPeriksa} bulan (${balita.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'}):\n'
          '- Median: ${who['median']!.toStringAsFixed(1)} kg\n'
          '- Batas -2SD: ${who['minus2sd']!.toStringAsFixed(1)} kg\n'
          '- Batas -3SD: ${who['minus3sd']!.toStringAsFixed(1)} kg\n'
        : '';

    return '''
Analisis kesehatan anak:
Nama: ${balita.namaAnak}
Jenis Kelamin: ${balita.jenisKelamin == 'L' ? 'Laki-laki' : 'Perempuan'}
Tanggal Lahir: ${balita.tanggalLahir.day}/${balita.tanggalLahir.month}/${balita.tanggalLahir.year}
Usia: ${_calculateAge(balita.tanggalLahir)}
Berat Lahir: ${balita.beratLahir} kg
Tinggi Lahir: ${balita.tinggiLahir} cm
$whoInfo
Riwayat Pemeriksaan (${sorted.length} data):
$history

Bandingkan BB terakhir (${last.beratBadan} kg) dengan standar WHO. Analisis trennya dan berikan rekomendasi nutrisi spesifik.
''';
  }

  static String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    if (months < 0) {
      years--;
      months += 12;
    }
    return '$years tahun $months bulan';
  }
}
