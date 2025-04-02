import 'package:flutter/material.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/supplier_model.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    try {
      final suppliers = await _dbHelper.getAllSuppliers();
      setState(() {
        _suppliers = suppliers;
        _filteredSuppliers = suppliers;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat supplier: $e')),
      );
    }
  }

  void _searchSuppliers(String query) {
    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        return supplier.namaSuplier.toLowerCase().contains(query.toLowerCase()) ||
            (supplier.kontak != null && supplier.kontak!.contains(query)) ||
            (supplier.alamat != null && supplier.alamat!.toLowerCase().contains(query.toLowerCase()));
      }).toList();
    });
  }

  Future<void> _deleteSupplier(int idSuplier) async {
    try {
      await _dbHelper.deleteSupplier(idSuplier);
      setState(() {
        _suppliers.removeWhere((supplier) => supplier.idSuplier == idSuplier);
        _filteredSuppliers = _suppliers;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus supplier: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Supplier'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SupplierSearchDelegate(_suppliers),
              );
            },
          ),
        ],
      ),
      body: _filteredSuppliers.isEmpty
          ? const Center(child: Text('Tidak ada supplier'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSuppliers.length,
              itemBuilder: (context, index) {
                final supplier = _filteredSuppliers[index];
                return _SupplierCard(
                  supplier: supplier,
                  onDelete: () => _deleteSupplier(supplier.idSuplier!),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupplierFormScreen()),
          );
          if (shouldRefresh == true) {
            await _loadSuppliers();
          }
        },
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onDelete;

  const _SupplierCard({
    required this.supplier,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          supplier.namaSuplier,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (supplier.kontak != null)
              Text('Kontak: ${supplier.kontak}', style: const TextStyle(color: Colors.grey)),
            if (supplier.alamat != null)
              Text('Alamat: ${supplier.alamat}', style: const TextStyle(color: Colors.grey)),
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
                    builder: (context) => SupplierFormScreen(supplier: supplier),
                  ),
                );
                if (shouldRefresh == true) {
                  // Trigger reload
                  Navigator.pop(context, true);
                }
              },
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

class SupplierSearchDelegate extends SearchDelegate<Supplier> {
  final List<Supplier> suppliers;

  SupplierSearchDelegate(this.suppliers);

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
        close(context, Supplier(idSuplier: 0, namaSuplier: '', kontak: '', alamat: ''));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = suppliers.where((supplier) {
      return supplier.namaSuplier.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final supplier = results[index];
        return _SupplierCard(
          supplier: supplier,
          onDelete: () {}, // Handle delete if needed
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kontakController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.supplier != null) {
      _namaController.text = widget.supplier!.namaSuplier;
      _kontakController.text = widget.supplier!.kontak ?? '';
      _alamatController.text = widget.supplier!.alamat ?? '';
    }
  }

  void _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newSupplier = Supplier(
          idSuplier: widget.supplier?.idSuplier,
          namaSuplier: _namaController.text,
          kontak: _kontakController.text.isNotEmpty ? _kontakController.text : null,
          alamat: _alamatController.text.isNotEmpty ? _alamatController.text : null,
        );

        if (newSupplier.idSuplier == null) {
          await DatabaseHelper().insertSupplier(newSupplier);
        } else {
          await DatabaseHelper().updateSupplier(newSupplier);
        }

        Navigator.pop(context, true);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan supplier: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama Supplier',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama supplier wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kontakController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Kontak',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveSupplier,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'SIMPAN SUPPLIER',
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
    _namaController.dispose();
    _kontakController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
}