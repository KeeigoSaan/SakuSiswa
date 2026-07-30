import 'package:flutter/material.dart';
import '../models/transaksi.dart';
import '../services/storage_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalSaldo = 0;
  List<Transaksi> _riwayatPengeluaran = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _muatDataAwal();
  }

  // Ambil data tersimpan (saldo & riwayat) saat aplikasi pertama dibuka.
  Future<void> _muatDataAwal() async {
    final saldo = await StorageService.muatSaldo();
    final riwayat = await StorageService.muatRiwayat();

    if (!mounted) return;
    setState(() {
      _totalSaldo = saldo;
      _riwayatPengeluaran = riwayat;
      _isLoading = false;
    });
  }

  // Tambah uang saku (+Rp50.000), lalu update UI dari hasil StorageService.
  Future<void> _isiUangSaku() async {
    final saldoBaru = await StorageService.tambahSaldo(50000);
    if (!mounted) return;
    setState(() => _totalSaldo = saldoBaru);
  }

  // Catat pengeluaran baru, lalu update UI dari hasil StorageService.
  Future<void> _tambahPengeluaran(String judul, int nominal) async {
    if (judul.isEmpty || nominal <= 0) return;

    final hasil = await StorageService.tambahPengeluaran(
      judul: judul,
      nominal: nominal,
    );

    if (!mounted) return;
    setState(() {
      _totalSaldo = hasil.saldo;
      _riwayatPengeluaran = hasil.riwayat;
    });
  }

  // Modal Bottom Sheet form input (UI Modern)
  void _tampilkanModalInput() {
    final judulController = TextEditingController();
    final nominalController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 20,
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tambah Pengeluaran', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: judulController,
              decoration: const InputDecoration(
                labelText: 'Keterangan (misal: Beli Pop Ice / Print Tugas)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nominal (Rp)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final judul = judulController.text.trim();
                  final nominal = int.tryParse(nominalController.text) ?? 0;
                  Navigator.pop(ctx);
                  _tambahPengeluaran(judul, nominal);
                },
                child: const Text('Simpan Pengeluaran'),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SakuSiswa Dashboard'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // CARD UI STANDAR INDUSTRI
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.teal.shade700,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const Text('Sisa Uang Saku Saat Ini',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      'Rp $_totalSaldo',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isiUangSaku,
                      icon: const Icon(Icons.add_card, color: Colors.white),
                      label: const Text('Isi Uang Saku (+Rp50.000)',
                          style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Riwayat Pengeluaran',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            // DYNAMIC LISTVIEW
            Expanded(
              child: _riwayatPengeluaran.isEmpty
                  ? const Center(child: Text('Belum ada pengeluaran hari ini. Hemat banget! 🎉'))
                  : ListView.builder(
                      itemCount: _riwayatPengeluaran.length,
                      itemBuilder: (context, index) {
                        final item = _riwayatPengeluaran[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.shopping_bag_outlined),
                            ),
                            title: Text(item.judul),
                            subtitle: Text(item.tanggal),
                            trailing: Text(
                              '- Rp ${item.nominal}',
                              style: const TextStyle(
                                  color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tampilkanModalInput,
        icon: const Icon(Icons.remove_circle_outline),
        label: const Text('Catat Pengeluaran'),
      ),
    );
  }
}
