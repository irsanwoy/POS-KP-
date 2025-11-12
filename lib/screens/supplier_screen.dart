import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/supplier_model.dart';
import '../models/product_model.dart';
import 'widgets/tambah_pembelian_dialog.dart';

class SupplierScreen extends StatefulWidget {
  final String userRole;
  
  const SupplierScreen({Key? key, this.userRole = 'pemilik'}) : super(key: key);

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  
  List<Supplier> _suppliers = [];
  List<Map<String, dynamic>> _pembelianSuplier = [];
  List<Product> _products = [];
  
  bool _isLoading = true;
  String _selectedView = 'supplier'; // 'supplier' atau 'pembelian'

  @override
  void initState() {
    super.initState();
    _loadData();
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
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.deepOrange))
          : Column(
              children: [
                // Segmented Button untuk Switch View
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          label: 'Supplier',
                          icon: Icons.business,
                          isSelected: _selectedView == 'supplier',
                          onTap: () {
                            setState(() {
                              _selectedView = 'supplier';
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: _buildSegmentButton(
                          label: 'Pembelian',
                          icon: Icons.shopping_cart,
                          isSelected: _selectedView == 'pembelian',
                          onTap: () {
                            setState(() {
                              _selectedView = 'pembelian';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _selectedView == 'supplier'
                      ? _buildSuppliersView()
                      : _buildPembelianView(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedView == 'supplier') {
            _showSupplierDialog();
          } else {
            _showPembelianDialog();
          }
        },
        backgroundColor: Colors.deepOrange,
        child: Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuppliersView() {
    if (_suppliers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada supplier',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: _suppliers.length,
      itemBuilder: (context, index) {
        final supplier = _suppliers[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.business,
                        color: Colors.deepOrange,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        supplier.namaSuplier,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editSupplier(supplier),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSupplier(supplier),
                    ),
                  ],
                ),
                if (supplier.kontak != null || supplier.alamat != null) ...[
                  SizedBox(height: 8),
                  if (supplier.kontak != null)
                    Row(
                      children: [
                        Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Text(
                          supplier.kontak!,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  if (supplier.alamat != null) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            supplier.alamat!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPembelianView() {
    if (_pembelianSuplier.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Belum ada pembelian',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
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
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.shopping_cart,
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PB-${pembelian['id_pembelian']}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            pembelian['nama_suplier'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      DateFormat('dd/MM/yyyy').format(tanggal),
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    SizedBox(width: 16),
                    Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      '${pembelian['total_items']} items',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                          .format(pembelian['total_harga']),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.deepOrange,
                      ),
                    ),
                    if (status != 'lunas')
                      TextButton.icon(
                        onPressed: () => _markAsPaid(pembelian['id_pembelian']),
                        icon: Icon(Icons.payment, size: 16),
                        label: Text('Bayar'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSupplierDialog({Supplier? supplier}) {
    final namaController = TextEditingController(text: supplier?.namaSuplier ?? '');
    final kontakController = TextEditingController(text: supplier?.kontak ?? '');
    final alamatController = TextEditingController(text: supplier?.alamat ?? '');
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
                        supplier == null ? Icons.add_business : Icons.business,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8),
                      Text(
                        supplier == null ? 'Tambah Supplier' : 'Edit Supplier',
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
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: namaController,
                            decoration: InputDecoration(
                              labelText: 'Nama Supplier',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.business),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama supplier wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: kontakController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Kontak (Opsional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: alamatController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              labelText: 'Alamat (Opsional)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: Icon(Icons.location_on),
                            ),
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
                          onPressed: isLoading ? null : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text('Batal'),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;

                                  setStateDialog(() {
                                    isLoading = true;
                                  });

                                  try {
                                    if (supplier == null) {
                                      // Add new
                                      final newSupplier = Supplier(
                                        namaSuplier: namaController.text.trim(),
                                        kontak: kontakController.text.isEmpty ? null : kontakController.text.trim(),
                                        alamat: alamatController.text.isEmpty ? null : alamatController.text.trim(),
                                      );
                                      await _dbHelper.insertSupplier(newSupplier);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Supplier berhasil ditambahkan'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } else {
                                      // Update existing
                                      final updatedSupplier = Supplier(
                                        idSuplier: supplier.idSuplier,
                                        namaSuplier: namaController.text.trim(),
                                        kontak: kontakController.text.isEmpty ? null : kontakController.text.trim(),
                                        alamat: alamatController.text.isEmpty ? null : alamatController.text.trim(),
                                      );
                                      await _dbHelper.updateSupplier(updatedSupplier);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Supplier berhasil diperbarui'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }

                                    Navigator.pop(context);
                                    _loadData();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Gagal menyimpan supplier: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  } finally {
                                    setStateDialog(() {
                                      isLoading = false;
                                    });
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
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
        ),
      ),
    );
  }

  void _editSupplier(Supplier supplier) {
    _showSupplierDialog(supplier: supplier);
  }

  void _deleteSupplier(Supplier supplier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Hapus Supplier'),
          ],
        ),
        content: Text('Hapus supplier "${supplier.namaSuplier}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _dbHelper.deleteSupplier(supplier.idSuplier!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Supplier berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal menghapus supplier: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showPembelianDialog() {
    showDialog(
      context: context,
      builder: (context) => TambahPembelianDialog(
        suppliers: _suppliers,
        products: _products,
        onSave: () {
          _loadData();
        },
      ),
    );
  }

  void _markAsPaid(int idPembelian) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi Pembayaran'),
        content: Text('Tandai pembelian ini sebagai sudah dibayar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _dbHelper.updateStatusPembayaran(idPembelian, 'lunas');
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Status pembayaran berhasil diperbarui'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal memperbarui status: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Ya, Sudah Bayar'),
          ),
        ],
      ),
    );
  }
}