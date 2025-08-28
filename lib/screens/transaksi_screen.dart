import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/transaction_model.dart';
import 'package:pos/models/product_model.dart';
import 'package:intl/intl.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => (product.hargaEcer) * quantity; // Menggunakan harga Ecer untuk subtotal
}

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<CartItem> _cart = [];

  double get _total => _cart.fold(0, (sum, item) => sum + item.subtotal);

  String _barcodeBuffer = '';
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _barcodeFocusNode.requestFocus(); // Fokus langsung ke scanner fisik
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showScanOptionDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.qr_code_scanner),
            title: Text('Scan dengan Kamera'),
            onTap: () {
              Navigator.pop(context);
              _scanBarcode();
            },
          ),
          ListTile(
            leading: Icon(Icons.keyboard),
            title: Text('Scan dengan Scanner Fisik'),
            onTap: () {
              Navigator.pop(context);
              _barcodeFocusNode.requestFocus();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Siap menerima input dari scanner fisik')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerPage(
          onScanResult: (barcode) {
            debugPrint('📥 Barcode dari kamera: $barcode');
            Navigator.pop(context, barcode);
          },
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _handleScannedBarcode(result);
    }
  }

  Future<void> _handleScannedBarcode(String barcode, {int quantity = 1}) async {
    final cleaned = barcode.trim().replaceAll('\n', '').replaceAll('\r', '');
    debugPrint('📥 Barcode dibersihkan: "$cleaned"');

    if (cleaned.isEmpty || cleaned.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Barcode tidak valid atau kosong')),
      );
      return;
    }

    final product = await _dbHelper.getProductByBarcode(cleaned);
    if (product != null) {
      _addToCart(product, quantity);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Produk tidak ditemukan: $cleaned')),
      );
    }
  }

  void _addToCart(Product product, int quantity) {
    setState(() {
      final index = _cart.indexWhere(
        (item) => item.product.idProduk == product.idProduk,
      );
      if (index != -1) {
        _cart[index].quantity += quantity;
      } else {
        _cart.add(CartItem(product: product, quantity: quantity));
      }
    });
  }

  Future<void> _saveTransaction() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Keranjang kosong')));
      return;
    }

    try {
      final transactionId = await _dbHelper.insertTransaction(
        Transaction(
          tanggal: DateTime.now(),
          totalHarga: _total,
          metodeBayar: 'tunai', // default karena gak dipakai
          statusBayar: 'lunas', // default juga
        ),
      );

      for (final item in _cart) {
        await _dbHelper.insertTransactionDetail(
          TransactionDetail(
            idTransaksi: transactionId,
            idProduk: item.product.idProduk!,
            jumlah: item.quantity,
            hargaSatuan: item.product.hargaEcer, // Harga eceran
            subtotal: item.subtotal,
          ),
        );

        await _dbHelper.updateProductStock(
          item.product.idProduk!,
          item.quantity,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Transaksi berhasil disimpan')),
      );

      setState(() {
        _cart.clear();
      });
    } catch (e) {
      debugPrint("❌ Error saat menyimpan transaksi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaksi'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: _showScanOptionDialog,
          ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: _barcodeFocusNode,
        autofocus: true,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            final label = event.logicalKey.keyLabel;
            debugPrint('⌨️ Key pressed: "$label"');

            if (label == 'Enter') {
              debugPrint('📤 Barcode dari scanner fisik: $_barcodeBuffer');
              _handleScannedBarcode(_barcodeBuffer);
              _barcodeBuffer = '';
            } else if (label.isNotEmpty && label != 'Shift') {
              _barcodeBuffer += label;
            }
          }
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  final grosir = NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(item.product.hargaGrosir ?? 0);
                  final eceran = NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(item.product.hargaEcer);
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(item.product.namaProduk ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Jumlah: ${item.quantity}'),
                          Text('Subtotal: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(item.subtotal)}'),
                          SizedBox(height: 4),
                          Text('Harga Grosir: $grosir'),
                          Text('Harga Eceran: $eceran'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _cart.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListTile(
                title: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text(
                  NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(_total),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Batal button warna merah
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => setState(() => _cart.clear()),
                    child: Text('Batal'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal, // Simpan button warna teal
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saveTransaction,
                    child: Text('Simpan'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final Function(String) onScanResult;

  const BarcodeScannerPage({required this.onScanResult});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pindai Barcode')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (capture) {
          if (_hasScanned) return;
          final barcode = capture.barcodes.first.rawValue;

          if (barcode != null && barcode.isNotEmpty) {
            debugPrint('✅ Barcode terdeteksi: $barcode');
            _hasScanned = true;
            widget.onScanResult(barcode);
          } else {
            debugPrint('⚠️ Barcode tidak valid');
          }
        },
      ),
    );
  }
}
