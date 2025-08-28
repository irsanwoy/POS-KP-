import 'package:flutter/material.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/product_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/models/supplier_model.dart';
class ProdukScreen extends StatefulWidget {
  const ProdukScreen({super.key});

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await DatabaseHelper().getAllProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat produk: $e')));
    }
  }

  void _searchProducts(String query) {
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.namaProduk.toLowerCase().contains(query.toLowerCase()) ||
            (product.barcode != null &&
                product.barcode!.contains(query));
      }).toList();
    });
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await DatabaseHelper().deleteProduct(id);
      setState(() {
        _products.removeWhere((product) => product.idProduk == id);
        _filteredProducts = _products;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Produk berhasil dihapus')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus produk: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(_products),
              );
            },
          ),
        ],
      ),
      body: _filteredProducts.isEmpty
          ? const Center(child: Text('Tidak ada produk'))
          : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _ProductCard(
                  product: product,
                  onDelete: () => _deleteProduct(product.idProduk!),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProductFormScreen()),
          );
          if (shouldRefresh == true) {
            await _loadProducts();
          }
        },
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: ListTile(
        title: Text(
          product.namaProduk,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.barcode != null) Text('Barcode: ${product.barcode}'),
            const SizedBox(height: 4),
            Text('Harga Ecer: Rp ${product.hargaEcer.toStringAsFixed(2)}'),
            if (product.hargaGrosir != null)
              Text(
                'Harga Grosir: Rp ${product.hargaGrosir!.toStringAsFixed(2)}',
              ),
            const SizedBox(height: 4),
            Text('Stok: ${product.stok}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () async {
                final shouldRefresh = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductFormScreen(product: product),
                  ),
                );
                if (shouldRefresh == true) {
                  // Trigger reload
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus Produk'),
                    content: const Text(
                      'Apakah Anda yakin ingin menghapus produk ini?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete();
                        },
                        child: const Text('Hapus'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate {
  final List<Product> products;

  ProductSearchDelegate(this.products);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = products.where((product) {
      return product.namaProduk.toLowerCase().contains(query.toLowerCase()) ||
          (product.barcode != null &&
              product.barcode!.toLowerCase().contains(query.toLowerCase()));
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return _ProductCard(
          product: product,
          onDelete: () {}, // Handle delete if necessary
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _hargaEceranController = TextEditingController();
  final TextEditingController _hargaGrosirController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  int? _selectedSupplierId; // Menyimpan ID Supplier yang dipilih
  List<Supplier> _suppliers = []; // Daftar Supplier

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    if (widget.product != null) {
      _nameController.text = widget.product!.namaProduk;
      _barcodeController.text = widget.product!.barcode ?? '';
      _hargaEceranController.text = widget.product!.hargaEcer.toString();
      _hargaGrosirController.text =
          widget.product!.hargaGrosir?.toString() ?? '';
      _stockController.text = widget.product!.stok.toString();
      _selectedSupplierId = widget.product!.idSuplier;
    }
  }

  // Fungsi untuk mengambil daftar supplier dari database
  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await DatabaseHelper().getAllSuppliers(); // Ambil data supplier
      setState(() {
        _suppliers = suppliers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat supplier: $e')));
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newProduct = Product(
          idProduk: widget.product?.idProduk,
          namaProduk: _nameController.text,
          hargaEcer: double.parse(_hargaEceranController.text),
          hargaGrosir: _hargaGrosirController.text.isNotEmpty
              ? double.parse(_hargaGrosirController.text)
              : null,
          stok: int.parse(_stockController.text),
          barcode: _barcodeController.text.isNotEmpty
              ? _barcodeController.text
              : null,
          idSuplier: _selectedSupplierId, // Simpan ID Supplier
        );

        if (newProduct.idProduk == null) {
          await DatabaseHelper().insertProduct(newProduct);
        } else {
          await DatabaseHelper().updateProduct(newProduct);
        }

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan produk: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Dropdown untuk memilih supplier
              DropdownButtonFormField<int>(
                value: _selectedSupplierId,
                decoration: const InputDecoration(
                  labelText: 'Pilih Supplier',
                  border: OutlineInputBorder(),
                ),
                items: _suppliers.map((supplier) {
                  return DropdownMenuItem<int>(
                    value: supplier.idSuplier,
                    child: Text(supplier.namaSuplier),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSupplierId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Supplier wajib dipilih';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Input lainnya tetap seperti sebelumnya
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: false, // Membuat barcode bisa diinput manual
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: _scanBarcode,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hargaEceranController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Eceran',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga eceran wajib diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _hargaGrosirController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Harga Grosir (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stok Awal',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok wajib diisi';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'SIMPAN PRODUK',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _hargaEceranController.dispose();
    _hargaGrosirController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  // Fungsi untuk scan barcode
  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Scan Barcode'),
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                Navigator.pop(context, barcodes.first.rawValue);
              }
            },
          ),
        ),
      ),
    );
    if (result != null) {
      _barcodeController.text = result;
    }
  }
}
