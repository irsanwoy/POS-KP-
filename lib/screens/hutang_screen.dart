import 'package:flutter/material.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/debt_model.dart';
import 'package:intl/intl.dart';

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
      final debts = await _dbHelper.getAllDebts();
      setState(() {
        _hutangList = debts;
        _filteredHutangList = debts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat hutang: $e'),
          backgroundColor: Colors.red,
        ),
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

  Future<void> _deleteHutang(int id, String status) async {
    try {
      await _dbHelper.deleteDebt(id);
      setState(() {
        _hutangList.removeWhere((hutang) => hutang.idHutang == id);
        _filteredHutangList = _hutangList;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hutang berhasil dihapus'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus hutang: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showHutangDialog({Debt? debt}) {
    showDialog(
      context: context,
      builder: (context) => HutangFormDialog(
        debt: debt,
        onSaved: () {
          _loadHutang();
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
                delegate: HutangSearchDelegate(_hutangList),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _filteredHutangList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Tidak ada hutang',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredHutangList.length,
                    itemBuilder: (context, index) {
                      final hutang = _filteredHutangList[index];
                      return _HutangCard(
                        hutang: hutang,
                        onDelete: () => _deleteHutang(hutang.idHutang!, hutang.status),
                        onEdit: () => _showHutangDialog(debt: hutang),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showHutangDialog(),
        backgroundColor: Colors.deepOrange,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HutangCard extends StatelessWidget {
  final Debt hutang;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _HutangCard({
    required this.hutang,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final isLunas = hutang.status == 'lunas';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      elevation: 2,
      color: isLunas ? Colors.green.shade50 : Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLunas ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            // Leading Icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isLunas ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isLunas ? Icons.check_circle : Icons.warning,
                color: isLunas ? Colors.green.shade700 : Colors.red.shade700,
                size: 26,
              ),
            ),
            SizedBox(width: 10),
            
            // Content - Gunakan Expanded agar tidak overflow
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hutang.namaPelanggan,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    currencyFormat.format(hutang.totalHutang),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hutang.tanggalJatuhTempo != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Jatuh Tempo: ${DateFormat('dd/MM/yyyy').format(hutang.tanggalJatuhTempo!)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 6),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLunas ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isLunas ? 'LUNAS' : 'BELUM LUNAS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Trailing Actions
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                  onPressed: onEdit,
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red, size: 22),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange),
                            SizedBox(width: 8),
                            Text('Hapus Hutang'),
                          ],
                        ),
                        content: Text(
                          isLunas 
                            ? 'Hapus hutang yang sudah LUNAS atas nama "${hutang.namaPelanggan}"?\n\nData ini akan dihapus permanen.'
                            : 'Hapus hutang atas nama "${hutang.namaPelanggan}"?',
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
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Hapus'),
                          ),
                        ],
                      ),
                    );
                  },
                  padding: EdgeInsets.all(8),
                  constraints: BoxConstraints(),
                ),
              ],
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
        return ListTile(
          title: Text(hutang.namaPelanggan),
          subtitle: Text('Rp ${hutang.totalHutang.toStringAsFixed(0)}'),
          trailing: Text(
            hutang.status.toUpperCase(),
            style: TextStyle(
              color: hutang.status == 'lunas' ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () => close(context, hutang),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

// Dialog Form untuk Hutang
class HutangFormDialog extends StatefulWidget {
  final Debt? debt;
  final VoidCallback onSaved;

  const HutangFormDialog({
    super.key,
    this.debt,
    required this.onSaved,
  });

  @override
  State<HutangFormDialog> createState() => _HutangFormDialogState();
}

class _HutangFormDialogState extends State<HutangFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _namaPelangganController = TextEditingController();
  final TextEditingController _totalHutangController = TextEditingController();
  final TextEditingController _tanggalJatuhTempoController = TextEditingController();
  String _status = 'belum lunas';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _namaPelangganController.text = widget.debt!.namaPelanggan;
      _totalHutangController.text = widget.debt!.totalHutang.toString();
      _tanggalJatuhTempoController.text =
          widget.debt!.tanggalJatuhTempo != null
              ? DateFormat('yyyy-MM-dd').format(widget.debt!.tanggalJatuhTempo!)
              : '';
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
      _tanggalJatuhTempoController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _saveHutang() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newDebt = Debt(
        idHutang: widget.debt?.idHutang,
        namaPelanggan: _namaPelangganController.text.trim(),
        totalHutang: double.parse(_totalHutangController.text),
        status: _status,
        tanggalJatuhTempo: _tanggalJatuhTempoController.text.isNotEmpty
            ? DateTime.parse(_tanggalJatuhTempoController.text)
            : null,
      );

      if (newDebt.idHutang == null) {
        await DatabaseHelper().insertDebt(newDebt);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hutang berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await DatabaseHelper().updateDebtStatus(newDebt.idHutang!, _status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hutang berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan hutang: $e'),
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
    _namaPelangganController.dispose();
    _totalHutangController.dispose();
    _tanggalJatuhTempoController.dispose();
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
                    widget.debt == null ? Icons.add_box : Icons.edit,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    widget.debt == null ? 'Tambah Hutang' : 'Edit Hutang',
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
                        controller: _namaPelangganController,
                        decoration: InputDecoration(
                          labelText: 'Nama Pelanggan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Nama pelanggan wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _totalHutangController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Total Hutang',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.attach_money),
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
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _tanggalJatuhTempoController,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Jatuh Tempo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.calendar_today),
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
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _status,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: Icon(Icons.info),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'belum lunas',
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Belum Lunas'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'lunas',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text('Lunas'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _status = value!;
                          });
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
                      onPressed: _isLoading ? null : _saveHutang,
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