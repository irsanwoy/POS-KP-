import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

class TransaksiScreen extends StatefulWidget {
  const TransaksiScreen({super.key});

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  List<Map<String, dynamic>> _items = []; // List item transaksi
  double _total = 0.0;
  final TextEditingController _uangDibayarController = TextEditingController();

  // Simulasi data produk (TODO: Ganti dengan data dari SQLite)
  final List<Map<String, dynamic>> _dummyProducts = [
    {'id': 1, 'name': 'Indomie Goreng', 'harga_eceran': 3000, 'harga_grosir': 2500},
    {'id': 2, 'name': 'Aqua 600ml', 'harga_eceran': 5000, 'harga_grosir': 4000},
  ];

  Future<void> _scanBarcode() async {
    String barcode = await FlutterBarcodeScanner.scanBarcode(
      '#FF0000', 
      'Batal', 
      true, 
      ScanMode.BARCODE
    );

    if (barcode == '-1') return;

    var product = _dummyProducts.firstWhere(
      (p) => p['id'].toString() == barcode,
      orElse: () => {},
    );

    if (product.isNotEmpty) {
      setState(() {
        _items.add({
          'product': product,
          'quantity': 1,
          'harga': product['harga_eceran'],
          'subtotal': product['harga_eceran'] * 1,
        });
        _total += product['harga_eceran'] * 1;
      });
    }
  }

  void _hitungKembalian() {
    double uangDibayar = double.tryParse(_uangDibayarController.text) ?? 0;
    double kembalian = uangDibayar - _total;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kembalian'),
        content: Text('Kembalian: Rp ${kembalian.toStringAsFixed(2)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaksi'),
        backgroundColor: Colors.deepPurple, // More vibrant app bar color
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.amber.shade100, // Colorful card for each item
                    child: ListTile(
                      title: Text(
                        item['product']['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Text('${item['quantity']} x Rp ${item['harga']}'),
                      trailing: Text(
                        'Rp ${item['subtotal'].toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18)),
                Text(
                  'Rp ${_total.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _uangDibayarController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Uang Dibayar',
                labelStyle: const TextStyle(color: Colors.deepPurple), // Colorful label
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _hitungKembalian,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple), // Button color
                    child: const Text('Hitung Kembalian'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.print),
                    label: const Text('Cetak Struk'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green), // Green button for contrast
                    onPressed: () {
                      // TODO: Implement cetak struk
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
