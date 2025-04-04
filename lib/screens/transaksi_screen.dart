import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/transaction_model.dart';
import 'package:pos/models/debt_model.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _cartItems = [];
  double _total = 0.0;
  double _payment = 0.0;
  double _change = 0.0;

  // Controller untuk MobileScanner
  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _addProductToCart(String barcode) async {
    try {
      final product = await _dbHelper.getProductByBarcode(barcode);
      if (product != null) {
        setState(() {
          bool exists = false;
          for (var item in _cartItems) {
            if (item['id'] == product.idProduk) {
              item['quantity'] += 1;
              exists = true;
              break;
            }
          }

          if (!exists) {
            _cartItems.add({
              'id': product.idProduk,
              'name': product.namaProduk,
              'price': product.hargaEcer,
              'quantity': 1,
            });
          }

          _calculateTotal();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Produk tidak ditemukan')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat produk: $e')),
      );
    }
  }

  void _calculateTotal() {
    _total = _cartItems.fold(0.0, (sum, item) {
      return sum + (item['price'] * item['quantity']);
    });
    _change = _payment - _total;
  }

  Future<void> _completeTransaction() async {
    if (_payment < _total) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pembayaran kurang')),
      );
      return;
    }

    try {
      // Simpan transaksi utama
      final transactionId = await _dbHelper.insertTransaction(
        Transaction(
          tanggal: DateTime.now(),
          totalHarga: _total,
          metodeBayar: _payment >= _total ? 'tunai' : 'non-tunai',
          statusBayar: _payment >= _total ? 'lunas' : 'hutang',
        ),
      );

      // Simpan detail transaksi
      for (var item in _cartItems) {
        await _dbHelper.insertTransactionDetail(
          TransactionDetail(
            idTransaksi: transactionId,
            idProduk: item['id'],
            jumlah: item['quantity'],
            hargaSatuan: item['price'],
            subtotal: item['price'] * item['quantity'],
          ),
        );
      }

      // Jika ada hutang, simpan ke tabel hutang_pelanggan
      if (_payment < _total) {
        await _dbHelper.insertDebt(
          Debt(
            idTransaksi: transactionId,
            namaPelanggan: '', // Anda bisa menambahkan logika untuk mendapatkan nama pelanggan
            totalHutang: _total - _payment,
            status: 'belum lunas',
            tanggalJatuhTempo: DateTime.now().add(const Duration(days: 7)), // Contoh jatuh tempo dalam 7 hari
          ),
        );
      }

      setState(() {
        _cartItems.clear();
        _total = 0.0;
        _payment = 0.0;
        _change = 0.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi berhasil')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // Buka halaman pemindaian barcode
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BarcodeScannerPage(
                    onScanResult: (barcode) {
                      _addProductToCart(barcode);
                      Navigator.pop(context); // Kembali ke halaman transaksi
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                final item = _cartItems[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text('${item['quantity']} x ${item['price']}'),
                  trailing: Text('Rp ${(item['price'] * item['quantity']).toStringAsFixed(2)}'),
                  onTap: () {
                    // Edit quantity dialog
                    _showEditDialog(index);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total:'),
                    Text('Rp ${_total.toStringAsFixed(2)}'),
                  ],
                ),
                SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Pembayaran',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _payment = double.tryParse(value) ?? 0.0;
                      _change = _payment - _total;
                    });
                  },
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kembalian:'),
                    Text('Rp ${_change.toStringAsFixed(2)}'),
                  ],
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _completeTransaction,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Selesaikan Transaksi'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        int quantity = _cartItems[index]['quantity'];
        return AlertDialog(
          title: Text('Edit Jumlah'),
          content: TextField(
            keyboardType: TextInputType.number,
            controller: TextEditingController(text: quantity.toString()),
            onChanged: (value) {
              quantity = int.tryParse(value) ?? 1;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _cartItems[index]['quantity'] = quantity;
                  _calculateTotal();
                });
                Navigator.pop(context);
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}

// Halaman pemindaian barcode
class BarcodeScannerPage extends StatelessWidget {
  final Function(String) onScanResult;

  const BarcodeScannerPage({required this.onScanResult});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pindai Barcode'),
      ),
      body: Center(
        child: MobileScanner(
          fit: BoxFit.contain,
          controller: MobileScannerController(),
          onDetect: (capture) {
            // Ambil barcode pertama dari daftar barcodes
            final Barcode barcode = capture.barcodes.first;
            onScanResult(barcode.rawValue ?? '');
          },
        ),
      ),
    );
  }
}