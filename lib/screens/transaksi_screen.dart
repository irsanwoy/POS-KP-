import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/transaction_model.dart';
import 'package:pos/models/debt_model.dart';
import 'package:pos/models/product_model.dart';
import 'package:intl/intl.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => (product.hargaGrosir ?? 0) * quantity;
}

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<CartItem> _cart = [];
  String _paymentMethod = 'tunai';
  String _paymentStatus = 'lunas';

  double get _total => _cart.fold(0, (sum, item) => sum + item.subtotal);

  final _manualBarcodeController = TextEditingController();
  final _manualQtyController = TextEditingController(text: '1');

  String _barcodeBuffer = '';
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void dispose() {
    _manualBarcodeController.dispose();
    _manualQtyController.dispose();
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
                SnackBar(content: Text('Siap menerima input dari scanner fisik')),
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
            Navigator.pop(context, barcode); // Pop setelah barcode berhasil
          },
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _handleScannedBarcode(result);
    }
  }

  void _showManualInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Input Manual'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _manualBarcodeController,
              decoration: InputDecoration(labelText: 'Barcode'),
            ),
            TextField(
              controller: _manualQtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Jumlah'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final barcode = _manualBarcodeController.text.trim();
              final qty = int.tryParse(_manualQtyController.text) ?? 1;
              _handleScannedBarcode(barcode, quantity: qty);
              Navigator.pop(context);
            },
            child: Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleScannedBarcode(String barcode, {int quantity = 1}) async {
    final product = await _dbHelper.getProductByBarcode(barcode);
    if (product != null) {
      _addToCart(product, quantity);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk tidak ditemukan')),
      );
    }
  }

  void _addToCart(Product product, int quantity) {
    setState(() {
      final index = _cart.indexWhere((item) => item.product.idProduk == product.idProduk);
      if (index != -1) {
        _cart[index].quantity += quantity;
      } else {
        _cart.add(CartItem(product: product, quantity: quantity));
      }
    });
  }

  Future<void> _saveTransaction() async {
  if (_cart.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Keranjang kosong')),
    );
    return;
  }

  try {
    final transactionId = await _dbHelper.insertTransaction(
      Transaction(
        tanggal: DateTime.now(),
        totalHarga: _total,
        metodeBayar: _paymentMethod,
        statusBayar: _paymentStatus,
      ),
    );

    for (final item in _cart) {
      await _dbHelper.insertTransactionDetail(
        TransactionDetail(
          idTransaksi: transactionId,
          idProduk: item.product.idProduk!,
          jumlah: item.quantity,
          hargaSatuan: item.product.hargaGrosir!,
          subtotal: item.subtotal,
        ),
      );

      // 🔥 Update stok produk
      final stokResult = await _dbHelper.updateProductStock(item.product.idProduk!, item.quantity);
      print('Stok produk ${item.product.namaProduk} dikurangi: ${item.quantity} | Result: $stokResult');
    }

    if (_paymentStatus == 'hutang') {
      await _dbHelper.insertDebt(
        Debt(
          idTransaksi: transactionId,
          namaPelanggan: '', // Optional: isi jika input pelanggan ditambahkan
          totalHutang: _total,
          status: 'belum lunas',
          tanggalJatuhTempo: DateTime.now().add(Duration(days: 7)),
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaksi berhasil disimpan')),
    );

    setState(() {
      _cart.clear();
      _paymentMethod = 'tunai';
      _paymentStatus = 'lunas';
    });
  } catch (e) {
    print("Error saat menyimpan transaksi: $e");
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
            icon: Icon(Icons.calculate),
            onPressed: _showManualInputDialog,
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: _showScanOptionDialog,
          ),
        ],
      ),
      body: RawKeyboardListener(
        focusNode: _barcodeFocusNode,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            final label = event.logicalKey.keyLabel;
            if (label == 'Enter') {
              _handleScannedBarcode(_barcodeBuffer);
              _barcodeBuffer = '';
            } else if (label.isNotEmpty && label != 'Shift') {
              _barcodeBuffer += label;
            }
          }
        },
        autofocus: true,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  return ListTile(
                    title: Text(item.product.namaProduk ?? ''),
                    subtitle: Text(
                      'Jumlah: ${item.quantity} | Subtotal: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(item.subtotal)}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          _cart.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ListTile(
              title: Text('Total'),
              trailing: Text(
                NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(_total),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              title: Text('Metode Pembayaran'),
              subtitle: Row(
                children: [
                  Radio<String>(
                    value: 'tunai',
                    groupValue: _paymentMethod,
                    onChanged: (value) => setState(() => _paymentMethod = value!),
                  ),
                  Text('Tunai'),
                  Radio<String>(
                    value: 'non-tunai',
                    groupValue: _paymentMethod,
                    onChanged: (value) => setState(() => _paymentMethod = value!),
                  ),
                  Text('Non-Tunai'),
                ],
              ),
            ),
            ListTile(
              title: Text('Status Pembayaran'),
              subtitle: Row(
                children: [
                  Radio<String>(
                    value: 'lunas',
                    groupValue: _paymentStatus,
                    onChanged: (value) => setState(() => _paymentStatus = value!),
                  ),
                  Text('Lunas'),
                  Radio<String>(
                    value: 'hutang',
                    groupValue: _paymentStatus,
                    onChanged: (value) => setState(() => _paymentStatus = value!),
                  ),
                  Text('Hutang'),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => _cart.clear()),
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
