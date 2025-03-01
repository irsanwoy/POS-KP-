import 'package:flutter/material.dart';

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
    final dummyProducts = [
      Product(
        id: 1,
        name: 'Indomie Goreng',
        barcode: '8998866103006',
        hargaEceran: 3500,
        hargaGrosir: 3000,
        stock: 25,
      ),
      Product(
        id: 2,
        name: 'Aqua 600ml',
        barcode: '8999999024779',
        hargaEceran: 5000,
        hargaGrosir: 4500,
        stock: 50,
      ),
    ];
    
    setState(() {
      _products = dummyProducts;
      _filteredProducts = dummyProducts;
    });
  }

  void _searchProducts(String query) {
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query.toLowerCase()) ||
            product.barcode.contains(query);
      }).toList();
    });
  }

  void _deleteProduct(int id) {
    setState(() {
      _products.removeWhere((product) => product.id == id);
      _filteredProducts = _products;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: Colors.deepOrange, // Vibrant app bar color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _filteredProducts.length,
          itemBuilder: (context, index) {
            final product = _filteredProducts[index];
            return _ProductCard(
              product: product,
              onDelete: () => _deleteProduct(product.id!),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProductFormScreen()),
        ),
        backgroundColor: Colors.deepOrange, // Match FAB color to app bar
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.amber.shade100, // Colorful card background
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Barcode: ${product.barcode}', style: TextStyle(color: Colors.grey[700])),
            Text('Eceran: Rp ${product.hargaEceran}', style: TextStyle(color: Colors.green[800])),
            Text('Grosir: Rp ${product.hargaGrosir}', style: TextStyle(color: Colors.green[600])),
            Text('Stok: ${product.stock}', style: TextStyle(color: Colors.red[700])),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductFormScreen(product: product),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
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

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _barcodeController.text = widget.product!.barcode;
      _hargaEceranController.text = widget.product!.hargaEceran.toString();
      _hargaGrosirController.text = widget.product!.hargaGrosir.toString();
      _stockController.text = widget.product!.stock.toString();
    }
  }

  void _generateBarcode() {
    _barcodeController.text = DateTime.now().millisecondsSinceEpoch.toString();
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final newProduct = Product(
        id: widget.product?.id,
        name: _nameController.text,
        barcode: _barcodeController.text,
        hargaEceran: double.parse(_hargaEceranController.text),
        hargaGrosir: double.parse(_hargaGrosirController.text),
        stock: int.parse(_stockController.text),
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
        backgroundColor: Colors.deepOrange, // Matching the theme color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama produk wajib diisi';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(labelText: 'Barcode'),
                      readOnly: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code),
                    onPressed: _generateBarcode,
                  ),
                ],
              ),
              TextFormField(
                controller: _hargaEceranController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Eceran'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga eceran wajib diisi';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _hargaGrosirController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Harga Grosir'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga grosir wajib diisi';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok Awal'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange), // Consistent button color
                child: const Text('Simpan Produk'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Product {
  int? id;
  String name;
  String barcode;
  double hargaEceran;
  double hargaGrosir;
  int stock;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.hargaEceran,
    required this.hargaGrosir,
    required this.stock,
  });
}
