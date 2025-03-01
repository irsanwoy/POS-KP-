import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  // Dummy data (TODO: Ganti dengan data real dari SQLite)
  double _totalPenjualanHariIni = 2500000;
  double _totalHutangAktif = 1750000;
  final List<Map<String, dynamic>> _lowStockProducts = [
    {'name': 'Indomie Goreng', 'stock': 5},
    {'name': 'Aqua 600ml', 'stock': 8},
    {'name': 'Minyak Goreng', 'stock': 3},
  ];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

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
            Expanded(
              child: _LowStockList(items: _lowStockProducts),
            ),
            
            // Quick Actions
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              children: [
                _QuickActionButton(
                  icon: Icons.add_box,
                  label: 'Tambah Produk',
                  onTap: () => _navigateToProductScreen(),
                ),
                _QuickActionButton(
                  icon: Icons.money_off,
                  label: 'Catat Hutang',
                  onTap: () => _navigateToDebtScreen(),
                ),
                _QuickActionButton(
                  icon: Icons.point_of_sale,
                  label: 'Transaksi Baru',
                  onTap: () => _navigateToTransactionScreen(),
                ),
                _QuickActionButton( // Tombol baru untuk Supplier
                  icon: Icons.local_shipping,
                  label: 'Kelola Supplier',
                  onTap: () => _navigateToSupplierScreen(),
                ),
              ],
            ),
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
      MaterialPageRoute(builder: (context) => const TransaksiScreen()),
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
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
  final List<Map<String, dynamic>> items;

  const _LowStockList({required this.items});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.orange),
            title: Text(item['name']),
            trailing: Chip(
              label: Text('${item['stock']}'),
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