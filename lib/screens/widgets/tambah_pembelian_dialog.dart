import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../db/database_helper.dart';
import '../../models/supplier_model.dart';
import '../../models/product_model.dart';
import '../../models/pembelian_item_model.dart';

class TambahPembelianDialog extends StatefulWidget {
  final List<Supplier> suppliers;
  final List<Product> products;
  final VoidCallback onSave;

  const TambahPembelianDialog({
    Key? key,
    required this.suppliers,
    required this.products,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TambahPembelianDialog> createState() => _TambahPembelianDialogState();
}

class _TambahPembelianDialogState extends State<TambahPembelianDialog> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  Supplier? _selectedSupplier;
  DateTime _tanggalPembelian = DateTime.now();
  DateTime _tanggalJatuhTempo = DateTime.now().add(Duration(days: 30));
  String _catatan = '';
  
  List<PembelianItem> _items = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tambah Pembelian dari Supplier',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pilih Supplier
                    Text(
                      'Pilih Supplier *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    DropdownButtonFormField<Supplier>(
                      value: _selectedSupplier,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Pilih supplier...',
                      ),
                      items: widget.suppliers.map((supplier) {
                        return DropdownMenuItem(
                          value: supplier,
                          child: Text(supplier.namaSuplier),
                        );
                      }).toList(),
                      onChanged: (supplier) {
                        setState(() {
                          _selectedSupplier = supplier;
                        });
                      },
                    ),

                    SizedBox(height: 20),

                    // Tanggal Pembelian
                    Text(
                      'Tanggal Pembelian *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTanggalPembelian(),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Text(DateFormat('dd/MM/yyyy').format(_tanggalPembelian)),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Tanggal Jatuh Tempo
                    Text(
                      'Tanggal Jatuh Tempo *',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    InkWell(
                      onTap: () => _selectTanggalJatuhTempo(),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: Colors.grey[600]),
                            SizedBox(width: 12),
                            Text(DateFormat('dd/MM/yyyy').format(_tanggalJatuhTempo)),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Items Pembelian
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Items Pembelian',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showTambahItemDialog(),
                          icon: Icon(Icons.add, size: 15),
                          label: Text('Tambah Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),

                    // List Items
                    if (_items.isEmpty)
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada item yang ditambahkan',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _items.map((item) => _buildItemCard(item)).toList(),
                      ),

                    SizedBox(height: 20),

                    // Catatan
                    Text(
                      'Catatan',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Catatan pembelian (opsional)...',
                      ),
                      maxLines: 3,
                      onChanged: (value) => _catatan = value,
                    ),

                    SizedBox(height: 20),

                    // Total
                    if (_items.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.deepOrange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.deepOrange.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Pembelian:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(_getTotalHarga()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.deepOrange.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanPembelian,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text('Simpan Pembelian'),
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

  Widget _buildItemCard(PembelianItem item) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange.shade100,
          child: Text(
            '${item.jumlah}',
            style: TextStyle(
              color: Colors.deepOrange.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          item.product.namaProduk ?? 'Produk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Harga: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item.hargaBeli)}'),
            Text(
              'Subtotal: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(item.subtotal)}',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            setState(() {
              _items.remove(item);
            });
          },
        ),
      ),
    );
  }

  void _showTambahItemDialog() {
    Product? selectedProduct;
    int jumlah = 1;
    double hargaBeli = 0;
    final jumlahController = TextEditingController(text: '1');
    final hargaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Tambah Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selectedProduct,
                  decoration: InputDecoration(
                    labelText: 'Pilih Produk *',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.products.map((product) {
                    return DropdownMenuItem(
                      value: product,
                      child: Text(product.namaProduk ?? 'Produk'),
                    );
                  }).toList(),
                  onChanged: (product) {
                    setStateDialog(() {
                      selectedProduct = product;
                      hargaBeli = product?.hargaEcer ?? 0;
                      hargaController.text = hargaBeli.toString();
                    });
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: jumlahController,
                  decoration: InputDecoration(
                    labelText: 'Jumlah *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    jumlah = int.tryParse(value) ?? 1;
                  },
                ),
                SizedBox(height: 16),
                TextField(
                  controller: hargaController,
                  decoration: InputDecoration(
                    labelText: 'Harga Beli *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    hargaBeli = double.tryParse(value) ?? 0;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct != null && jumlah > 0 && hargaBeli > 0) {
                  setState(() {
                    _items.add(PembelianItem(
                      product: selectedProduct!,
                      jumlah: jumlah,
                      hargaBeli: hargaBeli,
                    ));
                  });
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Semua field harus diisi dengan benar')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
              child: Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectTanggalPembelian() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalPembelian,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tanggalPembelian = picked;
      });
    }
  }

  Future<void> _selectTanggalJatuhTempo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalJatuhTempo,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _tanggalJatuhTempo = picked;
      });
    }
  }

  double _getTotalHarga() {
    return _items.fold(0, (sum, item) => sum + item.subtotal);
  }

  Future<void> _simpanPembelian() async {
    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih supplier terlebih dahulu')),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tambahkan minimal satu item')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final pembelianData = {
        'id_suplier': _selectedSupplier!.idSuplier,
        'tanggal_pembelian': _tanggalPembelian.toIso8601String(),
        'total_harga': _getTotalHarga(),
        'status_bayar': 'belum_bayar',
        'tanggal_jatuh_tempo': _tanggalJatuhTempo.toIso8601String(),
        'catatan': _catatan.isEmpty ? null : _catatan,
        'created_at': DateTime.now().toIso8601String(),
      };

      final detailItems = _items.map((item) => {
        'id_produk': item.product.idProduk,
        'jumlah': item.jumlah,
        'harga_beli': item.hargaBeli,
        'subtotal': item.subtotal,
      }).toList();

      print('💾 Saving pembelian dengan ${_items.length} items...');
      
      final idPembelian = await _dbHelper.savePembelianWithStockUpdate(
        pembelianData, 
        detailItems
      );

      if (idPembelian > 0) {
        Navigator.pop(context);
        widget.onSave();
        
        final totalItems = _items.fold(0, (sum, item) => sum + item.jumlah);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pembelian berhasil! $totalItems item ditambahkan ke stok'
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        print('🎉 Pembelian berhasil disimpan dengan ID: $idPembelian');
      } else {
        throw Exception('Gagal menyimpan pembelian');
      }
    } catch (e) {
      print('💥 Error saat simpan pembelian: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}