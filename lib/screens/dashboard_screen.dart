import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/db/database_helper.dart';
import 'package:pos/models/product_model.dart';
import 'package:pos/models/debt_model.dart';
import 'package:pos/screens/hutang_screen.dart';
import 'package:pos/screens/produk_screen.dart';
import 'package:pos/screens/transaksi_screen.dart';
import 'package:pos/screens/supplier_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  double _totalPenjualanHariIni = 0.0;
  double _totalHutangAktif = 0.0;
  List<Product> _lowStockProducts = [];
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Hitung total penjualan hari ini
      final today = DateTime.now();
      final totalSales = await _dbHelper.getTotalSales(today, today);
      setState(() {
        _totalPenjualanHariIni = totalSales;
      });

      // Hitung total hutang aktif
      final unpaidDebts = await _dbHelper.getUnpaidDebts();
      final totalDebt = unpaidDebts.fold(0.0, (sum, debt) => sum + debt.totalHutang);
      setState(() {
        _totalHutangAktif = totalDebt;
      });

      // Ambil daftar produk dengan stok rendah (misalnya < 10)
      final products = await _dbHelper.getAllProducts();
      setState(() {
        _lowStockProducts = products.where((product) => product.stok < 10).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Navigasi ke notifikasi
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement scan barcode
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistik Cepat
            Row(
              children: [
                _MetricCard(
                  title: 'Penjualan Hari Ini',
                  value: _currencyFormat.format(_totalPenjualanHariIni),
                  color: Colors.blue[100]!,
                ),
                const SizedBox(width: 16),
                _MetricCard(
                  title: 'Hutang Aktif',
                  value: _currencyFormat.format(_totalHutangAktif),
                  color: Colors.orange[100]!,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stok Rendah
            const Text(
              'Stok Hampir Habis',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(child: _LowStockList(items: _lowStockProducts)),
          ],
        ),
      ),
    );
  }

  void _navigateToProductScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProdukScreen()),
    );
  }

  void _navigateToDebtScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HutangScreen()),
    );
  }

  void _navigateToTransactionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TransaksiScreen()),
    );
  }

  void _navigateToSupplierScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupplierScreen()),
    );
  }
}

// Custom Widget: Kartu Metrik
class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Widget: Daftar Stok Rendah
class _LowStockList extends StatelessWidget {
  final List<Product> items;

  const _LowStockList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final product = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text(product.namaProduk),
            trailing: Chip(
              label: Text('${product.stok}'),
              backgroundColor: Colors.red[100],
            ),
          ),
        );
      },
    );
  }
}

// Custom Widget: Tombol Quick Action
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      
    );
    
  }
}