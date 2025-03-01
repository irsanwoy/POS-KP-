import 'package:flutter/material.dart';

class HutangScreen extends StatefulWidget {
  const HutangScreen({super.key});

  @override
  State<HutangScreen> createState() => _HutangScreenState();
}

class _HutangScreenState extends State<HutangScreen> {
  List<Hutang> _hutangList = [];
  List<Hutang> _filteredHutangList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showLunasOnly = false;

  @override
  void initState() {
    super.initState();
    _loadHutang();
  }

  Future<void> _loadHutang() async {
    final dummyHutang = [
      Hutang(
        id: 1,
        namaPelanggan: 'John Doe',
        jumlahHutang: 500000,
        tanggalHutang: DateTime(2024, 1, 15),
        jatuhTempo: DateTime(2024, 2, 15),
        isLunas: false,
      ),
      Hutang(
        id: 2,
        namaPelanggan: 'Jane Smith',
        jumlahHutang: 750000,
        tanggalHutang: DateTime(2024, 1, 20),
        jatuhTempo: DateTime(2024, 2, 20),
        isLunas: true,
      ),
    ];

    setState(() {
      _hutangList = dummyHutang;
      _filteredHutangList = dummyHutang;
    });
  }

  void _filterHutang(String query) {
    setState(() {
      _filteredHutangList = _hutangList.where((hutang) {
        final matchNama = hutang.namaPelanggan.toLowerCase().contains(query.toLowerCase());
        final matchStatus = _showLunasOnly ? hutang.isLunas : true;
        return matchNama && matchStatus;
      }).toList();
    });
  }

  void _toggleLunasOnly(bool value) {
    setState(() {
      _showLunasOnly = value;
      _filterHutang(_searchController.text);
    });
  }

  void _deleteHutang(int id) {
    setState(() {
      _hutangList.removeWhere((hutang) => hutang.id == id);
      _filteredHutangList = _hutangList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pencatatan Hutang'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Tampilkan Lunas Saja:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Switch(
                  value: _showLunasOnly,
                  onChanged: _toggleLunasOnly,
                  activeColor: Colors.greenAccent,
                  inactiveThumbColor: Colors.grey,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredHutangList.length,
              itemBuilder: (context, index) {
                final hutang = _filteredHutangList[index];
                return _HutangCard(
                  hutang: hutang,
                  onDelete: () => _deleteHutang(hutang.id!),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HutangFormScreen()),
        ),
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HutangCard extends StatelessWidget {
  final Hutang hutang;
  final VoidCallback onDelete;

  const _HutangCard({
    required this.hutang,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: hutang.isLunas ? Colors.green[50] : Colors.red[50],
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          hutang.namaPelanggan,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah: Rp ${hutang.jumlahHutang}', style: TextStyle(color: Colors.black)),
            Text(
                'Tanggal Hutang: ${hutang.tanggalHutang.toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: Colors.black)),
            Text(
                'Jatuh Tempo: ${hutang.jatuhTempo.toLocal().toString().split(' ')[0]}',
                style: TextStyle(color: Colors.black)),
            Text(
                'Status: ${hutang.isLunas ? 'Lunas' : 'Belum Lunas'}',
                style: TextStyle(
                    color: hutang.isLunas ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
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
                  builder: (context) => HutangFormScreen(hutang: hutang),
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

class HutangFormScreen extends StatefulWidget {
  final Hutang? hutang;

  const HutangFormScreen({super.key, this.hutang});

  @override
  State<HutangFormScreen> createState() => _HutangFormScreenState();
}

class _HutangFormScreenState extends State<HutangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaPelangganController = TextEditingController();
  final TextEditingController _jumlahHutangController = TextEditingController();
  final TextEditingController _tanggalHutangController = TextEditingController();
  final TextEditingController _jatuhTempoController = TextEditingController();
  bool _isLunas = false;

  @override
  void initState() {
    super.initState();
    if (widget.hutang != null) {
      _namaPelangganController.text = widget.hutang!.namaPelanggan;
      _jumlahHutangController.text = widget.hutang!.jumlahHutang.toString();
      _tanggalHutangController.text = widget.hutang!.tanggalHutang.toLocal().toString().split(' ')[0];
      _jatuhTempoController.text = widget.hutang!.jatuhTempo.toLocal().toString().split(' ')[0];
      _isLunas = widget.hutang!.isLunas;
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = picked.toLocal().toString().split(' ')[0];
    }
  }

  void _saveHutang() {
    if (_formKey.currentState!.validate()) {
      final newHutang = Hutang(
        id: widget.hutang?.id,
        namaPelanggan: _namaPelangganController.text,
        jumlahHutang: double.parse(_jumlahHutangController.text),
        tanggalHutang: DateTime.parse(_tanggalHutangController.text),
        jatuhTempo: DateTime.parse(_jatuhTempoController.text),
        isLunas: _isLunas,
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hutang == null ? 'Tambah Hutang' : 'Edit Hutang'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _namaPelangganController,
                decoration: const InputDecoration(labelText: 'Nama Pelanggan'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pelanggan wajib diisi';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _jumlahHutangController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Jumlah Hutang'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jumlah hutang wajib diisi';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _tanggalHutangController,
                decoration: const InputDecoration(labelText: 'Tanggal Hutang'),
                readOnly: true,
                onTap: () => _selectDate(context, _tanggalHutangController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal hutang wajib diisi';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _jatuhTempoController,
                decoration: const InputDecoration(labelText: 'Jatuh Tempo'),
                readOnly: true,
                onTap: () => _selectDate(context, _jatuhTempoController),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jatuh tempo wajib diisi';
                  }
                  return null;
                },
              ),
              SwitchListTile(
                title: const Text('Lunas'),
                value: _isLunas,
                onChanged: (value) {
                  setState(() {
                    _isLunas = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveHutang,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Simpan Hutang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Hutang {
  int? id;
  String namaPelanggan;
  double jumlahHutang;
  DateTime tanggalHutang;
  DateTime jatuhTempo;
  bool isLunas;

  Hutang({
    this.id,
    required this.namaPelanggan,
    required this.jumlahHutang,
    required this.tanggalHutang,
    required this.jatuhTempo,
    required this.isLunas,
  });
}
