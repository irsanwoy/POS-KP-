import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/transaction_model.dart';
import 'package:pos/models/debt_model.dart';
import 'package:pos/models/product_model.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Product? _product;
  String _barcode = '';
  int _quantity = 1;
  double _totalPrice = 0.0;
  String _paymentMethod = 'tunai';
  String _paymentStatus = 'lunas';
  double _total = 0.0;
  double _payment = 0.0;
  double _change = 0.0;

  final MobileScannerController _scannerController = MobileScannerController();

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
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
  }

  Future<void> _addProductToCart(String barcode) async {
    try {
      final product = await _dbHelper.getProductByBarcode(barcode);
      if (product != null) {
        setState(() {
          _product = product;
          _barcode = barcode;
          _quantity = 1;  // Set default quantity
          _calculateTotalPrice();
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

  void _calculateTotalPrice() {
    if (_product != null && _product!.hargaGrosir != null) {
      _totalPrice = _product!.hargaGrosir! * _quantity;
    } else {
      _totalPrice = 0.0;  // Jika hargaGrosir null, atur totalPrice menjadi 0
    }
  }

  Future<void> _saveTransaction() async {
    if (_product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan scan produk terlebih dahulu')),
      );
      return;
    }

    try {
      final int? productId = _product!.idProduk; // Pastikan _product tidak null
      final double? price = _product!.hargaGrosir;
    
      final transactionId = await _dbHelper.insertTransaction(
        Transaction(
          tanggal: DateTime.now(),
          totalHarga: _totalPrice,
          metodeBayar: _paymentMethod,
          statusBayar: _paymentStatus,
        ),
      );

      // Simpan detail transaksi
      await _dbHelper.insertTransactionDetail(
        TransactionDetail(
          idTransaksi: transactionId,
          idProduk: productId!,  // Using the previously declared productId
          jumlah: _quantity,
          hargaSatuan: price!,  // Using non-null assertion as we know price exists
          subtotal: _totalPrice,
        ),
      );

      // Jika status bayar hutang, simpan ke tabel hutang_pelanggan
      if (_paymentStatus == 'hutang') {
        await _dbHelper.insertDebt(
          Debt(
            idTransaksi: transactionId,
            namaPelanggan: '', // Logika untuk mendapatkan nama pelanggan
            totalHutang: _totalPrice,
            status: 'belum lunas',
            tanggalJatuhTempo: DateTime.now().add(const Duration(days: 7)),
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi berhasil disimpan')),
      );

      // Reset setelah transaksi selesai
      setState(() {
        _product = null;
        _barcode = '';
        _quantity = 1;
        _totalPrice = 0.0;
        _paymentMethod = 'tunai';
        _paymentStatus = 'lunas';
      });
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
        title: const Text('Tambah Transaksi'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Form untuk detail produk yang dipindai
          if (_product != null) ...[
            ListTile(
              title: Text('Nama Produk: ${_product!.namaProduk}'),
            ),
            ListTile(
              title: Text('Satuan: ${_product!.hargaEcer}'),
            ),
            ListTile(
              title: Text('Harga Grosir: Rp ${_product!.hargaGrosir}'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Jumlah:'),
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (_quantity > 1) _quantity--;
                      _calculateTotalPrice();
                    });
                  },
                ),
                Text('$_quantity'),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _quantity++;
                      _calculateTotalPrice();
                    });
                  },
                ),
              ],
            ),
            ListTile(
              title: Text('Total Harga: Rp $_totalPrice'),
            ),
          ],
          // Pilihan metode pembayaran
          ListTile(
            title: Text('Metode Pembayaran'),
            subtitle: Row(
              children: [
                Radio<String>(
                  value: 'tunai',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                ),
                Text('Tunai'),
                Radio<String>(
                  value: 'non-tunai',
                  groupValue: _paymentMethod,
                  onChanged: (value) {
                    setState(() {
                      _paymentMethod = value!;
                    });
                  },
                ),
                Text('Non-Tunai'),
              ],
            ),
          ),
          // Pilihan status pembayaran
          ListTile(
            title: Text('Status Pembayaran'),
            subtitle: Row(
              children: [
                Radio<String>(
                  value: 'lunas',
                  groupValue: _paymentStatus,
                  onChanged: (value) {
                    setState(() {
                      _paymentStatus = value!;
                    });
                  },
                ),
                Text('Lunas'),
                Radio<String>(
                  value: 'hutang',
                  groupValue: _paymentStatus,
                  onChanged: (value) {
                    setState(() {
                      _paymentStatus = value!;
                    });
                  },
                ),
                Text('Hutang'),
              ],
            ),
          ),
          // Tombol Simpan dan Batal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _product = null;
                      _barcode = '';
                      _quantity = 1;
                      _totalPrice = 0.0;
                      _paymentMethod = 'tunai';
                      _paymentStatus = 'lunas';
                    });
                  },
                  child: Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: _saveTransaction,
                  child: Text('Simpan'),
                ),
              ],
            ),
          ),
        ],
      ),
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
