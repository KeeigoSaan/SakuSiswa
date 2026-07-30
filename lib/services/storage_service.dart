import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaksi.dart';

/// Service untuk mengelola penyimpanan lokal permanen (saldo & riwayat
/// pengeluaran) menggunakan SharedPreferences.
///
/// Semua method bersifat static, jadi tidak perlu membuat instance:
/// contoh pemakaian -> StorageService.muatSaldo()
class StorageService {
  StorageService._(); // Mencegah class ini diinstansiasi.

  static const String _keySaldo = 'total_saldo';
  static const String _keyRiwayat = 'riwayat';

  // ---------------- SALDO ---------------- //

  /// Membaca saldo tersimpan. Default 0 jika belum pernah disimpan.
  static Future<int> muatSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySaldo) ?? 0;
  }

  /// Menyimpan nilai saldo terbaru.
  static Future<void> simpanSaldo(int saldo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySaldo, saldo);
  }

  // ---------------- RIWAYAT ---------------- //

  /// Membaca daftar riwayat pengeluaran.
  /// List<String> JSON hasil penyimpanan di-decode kembali menjadi
  /// List<Transaksi>.
  static Future<List<Transaksi>> muatRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStringList = prefs.getStringList(_keyRiwayat) ?? [];

    return dataStringList
        .map((item) => Transaksi.fromJson(jsonDecode(item)))
        .toList();
  }

  /// Menyimpan seluruh daftar riwayat.
  /// Setiap Transaksi di-encode dulu ke String JSON karena
  /// SharedPreferences hanya menerima List<String>.
  static Future<void> simpanRiwayat(List<Transaksi> riwayat) async {
    final prefs = await SharedPreferences.getInstance();
    final dataStringList =
        riwayat.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_keyRiwayat, dataStringList);
  }

  // ---------------- LOGIKA GABUNGAN ---------------- //

  /// Menambah uang saku ke saldo, lalu langsung disimpan.
  /// Mengembalikan saldo terbaru.
  static Future<int> tambahSaldo(int nominal) async {
    final saldoSaatIni = await muatSaldo();
    final saldoBaru = saldoSaatIni + nominal;
    await simpanSaldo(saldoBaru);
    return saldoBaru;
  }

  /// Mencatat pengeluaran baru: mengurangi saldo, menambah item riwayat
  /// paling atas, lalu menyimpan keduanya sekaligus.
  /// Mengembalikan saldo & riwayat terbaru agar UI tinggal setState.
  static Future<({int saldo, List<Transaksi> riwayat})> tambahPengeluaran({
    required String judul,
    required int nominal,
  }) async {
    if (judul.isEmpty || nominal <= 0) {
      final saldo = await muatSaldo();
      final riwayat = await muatRiwayat();
      return (saldo: saldo, riwayat: riwayat);
    }

    final saldoSaatIni = await muatSaldo();
    final riwayatSaatIni = await muatRiwayat();

    final saldoBaru = saldoSaatIni - nominal;
    final riwayatBaru = List<Transaksi>.from(riwayatSaatIni)
      ..insert(
        0,
        Transaksi(
          judul: judul,
          nominal: nominal,
          tanggal: DateTime.now().toString().substring(0, 10),
        ),
      );

    await simpanSaldo(saldoBaru);
    await simpanRiwayat(riwayatBaru);

    return (saldo: saldoBaru, riwayat: riwayatBaru);
  }
}
