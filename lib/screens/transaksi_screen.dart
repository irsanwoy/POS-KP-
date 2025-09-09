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
  bool useWholesalePrice;

  CartItem({
    required this.product, 
    this.quantity = 1, 
    this.useWholesalePrice = false
  });

  double get subtotal {
    final price = useWholesalePrice 
        ? (product.hargaGrosir ?? product.hargaEcer) 
        : product.hargaEcer;
    return price * quantity;
  }
  
  double get currentPrice {
    return useWholesalePrice 
        ? (product.hargaGrosir ?? product.hargaEcer) 
        : product.hargaEcer;
  }
}

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<CartItem> _cart = [];
  int? _lastTransactionId;
  bool _isWholesaleMode = false;

  double get _total => _cart.fold(0, (sum, item) => sum + item.subtotal);

  String _barcodeBuffer = '';
  final FocusNode _barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _barcodeFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _barcodeFocusNode.dispose();
    super.dispose();
  }

  void _updateAllItemsPriceMode() {
    setState(() {
      for (var item in _cart) {
        item.useWholesalePrice = _isWholesaleMode;
      }
    });
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
            debugPrint('Barcode dari kamera: $barcode');
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
    debugPrint('Barcode dibersihkan: "$cleaned"');

    if (cleaned.isEmpty || cleaned.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barcode tidak valid atau kosong')),
      );
      return;
    }

    final product = await _dbHelper.getProductByBarcode(cleaned);
    if (product != null) {
      _addToCart(product, quantity);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produk tidak ditemukan: $cleaned')),
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
        _cart.add(CartItem(
          product: product, 
          quantity: quantity,
          useWholesalePrice: _isWholesaleMode,
        ));
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
          metodeBayar: 'tunai',
          statusBayar: 'lunas',
        ),
      );

      for (final item in _cart) {
        await _dbHelper.insertTransactionDetail(
          TransactionDetail(
            idTransaksi: transactionId,
            idProduk: item.product.idProduk!,
            jumlah: item.quantity,
            hargaSatuan: item.currentPrice,
            subtotal: item.subtotal,
          ),
        );

        await _dbHelper.updateProductStock(
          item.product.idProduk!,
          item.quantity,
        );
      }

      setState(() {
        _lastTransactionId = transactionId;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaksi berhasil disimpan')),
      );

      setState(() {
        _cart.clear();
        _isWholesaleMode = false;
      });
    } catch (e) {
      debugPrint("Error saat menyimpan transaksi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan transaksi: $e')),
      );
    }
  }

  String _generateReceiptText() {
    if (_cart.isEmpty && _lastTransactionId == null) return '';
    
    final now = DateTime.now();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm:ss');
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ');
    
    String receipt = '';
    receipt += '================================\n';
    receipt += '            SRC RUDI            \n';
    receipt += '================================\n';
    receipt += 'Tanggal: ${dateFormat.format(now)}\n';
    if (_lastTransactionId != null) {
      receipt += 'No. Transaksi: $_lastTransactionId\n';
    }
    receipt += 'Jenis: ${_isWholesaleMode ? "GROSIR" : "ECERAN"}\n';
    receipt += '--------------------------------\n';
    
    final itemsToShow = _cart.isNotEmpty ? _cart : [];
    
    for (final item in itemsToShow) {
      receipt += '${item.product.namaProduk ?? 'Produk'}\n';
      receipt += '  ${item.quantity} x ${currencyFormat.format(item.currentPrice)}\n';
      receipt += '  = ${currencyFormat.format(item.subtotal)}\n';
      receipt += '--------------------------------\n';
    }
    
    receipt += 'TOTAL: ${currencyFormat.format(_total)}\n';
    receipt += '================================\n';
    receipt += '     Terima kasih atas\n';
    receipt += '      kunjungan Anda!\n';
    receipt += '================================\n';
    
    return receipt;
  }

  void _showReceiptPreview() {
    final receiptText = _generateReceiptText();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preview Struk'),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            child: Text(
              receiptText,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: receiptText));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Struk berhasil disalin ke clipboard!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
            ),
            child: Text('Salin ke Clipboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan Barcode'),
        backgroundColor: Colors.red,
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
            debugPrint('Key pressed: "$label"');

            if (label == 'Enter') {
              debugPrint('Barcode dari scanner fisik: $_barcodeBuffer');
              _handleScannedBarcode(_barcodeBuffer);
              _barcodeBuffer = '';
            } else if (label.isNotEmpty && label != 'Shift') {
              _barcodeBuffer += label;
            }
          }
        },
        child: Column(
          children: [
            // Header dengan toggle mode harga
            Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _isWholesaleMode ? Colors.orange[50] : Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isWholesaleMode ? Colors.orange[200]! : Colors.blue[200]!,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isWholesaleMode ? Icons.business : Icons.person,
                    color: _isWholesaleMode ? Colors.orange[700] : Colors.blue[700],
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Harga',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _isWholesaleMode ? 'Pelanggan Grosir' : 'Pelanggan Eceran',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isWholesaleMode ? Colors.orange[800] : Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isWholesaleMode,
                    onChanged: (value) {
                      setState(() {
                        _isWholesaleMode = value;
                        _updateAllItemsPriceMode();
                      });
                    },
                    activeColor: Colors.orange,
                    inactiveThumbColor: Colors.blue,
                  ),
                ],
              ),
            ),

            // Cart items
            Expanded(
              child: ListView.builder(
                itemCount: _cart.length,
                itemBuilder: (context, index) {
                  final item = _cart[index];
                  final grosir = item.product.hargaGrosir ?? 0;
                  final eceran = item.product.hargaEcer;
                  final isUsingGrosir = item.useWholesalePrice;
                  
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isUsingGrosir 
                            ? Border.all(color: Colors.orange[300]!, width: 2)
                            : Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.product.namaProduk ?? '', 
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (isUsingGrosir)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'GROSIR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 8),
                            Text('Jumlah: ${item.quantity}'),
                            Text(
                              'Harga: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(item.currentPrice)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isUsingGrosir ? Colors.orange[700] : Colors.blue[700],
                              ),
                            ),
                            Text(
                              'Subtotal: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(item.subtotal)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Eceran: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(eceran)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: !isUsingGrosir ? Colors.blue[600] : Colors.grey[600],
                                      fontWeight: !isUsingGrosir ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Grosir: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(grosir)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isUsingGrosir ? Colors.orange[600] : Colors.grey[600],
                                      fontWeight: isUsingGrosir ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                    ),
                  );
                },
              ),
            ),

            // Total section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '(${_isWholesaleMode ? "Harga Grosir" : "Harga Eceran"})',
                        style: TextStyle(
                          fontSize: 12,
                          color: _isWholesaleMode ? Colors.orange[600] : Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(_total),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                ],
              ),
            ),

            // Buttons section
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Row pertama: Batal dan Simpan
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => setState(() {
                            _cart.clear();
                            _lastTransactionId = null;
                            _isWholesaleMode = false;
                          }),
                          child: Text(
                            'Batal',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _cart.isNotEmpty ? _saveTransaction : null,
                          child: Text(
                            'Simpan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Row kedua: Print Struk (full width)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _cart.isNotEmpty || _lastTransactionId != null 
                          ? _showReceiptPreview 
                          : null,
                      icon: Icon(Icons.receipt_long),
                      label: Text(
                        'Print Struk',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
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
            debugPrint('Barcode terdeteksi: $barcode');
            _hasScanned = true;
            widget.onScanResult(barcode);
          } else {
            debugPrint('Barcode tidak valid');
          }
        },
      ),
    );
  }
}