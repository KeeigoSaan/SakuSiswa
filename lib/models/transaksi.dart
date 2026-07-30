/// Model data untuk satu transaksi pengeluaran siswa.
class Transaksi {
  final String judul;
  final int nominal;
  final String tanggal;

  Transaksi({
    required this.judul,
    required this.nominal,
    required this.tanggal,
  });

  /// SharedPreferences hanya bisa menyimpan tipe primitif,
  /// jadi objek ini harus diubah dulu ke Map sebelum di-jsonEncode.
  Map<String, dynamic> toJson() {
    return {
      'judul': judul,
      'nominal': nominal,
      'tanggal': tanggal,
    };
  }

  /// Membentuk ulang objek Transaksi dari Map hasil jsonDecode.
  factory Transaksi.fromJson(Map<String, dynamic> json) {
    return Transaksi(
      judul: json['judul'] as String,
      nominal: json['nominal'] as int,
      tanggal: json['tanggal'] as String,
    );
  }
}
