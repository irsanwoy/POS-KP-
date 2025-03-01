import 'package:flutter/material.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  List<Supplier> _suppliers = [];
  List<Supplier> _filteredSuppliers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    final dummySuppliers = [
      Supplier(
        id: 1,
        nama: 'PT. Sumber Makmur',
        kontak: '0812-3456-7890',
        alamat: 'Jl. Raya No. 123, Jakarta',
      ),
      Supplier(
        id: 2,
        nama: 'CV. Sejahtera Abadi',
        kontak: '0813-4567-8901',
        alamat: 'Jl. Merdeka No. 45, Bandung',
      ),
    ];

    setState(() {
      _suppliers = dummySuppliers;
      _filteredSuppliers = dummySuppliers;
    });
  }

  void _searchSuppliers(String query) {
    setState(() {
      _filteredSuppliers = _suppliers.where((supplier) {
        return supplier.nama.toLowerCase().contains(query.toLowerCase()) ||
            supplier.kontak.contains(query) ||
            supplier.alamat.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _deleteSupplier(int id) {
    setState(() {
      _suppliers.removeWhere((supplier) => supplier.id == id);
      _filteredSuppliers = _suppliers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal, // Warna yang lebih cerah pada AppBar
        title: const Text('Manajemen Supplier', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SupplierSearchDelegate(suppliers: _suppliers),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: _filteredSuppliers.length,
          itemBuilder: (context, index) {
            final supplier = _filteredSuppliers[index];
            return _SupplierCard(
              supplier: supplier,
              onDelete: () => _deleteSupplier(supplier.id!),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SupplierFormScreen()),
        ),
        child: const Icon(Icons.add),
        backgroundColor: Colors.orange, // Warna tombol yang cerah
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
      elevation: 4, // Menambahkan bayangan pada card
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Sudut card lebih melengkung
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          supplier.nama,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kontak: ${supplier.kontak}', style: const TextStyle(color: Colors.grey)),
            Text('Alamat: ${supplier.alamat}', style: const TextStyle(color: Colors.grey)),
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
                  builder: (context) => SupplierFormScreen(supplier: supplier),
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
      _namaController.text = widget.supplier!.nama;
      _kontakController.text = widget.supplier!.kontak;
      _alamatController.text = widget.supplier!.alamat;
    }
  }

  void _saveSupplier() {
    if (_formKey.currentState!.validate()) {
      final newSupplier = Supplier(
        id: widget.supplier?.id,
        nama: _namaController.text,
        kontak: _kontakController.text,
        alamat: _alamatController.text,
      );

      Navigator.pop(context);
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
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama supplier wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _kontakController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Kontak',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Kontak wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _alamatController,
                decoration: const InputDecoration(
                  labelText: 'Alamat',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveSupplier,
                child: const Text('Simpan Supplier'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal, // Warna tombol yang konsisten
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Supplier {
  int? id;
  String nama;
  String kontak;
  String alamat;

  Supplier({
    this.id,
    required this.nama,
    required this.kontak,
    required this.alamat,
  });
}

class SupplierSearchDelegate extends SearchDelegate<Supplier> {
  final List<Supplier> suppliers;

  SupplierSearchDelegate({required this.suppliers});

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
        close(context, Supplier(id: 0, nama: '', kontak: '', alamat: ''));
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = suppliers.where((supplier) {
      return supplier.nama.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView(
      children: results.map((supplier) {
        return ListTile(
          title: Text(supplier.nama),
          subtitle: Text(supplier.kontak),
        );
      }).toList(),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = suppliers.where((supplier) {
      return supplier.nama.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView(
      children: suggestions.map((supplier) {
        return ListTile(
          title: Text(supplier.nama),
          subtitle: Text(supplier.kontak),
        );
      }).toList(),
    );
  }
}
