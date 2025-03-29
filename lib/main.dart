// main.dart
import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/transaksi_screen.dart';
import 'screens/produk_screen.dart';
import 'screens/hutang_screen.dart';
import 'screens/supplier_screen.dart';
import 'components/bottom_navbar.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    DashboardScreen(),
    TransaksiScreen(),
    ProdukScreen(),
    HutangScreen(),
    SupplierScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}