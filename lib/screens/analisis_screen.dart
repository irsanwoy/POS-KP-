import 'package:flutter/material.dart';
import '../db/database_helper.dart';

class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({Key? key}) : super(key: key);

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _produkTerlaris = [];
  List<Map<String, dynamic>> _produkKurangLaris = [];
  List<Map<String, dynamic>> _produkTidakLaku = [];
  List<Map<String, dynamic>> _stokMenutipis = [];
  
  bool _isLoading = true;
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Pastikan length = 4
    _loadAnalisisData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalisisData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadProdukTerlaris(),
        _loadProdukKurangLaris(),
        _loadProdukTidakLaku(),
        _loadStokMenipis(),
      ]);
    } catch (e) {
      print('Error loading analisis data: $e');
      _showErrorDialog('Error memuat data: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadProdukTerlaris() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          p.id_produk,
          p.nama_produk,
          p.kategori,
          p.stok,
          p.harga_ecer,
          SUM(dt.jumlah) as total_terjual,
          COUNT(DISTINCT t.id_transaksi) as frekuensi_beli,
          SUM(dt.subtotal) as total_pendapatan
        FROM produk p
        JOIN detail_transaksi dt ON p.id_produk = dt.id_produk
        JOIN transaksi t ON dt.id_transaksi = t.id_transaksi
        WHERE DATE(t.tanggal) BETWEEN DATE(?) AND DATE(?)
        GROUP BY p.id_produk
        HAVING total_terjual > 0
        ORDER BY total_terjual DESC, frekuensi_beli DESC
        LIMIT 20
      ''', [_startDate.toIso8601String(), _endDate.toIso8601String()]);
      
      _produkTerlaris = result;
    } catch (e) {
      print('Error loading produk terlaris: $e');
      _produkTerlaris = [];
    }
  }

  Future<void> _loadProdukKurangLaris() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          p.id_produk,
          p.nama_produk,
          p.kategori,
          p.stok,
          p.harga_ecer,
          COALESCE(SUM(dt.jumlah), 0) as total_terjual,
          COUNT(DISTINCT t.id_transaksi) as frekuensi_beli,
          COALESCE(SUM(dt.subtotal), 0) as total_pendapatan
        FROM produk p
        LEFT JOIN detail_transaksi dt ON p.id_produk = dt.id_produk
        LEFT JOIN transaksi t ON dt.id_transaksi = t.id_transaksi
          AND DATE(t.tanggal) BETWEEN DATE(?) AND DATE(?)
        GROUP BY p.id_produk
        HAVING total_terjual > 0 AND total_terjual <= 5
        ORDER BY total_terjual ASC
        LIMIT 20
      ''', [_startDate.toIso8601String(), _endDate.toIso8601String()]);
      
      _produkKurangLaris = result;
    } catch (e) {
      print('Error loading produk kurang laris: $e');
      _produkKurangLaris = [];
    }
  }

  Future<void> _loadProdukTidakLaku() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          p.id_produk,
          p.nama_produk,
          p.kategori,
          p.stok,
          p.harga_ecer,
          0 as total_terjual,
          0 as frekuensi_beli,
          0 as total_pendapatan
        FROM produk p
        WHERE p.id_produk NOT IN (
          SELECT DISTINCT dt.id_produk
          FROM detail_transaksi dt
          JOIN transaksi t ON dt.id_transaksi = t.id_transaksi
          WHERE DATE(t.tanggal) BETWEEN DATE(?) AND DATE(?)
        )
        ORDER BY p.stok DESC
      ''', [_startDate.toIso8601String(), _endDate.toIso8601String()]);
      
      _produkTidakLaku = result;
    } catch (e) {
      print('Error loading produk tidak laku: $e');
      _produkTidakLaku = [];
    }
  }

  Future<void> _loadStokMenipis() async {
    try {
      final db = await _databaseHelper.database;
      final result = await db.rawQuery('''
        SELECT 
          p.id_produk,
          p.nama_produk,
          p.kategori,
          p.stok,
          p.harga_ecer,
          COALESCE(SUM(dt.jumlah), 0) as total_terjual,
          CASE 
            WHEN COALESCE(SUM(dt.jumlah), 0) > 0 
            THEN ROUND(p.stok * 1.0 / (COALESCE(SUM(dt.jumlah), 1) / 30.0), 1)
            ELSE 999
          END as hari_tersisa
        FROM produk p
        LEFT JOIN detail_transaksi dt ON p.id_produk = dt.id_produk
        LEFT JOIN transaksi t ON dt.id_transaksi = t.id_transaksi
          AND DATE(t.tanggal) BETWEEN DATE(?) AND DATE(?)
        WHERE p.stok <= 10
        GROUP BY p.id_produk
        ORDER BY p.stok ASC, hari_tersisa ASC
      ''', [_startDate.toIso8601String(), _endDate.toIso8601String()]);
      
      _stokMenutipis = result;
    } catch (e) {
      print('Error loading stok menipis: $e');
      _stokMenutipis = [];
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadAnalisisData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analisis Produk'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Pilih Periode',
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadAnalisisData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: false,
          tabs: [
            Tab(text: 'Terlaris'),
            Tab(text: 'Kurang Laris'),
            Tab(text: 'Tidak Laku'),
            Tab(text: 'Stok Tipis'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildPeriodeInfo(),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.red))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProdukTerlarisTab(),
                      _buildProdukKurangLarisTab(),
                      _buildProdukTidakLakuTab(),
                      _buildStokMenimpisTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodeInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.grey[100],
      width: double.infinity,
      child: Text(
        'Periode: ${_formatDate(_startDate)} - ${_formatDate(_endDate)}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProdukTerlarisTab() {
    if (_produkTerlaris.isEmpty) {
      return _buildEmptyState('Tidak ada data produk terlaris');
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.green[50],
          width: double.infinity,
          child: Row(
            children: [
              Icon(Icons.trending_up, color: Colors.green[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rekomendasi: Tambah stok untuk produk-produk ini',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _produkTerlaris.length,
            itemBuilder: (context, index) {
              final produk = _produkTerlaris[index];
              return _buildProdukCard(
                produk: produk,
                color: Colors.green,
                icon: Icons.trending_up,
                showRecommendation: true,
                recommendationType: 'TAMBAH STOK',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProdukKurangLarisTab() {
    if (_produkKurangLaris.isEmpty) {
      return _buildEmptyState('Tidak ada data produk kurang laris');
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.orange[50],
          width: double.infinity,
          child: Row(
            children: [
              Icon(Icons.trending_down, color: Colors.orange[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rekomendasi: Kurangi pembelian untuk produk-produk ini',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _produkKurangLaris.length,
            itemBuilder: (context, index) {
              final produk = _produkKurangLaris[index];
              return _buildProdukCard(
                produk: produk,
                color: Colors.orange,
                icon: Icons.trending_down,
                showRecommendation: true,
                recommendationType: 'KURANGI PEMBELIAN',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProdukTidakLakuTab() {
    if (_produkTidakLaku.isEmpty) {
      return _buildEmptyState('Semua produk ada yang terjual dalam periode ini');
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.red[50],
          width: double.infinity,
          child: Row(
            children: [
              Icon(Icons.block, color: Colors.red[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rekomendasi: Jangan beli lagi atau ganti produk',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _produkTidakLaku.length,
            itemBuilder: (context, index) {
              final produk = _produkTidakLaku[index];
              return _buildProdukCard(
                produk: produk,
                color: Colors.red,
                icon: Icons.block,
                showRecommendation: true,
                recommendationType: 'JANGAN BELI LAGI',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStokMenimpisTab() {
    if (_stokMenutipis.isEmpty) {
      return _buildEmptyState('Tidak ada produk dengan stok menipis');
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.blue[50],
          width: double.infinity,
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.blue[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Rekomendasi: Segera restok produk-produk ini',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _stokMenutipis.length,
            itemBuilder: (context, index) {
              final produk = _stokMenutipis[index];
              return _buildProdukCard(
                produk: produk,
                color: Colors.blue,
                icon: Icons.warning,
                showRecommendation: true,
                recommendationType: 'SEGERA RESTOK',
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProdukCard({
    required Map<String, dynamic> produk,
    required MaterialColor color, // Ganti dari Color ke MaterialColor
    required IconData icon,
    bool showRecommendation = false,
    String? recommendationType,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color[600], size: 20), // Sekarang bisa akses color[600]
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    produk['nama_produk'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (showRecommendation && recommendationType != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color[50], // Sekarang bisa akses color[50]
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color[200]!), // Sekarang bisa akses color[200]
                    ),
                    child: Text(
                      recommendationType,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color[800], // Sekarang bisa akses color[800]
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Kategori: ${produk['kategori'] ?? 'Tidak ada'}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Stok',
                    '${produk['stok'] ?? 0}',
                    (produk['stok'] ?? 0) <= 5 ? Colors.red : Colors.black,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Terjual',
                    '${produk['total_terjual'] ?? 0}',
                    Colors.black,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Harga',
                    _formatCurrency(produk['harga_ecer'] ?? 0),
                    Colors.black,
                  ),
                ),
              ],
            ),
            if (produk['hari_tersisa'] != null && 
                produk['hari_tersisa'] is num && 
                produk['hari_tersisa'] < 30 && 
                produk['hari_tersisa'] != 999) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.yellow[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.yellow[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange, size: 16),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Perkiraan habis dalam ${produk['hari_tersisa']} hari',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatCurrency(dynamic amount) {
    return 'Rp ${(amount ?? 0).toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}