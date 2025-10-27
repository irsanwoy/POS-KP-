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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Pilih Metode Scan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.qr_code_scanner, color: Colors.blue[700]),
              ),
              title: Text(
                'Scan dengan Kamera',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Gunakan kamera untuk scan barcode'),
              onTap: () {
                Navigator.pop(context);
                _scanBarcode();
              },
            ),
            SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.keyboard, color: Colors.green[700]),
              ),
              title: Text(
                'Scanner Fisik',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Gunakan barcode scanner eksternal'),
              onTap: () {
                Navigator.pop(context);
                _barcodeFocusNode.requestFocus();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 10),
                        Text('Siap menerima input dari scanner fisik'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
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
        SnackBar(
          content: Text('Barcode tidak valid atau kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final product = await _dbHelper.getProductByBarcode(cleaned);
    if (product != null) {
      _addToCart(product, quantity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.namaProduk} ditambahkan ke keranjang'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk tidak ditemukan: $cleaned'),
          backgroundColor: Colors.orange,
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keranjang kosong'),
          backgroundColor: Colors.orange,
        ),
      );
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
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Transaksi berhasil disimpan'),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _cart.clear();
        _isWholesaleMode = false;
      });
    } catch (e) {
      debugPrint("Error saat menyimpan transaksi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan transaksi: $e'),
          backgroundColor: Colors.red,
        ),
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
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.blue),
            SizedBox(width: 10),
            Text('Preview Struk'),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
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
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: receiptText));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 10),
                      Text('Struk berhasil disalin ke clipboard!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            icon: Icon(Icons.copy),
            label: Text('Salin'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.blue[300],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Keranjang Kosong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Scan barcode untuk menambah produk',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 40),
          // Tombol Scan Besar
          ElevatedButton.icon(
            onPressed: _showScanOptionDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            icon: Icon(Icons.qr_code_scanner, size: 28),
            label: Text(
              'Scan Barcode',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
                  color: _isWholesaleMode ? Colors.orange.shade300 : Colors.blue.shade300,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isWholesaleMode ? Icons.business : Icons.person,
                    color: _isWholesaleMode ? Colors.orange.shade700 : Colors.blue.shade700,
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
                            color: _isWholesaleMode ? Colors.orange.shade800 : Colors.blue.shade800,
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

            // Cart items atau Empty State
            Expanded(
              child: _cart.isEmpty 
                  ? _buildEmptyCart()
                  : Column(
                      children: [
                        // Tombol Scan ketika ada item di cart
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _showScanOptionDialog,
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.blue, width: 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(Icons.qr_code_scanner, color: Colors.blue),
                              label: Text(
                                'Scan Produk Lain',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, index) {
                              final item = _cart[index];
                              final grosir = item.product.hargaGrosir ?? 0;
                              final eceran = item.product.hargaEcer;
                              final isUsingGrosir = item.useWholesalePrice;
                              
                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: isUsingGrosir 
                                        ? Border.all(color: Colors.orange.shade300, width: 2)
                                        : Border.all(color: Colors.grey.shade200, width: 1),
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
                                              color: Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              'GROSIR',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange.shade800,
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
                                            color: isUsingGrosir ? Colors.orange.shade700 : Colors.blue.shade700,
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
                                                  color: !isUsingGrosir ? Colors.blue.shade600 : Colors.grey[600],
                                                  fontWeight: !isUsingGrosir ? FontWeight.w600 : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                'Grosir: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(grosir)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isUsingGrosir ? Colors.orange.shade600 : Colors.grey[600],
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
                      ],
                    ),
            ),

            // Total section - hanya tampil jika ada item di cart
            if (_cart.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
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
                            color: _isWholesaleMode ? Colors.orange.shade600 : Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(_total),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  ],
                ),
              ),

            // Buttons section - hanya tampil jika ada item di cart
            if (_cart.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => setState(() {
                              _cart.clear();
                              _lastTransactionId = null;
                              _isWholesaleMode = false;
                            }),
                            icon: Icon(Icons.cancel),
                            label: Text(
                              'Batal',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _saveTransaction,
                            icon: Icon(Icons.check_circle),
                            label: Text(
                              'Simpan',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _showReceiptPreview,
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
      appBar: AppBar(
        title: Text('Pindai Barcode'),
        backgroundColor: Colors.red,
      ),
      body: Stack(
        children: [
          MobileScanner(
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
          // Overlay dengan frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          // Instruksi
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Arahkan kamera ke barcode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}