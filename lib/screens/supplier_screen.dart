import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/supplier_model.dart';
import '../models/product_model.dart';

class SupplierScreen extends StatefulWidget {
  final String userRole;
  
  const SupplierScreen({Key? key, this.userRole = 'pemilik'}) : super(key: key);

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Supplier> _suppliers = [];
  List<Map<String, dynamic>> _pembelianSuplier = [];
  List<Product> _products = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Hanya 2 tab
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final suppliers = await _dbHelper.getAllSuppliers();
      final pembelian = await _dbHelper.getAllPembelianSuplier();
      final products = await _dbHelper.getAllProducts();
      
      setState(() {
        _suppliers = suppliers;
        _pembelianSuplier = pembelian;
        _products = products;
      });
    } catch (e) {
      print('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        // title: Text('Manajemen Supplier'),
        // backgroundColor: Colors.teal,
        backgroundColor: Colors.deepOrange,

        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.business), text: 'Supplier'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Pembelian'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSuppliersTab(),
                _buildPembelianTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),

        backgroundColor: Colors.deepOrange,
        
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSuppliersTab() {
    return Column(
      children: [
        // Header
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.business, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Text(
                'Total Supplier: ${_suppliers.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // List Suppliers
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _suppliers.length,
            itemBuilder: (context, index) {
              final supplier = _suppliers[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[100],
                    child: Icon(Icons.business, color: Colors.teal),
                  ),
                  title: Text(
                    supplier.namaSuplier,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (supplier.kontak != null)
                        Text('📞 ${supplier.kontak}'),
                      if (supplier.alamat != null)
                        Text('📍 ${supplier.alamat}'),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editSupplier(supplier);
                      } else if (value == 'delete') {
                        _deleteSupplier(supplier);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPembelianTab() {
    return Column(
      children: [
        // Header
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Text(
                'Total Pembelian: ${_pembelianSuplier.length}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // List Pembelian
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _pembelianSuplier.length,
            itemBuilder: (context, index) {
              final pembelian = _pembelianSuplier[index];
              final tanggal = DateTime.parse(pembelian['tanggal_pembelian']);
              final status = pembelian['status_bayar'];
              
              Color statusColor = status == 'lunas' 
                  ? Colors.green 
                  : status == 'terlambat' 
                    ? Colors.red 
                    : Colors.orange;

              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.2),
                    child: Text('PB', style: TextStyle(color: statusColor)),
                  ),
                  title: Text(
                    'PB-${pembelian['id_pembelian']} - ${pembelian['nama_suplier']}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📅 ${DateFormat('dd/MM/yyyy').format(tanggal)}'),
                      Text('📦 ${pembelian['total_items']} items'),
                      Text('💰 ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(pembelian['total_harga'])}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (status != 'lunas')
                        IconButton(
                          icon: Icon(Icons.payment, color: Colors.green),
                          onPressed: () => _markAsPaid(pembelian['id_pembelian']),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddDialog() {
    if (_tabController.index == 0) {
      _addSupplier();
    } else {
      _addPembelian();
    }
  }

  void _addSupplier() {
    final namaController = TextEditingController();
    final kontakController = TextEditingController();
    final alamatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: InputDecoration(labelText: 'Nama Supplier'),
            ),
            TextField(
              controller: kontakController,
              decoration: InputDecoration(labelText: 'Kontak'),
            ),
            TextField(
              controller: alamatController,
              decoration: InputDecoration(labelText: 'Alamat'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.isNotEmpty) {
                final supplier = Supplier(
                  namaSuplier: namaController.text,
                  kontak: kontakController.text.isEmpty ? null : kontakController.text,
                  alamat: alamatController.text.isEmpty ? null : alamatController.text,
                );
                await _dbHelper.insertSupplier(supplier);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _editSupplier(Supplier supplier) {
    final namaController = TextEditingController(text: supplier.namaSuplier);
    final kontakController = TextEditingController(text: supplier.kontak ?? '');
    final alamatController = TextEditingController(text: supplier.alamat ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaController,
              decoration: InputDecoration(labelText: 'Nama Supplier'),
            ),
            TextField(
              controller: kontakController,
              decoration: InputDecoration(labelText: 'Kontak'),
            ),
            TextField(
              controller: alamatController,
              decoration: InputDecoration(labelText: 'Alamat'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (namaController.text.isNotEmpty) {
                final updatedSupplier = Supplier(
                  idSuplier: supplier.idSuplier,
                  namaSuplier: namaController.text,
                  kontak: kontakController.text.isEmpty ? null : kontakController.text,
                  alamat: alamatController.text.isEmpty ? null : alamatController.text,
                );
                await _dbHelper.updateSupplier(updatedSupplier);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _deleteSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Supplier'),
        content: Text('Apakah yakin ingin menghapus ${supplier.namaSuplier}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbHelper.deleteSupplier(supplier.idSuplier!);
              Navigator.pop(context);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _addPembelian() {
    // Placeholder - implementasi nanti
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur tambah pembelian segera hadir')),
    );
  }

  void _markAsPaid(int idPembelian) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Tandai sebagai sudah dibayar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _dbHelper.updateStatusPembayaran(idPembelian, 'lunas');
              Navigator.pop(context);
              _loadData();
            },
            child: Text('Ya'),
          ),
        ],
      ),
    );
  }
}

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
                color: Colors.green,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Tambah Pembelian dari Supplier',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
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
                          icon: Icon(Icons.add, size: 18),
                          label: Text('Tambah Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
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
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green[200]!),
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
                              NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(_getTotalHarga()),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.green[800],
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
                        backgroundColor: Colors.green,
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
          backgroundColor: Colors.green[100],
          child: Text(
            '${item.jumlah}',
            style: TextStyle(
              color: Colors.green[800],
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
            Text('Harga: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(item.hargaBeli)}'),
            Text(
              'Subtotal: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(item.subtotal)}',
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Tambah Item'),
          content: Column(
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
                    hargaBeli = product?.hargaEcer ?? 0; // Default ke harga ecer
                  });
                },
              ),
              SizedBox(height: 16),
              TextField(
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
                decoration: InputDecoration(
                  labelText: 'Harga Beli *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: hargaBeli.toString()),
                onChanged: (value) {
                  hargaBeli = double.tryParse(value) ?? 0;
                },
              ),
            ],
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
    // Prepare data pembelian
    final pembelianData = {
      'id_suplier': _selectedSupplier!.idSuplier,
      'tanggal_pembelian': _tanggalPembelian.toIso8601String(),
      'total_harga': _getTotalHarga(),
      'status_bayar': 'belum_bayar',
      'tanggal_jatuh_tempo': _tanggalJatuhTempo.toIso8601String(),
      'catatan': _catatan.isEmpty ? null : _catatan,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Prepare detail items
    final detailItems = _items.map((item) => {
      'id_produk': item.product.idProduk,
      'jumlah': item.jumlah,
      'harga_beli': item.hargaBeli,
      'subtotal': item.subtotal,
    }).toList();

    print('💾 Saving pembelian dengan ${_items.length} items...');
    
    // Save dengan transaction-based method (lebih aman)
    final idPembelian = await _dbHelper.savePembelianWithStockUpdate(
      pembelianData, 
      detailItems
    );

    if (idPembelian > 0) {
      Navigator.pop(context);
      widget.onSave();
      
      // Show success message dengan detail
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

// Class untuk item pembelian
class PembelianItem {
  final Product product;
  final int jumlah;
  final double hargaBeli;

  PembelianItem({
    required this.product,
    required this.jumlah,
    required this.hargaBeli,
  });

  double get subtotal => hargaBeli * jumlah;
}