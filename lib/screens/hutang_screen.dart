import 'package:flutter/material.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/debt_model.dart';

class HutangScreen extends StatefulWidget {
  const HutangScreen({super.key});

  @override
  State<HutangScreen> createState() => _HutangScreenState();
}

class _HutangScreenState extends State<HutangScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Debt> _hutangList = [];
  List<Debt> _filteredHutangList = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showLunasOnly = false;

  @override
  void initState() {
    super.initState();
    _loadHutang();
  }

  Future<void> _loadHutang() async {
    try {
      final debts = await _dbHelper.getUnpaidDebts(); // Ambil semua hutang yang belum lunas
      setState(() {
        _hutangList = debts;
        _filteredHutangList = debts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat hutang: $e')),
      );
    }
  }

  void _searchHutang(String query) {
    setState(() {
      _filteredHutangList = _hutangList.where((hutang) {
        return hutang.namaPelanggan.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  void _toggleLunasOnly(bool value) {
    setState(() {
      _showLunasOnly = value;
      _filterHutang();
    });
  }

  void _filterHutang() {
    setState(() {
      _filteredHutangList = _hutangList.where((hutang) {
        final matchStatus = _showLunasOnly ? hutang.status == 'lunas' : true;
        return matchStatus;
      }).toList();
    });
  }

  Future<void> _deleteHutang(int id) async {
    try {
      await _dbHelper.deleteDebt(id); // Hapus hutang dari database
      setState(() {
        _hutangList.removeWhere((hutang) => hutang.idHutang == id);
        _filteredHutangList = _hutangList;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hutang berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus hutang: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // title: const Text('Pencatatan Hutang'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: HutangSearchDelegate(_hutangList),
              );
            },
          ),
        ],
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
            child: _filteredHutangList.isEmpty
                ? const Center(child: Text('Tidak ada hutang'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHutangList.length,
                    itemBuilder: (context, index) {
                      final hutang = _filteredHutangList[index];
                      return _HutangCard(
                        hutang: hutang,
                        onDelete: () => _deleteHutang(hutang.idHutang!),
                        onEdit: () async {
                          final shouldRefresh = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HutangFormScreen(debt: hutang),
                            ),
                          );
                          if (shouldRefresh == true) {
                            // Panggil ulang _loadHutang setelah selesai edit
                            await _loadHutang();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HutangFormScreen()),
          );
          if (shouldRefresh == true) {
            await _loadHutang();
          }
        },
        backgroundColor: Colors.deepOrange,

        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HutangCard extends StatelessWidget {
  final Debt hutang;
  final VoidCallback onDelete;
  final VoidCallback onEdit;  // Tambahkan callback untuk edit

  const _HutangCard({
    required this.hutang,
    required this.onDelete,
    required this.onEdit,  // Tambahkan parameter ini
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      color: hutang.status == 'lunas' ? Colors.green[50] : Colors.red[50],
      child: ListTile(
        title: Text(
          hutang.namaPelanggan,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jumlah: Rp ${hutang.totalHutang.toStringAsFixed(2)}'),
            if (hutang.tanggalJatuhTempo != null)
              Text(
                'Jatuh Tempo: ${hutang.tanggalJatuhTempo!.toLocal().toString().split(' ')[0]}',
              ),
            Text(
              'Status: ${hutang.status == 'lunas' ? 'Lunas' : 'Belum Lunas'}',
              style: TextStyle(
                color: hutang.status == 'lunas' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,  // Panggil fungsi onEdit ketika tombol edit ditekan
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

class HutangSearchDelegate extends SearchDelegate {
  final List<Debt> hutangList;

  HutangSearchDelegate(this.hutangList);

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
    final results = hutangList.where((hutang) {
      return hutang.namaPelanggan.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final hutang = results[index];
        return _HutangCard(
          hutang: hutang,
          onDelete: () {}, // Handle delete if needed
          onEdit: () {},   // Handle edit if needed
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

class HutangFormScreen extends StatefulWidget {
  final Debt? debt;

  const HutangFormScreen({super.key, this.debt});

  @override
  State<HutangFormScreen> createState() => _HutangFormScreenState();
}

class _HutangFormScreenState extends State<HutangFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaPelangganController = TextEditingController();
  final TextEditingController _totalHutangController = TextEditingController();
  final TextEditingController _tanggalJatuhTempoController = TextEditingController();
  String _status = 'belum lunas';

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _namaPelangganController.text = widget.debt!.namaPelanggan;
      _totalHutangController.text = widget.debt!.totalHutang.toString();
      _tanggalJatuhTempoController.text =
          widget.debt!.tanggalJatuhTempo?.toLocal().toString().split(' ')[0] ?? '';
      _status = widget.debt!.status;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      _tanggalJatuhTempoController.text = picked.toLocal().toString().split(' ')[0];
    }
  }

  void _saveHutang() async {
    if (_formKey.currentState!.validate()) {
      try {
        final newDebt = Debt(
          idHutang: widget.debt?.idHutang,
          namaPelanggan: _namaPelangganController.text,
          totalHutang: double.parse(_totalHutangController.text),
          status: _status,
          tanggalJatuhTempo: _tanggalJatuhTempoController.text.isNotEmpty
              ? DateTime.parse(_tanggalJatuhTempoController.text)
              : null,
        );

        if (newDebt.idHutang == null) {
          await DatabaseHelper().insertDebt(newDebt);
        } else {
          await DatabaseHelper().updateDebtStatus(newDebt.idHutang!, _status);
        }

        Navigator.pop(context, true);  // Kembalikan nilai true untuk refresh
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan hutang: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.debt == null ? 'Tambah Hutang' : 'Edit Hutang'),
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
                decoration: const InputDecoration(
                  labelText: 'Nama Pelanggan',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama pelanggan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _totalHutangController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Hutang',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Total hutang wajib diisi';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tanggalJatuhTempoController,
                decoration: const InputDecoration(
                  labelText: 'Tanggal Jatuh Tempo',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal jatuh tempo wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['belum lunas', 'lunas']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _status = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveHutang,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'SIMPAN HUTANG',
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
    _namaPelangganController.dispose();
    _totalHutangController.dispose();
    _tanggalJatuhTempoController.dispose();
    super.dispose();
  }
}
