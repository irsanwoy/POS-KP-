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
  
  // Controllers for editing or adding supplier
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kontakController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  
  // Variables to track whether it's add or edit
  bool isEditMode = false;
  Supplier? currentSupplier;

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

  void _saveSupplier() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newSupplier = Supplier(
          idSuplier: currentSupplier?.idSuplier,
          namaSuplier: _namaController.text,
          kontak: _kontakController.text.isNotEmpty ? _kontakController.text : null,
          alamat: _alamatController.text.isNotEmpty ? _alamatController.text : null,
        );

        if (newSupplier.idSuplier == null) {
          await _dbHelper.insertSupplier(newSupplier);
        } else {
          await _dbHelper.updateSupplier(newSupplier);
        }

        // Reset the form and load updated data
        setState(() {
          isEditMode = false;
          currentSupplier = null;
        });
        await _loadSuppliers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan supplier: $e')),
        );
      }
    }
  }

  void _editSupplier(Supplier supplier) {
    setState(() {
      isEditMode = true;
      currentSupplier = supplier;
      _namaController.text = supplier.namaSuplier;
      _kontakController.text = supplier.kontak ?? '';
      _alamatController.text = supplier.alamat ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Supplier' : 'Manajemen Supplier'),
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
      body: isEditMode
          ? _buildForm() // Show the form if in edit mode
          : _buildSupplierList(), // Otherwise, show the supplier list
      floatingActionButton: isEditMode
          ? null // Hide the FAB while editing
          : FloatingActionButton(
              onPressed: () {
                setState(() {
                  isEditMode = true;
                });
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildSupplierList() {
    return _filteredSuppliers.isEmpty
        ? const Center(child: Text('Tidak ada supplier'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredSuppliers.length,
            itemBuilder: (context, index) {
              final supplier = _filteredSuppliers[index];
              return _SupplierCard(
                supplier: supplier,
                onDelete: () => _deleteSupplier(supplier.idSuplier!),
                onEdit: () => _editSupplier(supplier),
              );
            },
          );
  }

  Widget _buildForm() {
    return Padding(
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
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isEditMode = false;
                  currentSupplier = null;
                  _namaController.clear();
                  _kontakController.clear();
                  _alamatController.clear();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'BATAL',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _SupplierCard({
    required this.supplier,
    required this.onDelete,
    required this.onEdit,
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
              onPressed: onEdit,
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
          onEdit: () {}, // Handle edit if needed
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}
