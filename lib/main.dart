// main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaksi_screen.dart';
import 'screens/produk_screen.dart';
import 'screens/hutang_screen.dart';
import 'screens/supplier_screen.dart';
import 'screens/analisis_screen.dart'; // Import screen analisis baru
import 'components/bottom_navbar.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRC Rudi - Toko Kelontong',
      debugShowCheckedModeBanner: false,
      // Mulai dari login screen
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/cashier_dashboard': (context) => MainScreen(userRole: 'kasir'),
        '/owner_dashboard': (context) => MainScreen(userRole: 'pemilik'),
        '/analisis': (context) => AnalisisScreen(), // Route untuk analisis
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final String userRole;
  
  const MainScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  late List<Widget> _screens;
  late List<String> _titles;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    if (widget.userRole == 'pemilik') {
      // Pemilik bisa akses semua fitur termasuk analisis
      _screens = [
        DashboardScreen(),
        TransaksiScreen(),
        ProdukScreen(),
        HutangScreen(),
        SupplierScreen(),
        AnalisisScreen(), // Tambahkan screen analisis
      ];
      _titles = ['Dashboard', 'Transaksi', 'Produk', 'Hutang', 'Supplier', 'Analisis'];
    } else {
      // Kasir tidak bisa akses analisis (hanya pemilik)
      _screens = [
        DashboardScreen(),
        TransaksiScreen(),
        ProdukScreen(),
        HutangScreen(),
      ];
      _titles = ['Dashboard', 'Transaksi', 'Produk', 'Hutang'];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin keluar?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/');
              },
              child: Text('Ya, Keluar'),
            ),
          ],
        );
      },
    );
  }

  // Bottom nav khusus untuk kasir (tanpa supplier dan analisis)
  Widget _buildCashierBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: 'Transaksi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Produk',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.money_off),
          label: 'Hutang',
        ),
      ],
    );
  }

  // Bottom nav khusus untuk pemilik (dengan semua fitur termasuk analisis)
  Widget _buildOwnerBottomNavBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: 'Transaksi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory),
          label: 'Produk',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.money_off),
          label: 'Hutang',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_shipping),
          label: 'Supplier',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analisis',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Indikator role user
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              widget.userRole.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Tombol logout
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: widget.userRole == 'pemilik' 
        ? _buildOwnerBottomNavBar()
        : _buildCashierBottomNavBar(),
    );
  }
}