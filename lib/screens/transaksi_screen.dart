import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/transaction_model.dart';

class TransaksiScreen extends StatefulWidget {
  @override
  _TransaksiScreenState createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _cartItems = [];
  double _total = 0.0;
  double _payment = 0.0;
  double _change = 0.0;

  Future<void> _scanBarcode() async {
    String barcode = await FlutterBarcodeScanner.scanBarcode(
      '#FF0000', 
      'Cancel', 
      true, 
      ScanMode.BARCODE
    );

    if (barcode != '-1') {
      _addProductToCart(barcode);
    }
  }

  Future<void> _addProductToCart(String barcode) async {
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
        SnackBar(content: Text('Produk tidak ditemukan'))
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
        SnackBar(content: Text('Pembayaran kurang'))
      );
      return;
    }

    await _dbHelper.insertTransaction(
  Transaction(
    tanggal: DateTime.now(),
    totalHarga: _total,
    metodeBayar: _payment >= _total ? 'tunai' : 'hutang',
    statusBayar: _payment >= _total ? 'lunas' : 'hutang',
    // Sesuaikan dengan constructor Transaction Anda
  )
);

    setState(() {
      _cartItems.clear();
      _total = 0.0;
      _payment = 0.0;
      _change = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaksi berhasil'))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transaksi'),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          )
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
            padding: EdgeInsets.all(16.0),
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
                  child: Text('Selesaikan Transaksi'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
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