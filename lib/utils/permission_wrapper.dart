// 3. Buat widget helper untuk permission-aware UI
// File: lib/widgets/permission_wrapper.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/permissions.dart';

class PermissionWrapper extends StatelessWidget {
  final String userRole;
  final String requiredPermission;
  final Widget child;
  final Widget? fallback;
  final bool showFallback;

  const PermissionWrapper({
    Key? key,
    required this.userRole,
    required this.requiredPermission,
    required this.child,
    this.fallback,
    this.showFallback = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (UserPermissions.hasPermission(userRole, requiredPermission)) {
      return child;
    } else if (showFallback && fallback != null) {
      return fallback!;
    } else if (showFallback) {
      return Container(
        padding: EdgeInsets.all(16),
        child: Card(
          color: Colors.grey[100],
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.grey[400], size: 48),
                SizedBox(height: 12),
                Text(
                  'Akses Terbatas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Anda tidak memiliki izin untuk mengakses fitur ini',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }
}

// 4. Update DashboardScreen dengan permission checking
class DashboardScreen extends StatefulWidget {
  final String userRole;
  
  const DashboardScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Data dashboard
  double _penjualanHariIni = 0.0;
  double _hutangAktif = 0.0;
  int _stokMenipis = 0;
  int _totalTransaksi = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // Load data sesuai dengan permission level
    // Implementation sesuai dengan logic dashboard yang ada
  }

  Widget _buildFinancialCard(String title, double amount, Color color) {
    return PermissionWrapper(
      userRole: widget.userRole,
      requiredPermission: 'view_financial_data',
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              SizedBox(height: 8),
              Text(
                NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(amount),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
      fallback: Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              SizedBox(height: 8),
              Text(
                'Data Terbatas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, String requiredPermission, VoidCallback onTap) {
    return PermissionWrapper(
      userRole: widget.userRole,
      requiredPermission: requiredPermission,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 32),
                SizedBox(height: 8),
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
      showFallback: false, // Hide completely jika tidak ada permission
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header dengan role-specific greeting
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red, Colors.red[300]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.userRole == UserPermissions.PEMILIK ? Icons.business_center : Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userRole == UserPermissions.PEMILIK ? 'Selamat datang, Pemilik' : 'Selamat datang, Kasir',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'id').format(DateTime.now()),
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Cards ringkasan dengan permission checking
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _buildFinancialCard('Penjualan Hari Ini', _penjualanHariIni, Colors.green),
                  _buildFinancialCard('Hutang Aktif', _hutangAktif, Colors.orange),
                  
                  // Card untuk semua role
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stok Menipis', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          SizedBox(height: 8),
                          Text(
                            '$_stokMenipis Items',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Transaksi Hari Ini', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                          SizedBox(height: 8),
                          Text(
                            '$_totalTransaksi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // Quick Actions dengan permission
              Text(
                'Aksi Cepat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _buildQuickActionCard(
                    'Transaksi Baru',
                    Icons.add_shopping_cart,
                    Colors.red,
                    'create_transaction',
                    () => Navigator.pushNamed(context, '/transaction'),
                  ),
                  _buildQuickActionCard(
                    'Kelola Produk',
                    Icons.inventory,
                    Colors.blue,
                    'manage_products',
                    () => Navigator.pushNamed(context, '/products'),
                  ),
                  _buildQuickActionCard(
                    'Lihat Analisis',
                    Icons.analytics,
                    Colors.green,
                    'view_analytics',
                    () => Navigator.pushNamed(context, '/analisis'),
                  ),
                ].where((widget) => widget != null).toList().cast<Widget>(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. Update konstruktor screen lain untuk menerima userRole
class TransaksiScreen extends StatefulWidget {
  final String userRole;

  const TransaksiScreen({Key? key, this.userRole = 'kasir'}) : super(key: key);

  @override
  State<TransaksiScreen> createState() => _TransaksiScreenState();
}

class _TransaksiScreenState extends State<TransaksiScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaksi')),
      body: Center(child: Text('Halaman Transaksi')),
    );
  }
}

class ProdukScreen extends StatefulWidget {
  final String userRole;

  const ProdukScreen({Key? key, this.userRole = 'kasir'}) : super(key: key);

  @override
  State<ProdukScreen> createState() => _ProdukScreenState();
}

class _ProdukScreenState extends State<ProdukScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manajemen Produk')),
      body: Center(child: Text('Halaman Produk')),
    );
  }
}

class HutangScreen extends StatefulWidget {
  final String userRole;

  const HutangScreen({Key? key, this.userRole = 'kasir'}) : super(key: key);

  @override
  State<HutangScreen> createState() => _HutangScreenState();
}

class _HutangScreenState extends State<HutangScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hutang')),
      body: Center(child: Text('Halaman Hutang')),
    );
  }
}

class SupplierScreen extends StatefulWidget {
  final String userRole;

  const SupplierScreen({Key? key, this.userRole = 'kasir'}) : super(key: key);

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Supplier')),
      body: Center(child: Text('Halaman Supplier')),
    );
  }
}