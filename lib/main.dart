// main.dart - Fixed version
import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaksi_screen.dart';
import 'screens/produk_screen.dart';
import 'screens/hutang_screen.dart';
import 'screens/supplier_screen.dart';
import 'screens/analisis_screen.dart';
import 'components/bottom_navbar.dart';

// Simple permission constants untuk sementara
class UserPermissions {
  static const String KASIR = 'kasir';
  static const String PEMILIK = 'pemilik';

  static bool canAccessScreen(String userRole, String screenName) {
    switch (screenName) {
      case 'dashboard':
        return true; // Semua role bisa akses dashboard
      case 'transaction':
        return userRole == KASIR; // Semua role bisa akses (dengan level berbeda)
      case 'products':
        return true; // Semua role bisa akses (dengan level berbeda)
      case 'debt':
        return userRole == KASIR; // Semua role bisa akses (dengan level berbeda)
      case 'suppliers':
        return userRole == PEMILIK; // Hanya pemilik
      case 'analytics':
        return userRole == PEMILIK; // Hanya pemilik
      default:
        return false;
    }
  }
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SRC Rudi - Toko Kelontong',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => LoadingScreen(
          nextScreen: LoginScreen(),
          loadingText: 'Memuat aplikasi kasir...',
          durationSeconds: 3,
        ),
        '/login': (context) => LoginScreen(),
        '/cashier_dashboard': (context) => MainScreen(userRole: UserPermissions.KASIR),
        '/owner_dashboard': (context) => MainScreen(userRole: UserPermissions.PEMILIK),
        '/analisis': (context) => AnalisisScreen(),
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
  late List<String> _screenNames;

  @override
  void initState() {
    super.initState();
    _initializeScreensBasedOnRole();
  }

  void _initializeScreensBasedOnRole() {
    _screens = [];
    _titles = [];
    _screenNames = [];

    // Dashboard - semua role bisa akses
    if (UserPermissions.canAccessScreen(widget.userRole, 'dashboard')) {
      _screens.add(DashboardScreen()); // Sementara tanpa userRole parameter
      _titles.add('Dashboard');
      _screenNames.add('dashboard');
    }

    // Transaksi - kasir full access, pemilik read-only
    if (UserPermissions.canAccessScreen(widget.userRole, 'transaction')) {
      _screens.add(TransaksiScreen()); // Gunakan konstruktor existing
      _titles.add('Transaksi');
      _screenNames.add('transaction');
    }

    // Produk - kasir full access, pemilik read-only
    if (UserPermissions.canAccessScreen(widget.userRole, 'products')) {
      _screens.add(ProdukScreen());
      _titles.add('Produk');
      _screenNames.add('products');
    }

    // Hutang - kasir full access, pemilik read-only
    if (UserPermissions.canAccessScreen(widget.userRole, 'debt')) {
      _screens.add(HutangScreen());
      _titles.add('Hutang');
      _screenNames.add('debt');
    }

    // Supplier - hanya pemilik
    if (UserPermissions.canAccessScreen(widget.userRole, 'suppliers')) {
      _screens.add(SupplierScreen());
      _titles.add('Supplier');
      _screenNames.add('suppliers');
    }

    // Analisis - hanya pemilik
    if (UserPermissions.canAccessScreen(widget.userRole, 'analytics')) {
      _screens.add(AnalisisScreen());
      _titles.add('Analisis');
      _screenNames.add('analytics');
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
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/', 
                  (route) => false,
                );
              },
              child: Text('Ya, Keluar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigation() {
    List<BottomNavigationBarItem> items = [];
    
    for (int i = 0; i < _titles.length; i++) {
      IconData icon;
      switch (_screenNames[i]) {
        case 'dashboard':
          icon = Icons.home;
          break;
        case 'transaction':
          icon = Icons.point_of_sale;
          break;
        case 'products':
          icon = Icons.inventory;
          break;
        case 'debt':
          icon = Icons.money_off;
          break;
        case 'suppliers':
          icon = Icons.local_shipping;
          break;
        case 'analytics':
          icon = Icons.analytics;
          break;
        default:
          icon = Icons.circle;
      }
      
      items.add(BottomNavigationBarItem(
        icon: Icon(icon),
        label: _titles[i],
      ));
    }

    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 12,
      unselectedFontSize: 10,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles.isNotEmpty ? _titles[_selectedIndex] : 'Dashboard'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          // Role indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: widget.userRole == UserPermissions.PEMILIK 
                  ? Colors.orange.withOpacity(0.2) 
                  : Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.userRole == UserPermissions.PEMILIK 
                      ? Icons.business_center 
                      : Icons.person,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 4),
                Text(
                  widget.userRole.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _screens.isNotEmpty ? _screens[_selectedIndex] : Center(
        child: Text('No accessible screens for this role'),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
}