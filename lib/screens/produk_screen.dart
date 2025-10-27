import 'package:flutter/material.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/product_model.dart';
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
        SnackBar(
          content: Text('Gagal memuat produk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _searchProducts(String query) {
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.namaProduk.toLowerCase().contains(query.toLowerCase()) ||
            (product.barcode != null && product.barcode!.contains(query));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus produk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showProductDialog({Product? product}) {
    showDialog(
      context: context,
      builder: (context) => ProductFormDialog(
        product: product,
        onSaved: () {
          _loadProducts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
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
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Tidak ada produk',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                return _ProductCard(
                  product: product,
                  onEdit: () => _showProductDialog(product: product),
                  onDelete: () => _deleteProduct(product.idProduk!),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProductDialog(),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

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
            Text('Harga Ecer: Rp ${product.hargaEcer.toStringAsFixed(0)}'),
            if (product.hargaGrosir != null)
              Text('Harga Grosir: Rp ${product.hargaGrosir!.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            Text(
              'Stok: ${product.stok}',
              style: TextStyle(
                color: product.stok < 10 ? Colors.red : Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Hapus Produk'),
                    content: Text('Hapus "${product.namaProduk}"?'),
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
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        return ListTile(
          title: Text(product.namaProduk),
          subtitle: Text('Stok: ${product.stok}'),
          onTap: () => close(context, product),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

// Dialog Form untuk Produk
class ProductFormDialog extends StatefulWidget {
  final Product? product;
  final VoidCallback onSaved;

  const ProductFormDialog({
    super.key,
    this.product,
    required this.onSaved,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _hargaEceranController = TextEditingController();
  final TextEditingController _hargaGrosirController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  int? _selectedSupplierId;
  List<Supplier> _suppliers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    if (widget.product != null) {
      _nameController.text = widget.product!.namaProduk;
      _barcodeController.text = widget.product!.barcode ?? '';
      _hargaEceranController.text = widget.product!.hargaEcer.toString();
      _hargaGrosirController.text = widget.product!.hargaGrosir?.toString() ?? '';
      _stockController.text = widget.product!.stok.toString();
      _selectedSupplierId = widget.product!.idSuplier;
    }
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await DatabaseHelper().getAllSuppliers();
      setState(() {
        _suppliers = suppliers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat supplier: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newProduct = Product(
        idProduk: widget.product?.idProduk,
        namaProduk: _nameController.text.trim(),
        hargaEcer: double.parse(_hargaEceranController.text),
        hargaGrosir: _hargaGrosirController.text.isNotEmpty
            ? double.parse(_hargaGrosirController.text)
            : null,
        stok: int.parse(_stockController.text),
        barcode: _barcodeController.text.isNotEmpty
            ? _barcodeController.text.trim()
            : null,
        idSuplier: _selectedSupplierId,
      );

      if (newProduct.idProduk == null) {
        await DatabaseHelper().insertProduct(newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produk berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await DatabaseHelper().updateProduct(newProduct);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produk berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan produk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.product == null ? Icons.add_box : Icons.edit,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    widget.product == null ? 'Tambah Produk' : 'Edit Produk',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Produk',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.inventory_2),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<int>(
                        value: _selectedSupplierId,
                        decoration: InputDecoration(
                          labelText: 'Pilih Supplier',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.local_shipping),
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
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          labelText: 'Barcode',
                          hintText: 'Scan atau ketik manual',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _hargaEceranController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga Eceran',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.attach_money),
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
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _hargaGrosirController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga Grosir (opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (double.tryParse(value) == null) {
                              return 'Masukkan angka yang valid';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Stok Awal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.storage),
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
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Batal'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(
                              'Simpan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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