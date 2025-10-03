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
  List<Map<String, dynamic>> _stokMenipis = [];
  
  bool _isLoading = true;
  String _selectedPeriod = '30 hari terakhir';
  DateTime _startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final Map<String, int> _periodDays = {
    '7 hari terakhir': 7,
    '30 hari terakhir': 30,
    '3 bulan terakhir': 90,
    '6 bulan terakhir': 180,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalisisData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changePeriod(String period) {
    final days = _periodDays[period] ?? 30;
    setState(() {
      _selectedPeriod = period;
      _startDate = DateTime.now().subtract(Duration(days: days));
      _endDate = DateTime.now();
    });
    _loadAnalisisData();
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
      
      _stokMenipis = result;
    } catch (e) {
      print('Error loading stok menipis: $e');
      _stokMenipis = [];
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeaderSection(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProdukTerlarisTab(),
                      _buildProdukKurangLarisTab(),
                      _buildProdukTidakLakuTab(),
                      _buildStokMenipisTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Period Selector
          
          // Summary Stats
          // _buildSummaryStats(),
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: [
                Tab(
                  icon: Icon(Icons.trending_up, size: 18),
                  text: 'Terlaris',
                ),
                Tab(
                  icon: Icon(Icons.trending_down, size: 18),
                  text: 'Kurang',
                ),
                Tab(
                  icon: Icon(Icons.block, size: 18),
                  text: 'Tidak Laku',
                ),
                Tab(
                  icon: Icon(Icons.warning, size: 18),
                  text: 'Stok Tipis',
                ),
              ],
            ),
            
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.date_range, color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'Periode Analisis:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedPeriod,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: Colors.red),
                        items: _periodDays.keys.map((String period) {
                          return DropdownMenuItem<String>(
                            value: period,
                            child: Text(
                              period,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _changePeriod(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildSummaryStats() {
  //   return Container(
  //     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     child: Row(
  //       children: [
  //         _buildStatCard('Produk Terlaris', _produkTerlaris.length.toString(), Colors.green, Icons.trending_up),
  //         SizedBox(width: 12),
  //         _buildStatCard('Kurang Laris', _produkKurangLaris.length.toString(), Colors.orange, Icons.trending_down),
  //         SizedBox(width: 12),
  //         _buildStatCard('Tidak Laku', _produkTidakLaku.length.toString(), Colors.red, Icons.block),
  //         SizedBox(width: 12),
  //         _buildStatCard('Stok Tipis', _stokMenipis.length.toString(), Colors.blue, Icons.warning),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.red,
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Memuat data analisis...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdukTerlarisTab() {
    if (_produkTerlaris.isEmpty) {
      return _buildEmptyState('Tidak ada data produk terlaris', Icons.trending_up);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationHeader(
            'Rekomendasi: Tambah stok untuk produk-produk ini',
            Colors.green,
            Icons.trending_up,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _produkTerlaris.length,
            itemBuilder: (context, index) {
              final produk = _produkTerlaris[index];
              return _buildProdukCard(
                produk: produk,
                color: Colors.green,
                icon: Icons.trending_up,
                showRecommendation: true,
                recommendationType: 'TAMBAH STOK',
                rank: index + 1,
              );
            },
          ),
          SizedBox(height: 20), // Extra bottom padding
        ],
      ),
    );
  }

  Widget _buildProdukKurangLarisTab() {
    if (_produkKurangLaris.isEmpty) {
      return _buildEmptyState('Tidak ada data produk kurang laris', Icons.trending_down);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationHeader(
            'Rekomendasi: Kurangi pembelian untuk produk-produk ini',
            Colors.orange,
            Icons.trending_down,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
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
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProdukTidakLakuTab() {
    if (_produkTidakLaku.isEmpty) {
      return _buildEmptyState('Semua produk ada yang terjual dalam periode ini', Icons.check_circle);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationHeader(
            'Rekomendasi: Jangan beli lagi atau ganti produk',
            Colors.red,
            Icons.block,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
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
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStokMenipisTab() {
    if (_stokMenipis.isEmpty) {
      return _buildEmptyState('Tidak ada produk dengan stok menipis', Icons.inventory_2);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRecommendationHeader(
            'Rekomendasi: Segera restok produk-produk ini',
            Colors.blue,
            Icons.warning,
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: _stokMenipis.length,
            itemBuilder: (context, index) {
              final produk = _stokMenipis[index];
              return _buildProdukCard(
                produk: produk,
                color: Colors.blue,
                icon: Icons.warning,
                showRecommendation: true,
                recommendationType: 'SEGERA RESTOK',
              );
            },
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProdukCard({
    required Map<String, dynamic> produk,
    required MaterialColor color,
    required IconData icon,
    bool showRecommendation = false,
    String? recommendationType,
    int? rank,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient accent
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color[400]!, color[600]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (rank != null) ...[
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                    ],
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produk['nama_produk'] ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                          Text(
                            produk['kategori'] ?? 'Tidak ada kategori',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (showRecommendation && recommendationType != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          recommendationType,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Stok',
                        '${produk['stok'] ?? 0}',
                        Icons.inventory_2_outlined,
                        (produk['stok'] ?? 0) <= 5 ? Colors.red : Colors.grey[700]!,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Terjual',
                        '${produk['total_terjual'] ?? 0}',
                        Icons.shopping_cart_outlined,
                        color,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Harga',
                        _formatCurrency(produk['harga_ecer'] ?? 0),
                        Icons.attach_money_outlined,
                        Colors.grey[700]!,
                      ),
                    ),
                  ],
                ),
                if (produk['hari_tersisa'] != null && 
                    produk['hari_tersisa'] is num && 
                    produk['hari_tersisa'] < 30 && 
                    produk['hari_tersisa'] != 999) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange[50]!, Colors.yellow[50]!],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.orange[600], size: 16),
                        SizedBox(width: 8),
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
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationHeader(String text, MaterialColor color, IconData icon) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color[50]!, color[100]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color[800],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Coba ubah periode analisis atau refresh data',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return 'Rp 0';
    final value = amount is String ? double.tryParse(amount) ?? 0 : amount.toDouble();
    return 'Rp ${value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}