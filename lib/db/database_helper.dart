import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/supplier_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';
import '../models/stock_model.dart';
import 'dart:math';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Table names
  final String tableProduk = 'produk';
  final String tableTransaksi = 'transaksi';
  final String tableDetailTransaksi = 'detail_transaksi';
  final String tableHutang = 'hutang_pelanggan';
  final String tableStokMasuk = 'stok_masuk';
  final String tableSuplier = 'suplier';
  final String tablePembelianSuplier = 'pembelian_suplier';
  final String tableDetailPembelianSuplier = 'detail_pembelian_suplier';

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'toko_kelontong.db'),
      onCreate: (db, version) async {
        // Create Supplier Table
        await db.execute(''' 
          CREATE TABLE $tableSuplier (
            id_suplier INTEGER PRIMARY KEY AUTOINCREMENT,
            nama_suplier TEXT NOT NULL,
            kontak TEXT,
            alamat TEXT
          )
        ''');

        // Create Product Table
        await db.execute(''' 
          CREATE TABLE $tableProduk (
            id_produk INTEGER PRIMARY KEY AUTOINCREMENT,
            nama_produk TEXT NOT NULL,
            kategori TEXT,
            harga_ecer REAL NOT NULL,
            harga_grosir REAL,
            stok INTEGER DEFAULT 0,
            barcode TEXT UNIQUE,
            id_suplier INTEGER,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (id_suplier) REFERENCES $tableSuplier(id_suplier)
          )
        ''');

        // Create Transaction Table
        await db.execute(''' 
          CREATE TABLE $tableTransaksi (
            id_transaksi INTEGER PRIMARY KEY AUTOINCREMENT,
            tanggal TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            total_harga REAL NOT NULL,
            metode_bayar TEXT CHECK(metode_bayar IN ('tunai', 'non-tunai')),
            status_bayar TEXT CHECK(status_bayar IN ('lunas', 'hutang'))
          )
        ''');

        // Create Transaction Detail Table
        await db.execute(''' 
          CREATE TABLE $tableDetailTransaksi (
            id_detail INTEGER PRIMARY KEY AUTOINCREMENT,
            id_transaksi INTEGER NOT NULL,
            id_produk INTEGER NOT NULL,
            jumlah INTEGER NOT NULL,
            harga_satuan REAL NOT NULL,
            subtotal REAL NOT NULL,
            FOREIGN KEY (id_transaksi) REFERENCES $tableTransaksi(id_transaksi),
            FOREIGN KEY (id_produk) REFERENCES $tableProduk(id_produk)
          )
        ''');

        // Create Debt Table
        await db.execute(''' 
          CREATE TABLE $tableHutang (
            id_hutang INTEGER PRIMARY KEY AUTOINCREMENT,
            id_transaksi INTEGER UNIQUE,
            nama_pelanggan TEXT NOT NULL,
            total_hutang REAL NOT NULL,
            status TEXT CHECK(status IN ('lunas', 'belum lunas')),
            tanggal_jatuh_tempo TIMESTAMP,
            FOREIGN KEY (id_transaksi) REFERENCES $tableTransaksi(id_transaksi)
          )
        ''');

        // Create Stock Entry Table
        await db.execute(''' 
          CREATE TABLE $tableStokMasuk (
            id_stok INTEGER PRIMARY KEY AUTOINCREMENT,
            id_produk INTEGER NOT NULL,
            id_suplier INTEGER,
            jumlah INTEGER NOT NULL,
            tanggal TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (id_produk) REFERENCES $tableProduk(id_produk),
            FOREIGN KEY (id_suplier) REFERENCES $tableSuplier(id_suplier)
          )
        ''');

        // === TABEL USERS ===
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT
          )
        ''');

        // === TABEL PEMBELIAN SUPLIER ===
        await db.execute(''' 
          CREATE TABLE $tablePembelianSuplier (
            id_pembelian INTEGER PRIMARY KEY AUTOINCREMENT,
            id_suplier INTEGER NOT NULL,
            tanggal_pembelian TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            total_harga REAL NOT NULL,
            status_bayar TEXT CHECK(status_bayar IN ('belum_bayar', 'lunas', 'terlambat')) DEFAULT 'belum_bayar',
            tanggal_jatuh_tempo TIMESTAMP,
            catatan TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (id_suplier) REFERENCES $tableSuplier(id_suplier)
          )
        ''');

        // === TABEL DETAIL PEMBELIAN SUPLIER ===
        await db.execute(''' 
          CREATE TABLE $tableDetailPembelianSuplier (
            id_detail INTEGER PRIMARY KEY AUTOINCREMENT,
            id_pembelian INTEGER NOT NULL,
            id_produk INTEGER NOT NULL,
            jumlah INTEGER NOT NULL,
            harga_beli REAL NOT NULL,
            subtotal REAL NOT NULL,
            FOREIGN KEY (id_pembelian) REFERENCES $tablePembelianSuplier(id_pembelian),
            FOREIGN KEY (id_produk) REFERENCES $tableProduk(id_produk)
          )
        ''');

        // Insert user default
        await db.insert('users', {
          'username': 'kasir',
          'password': '12345',
          'role': 'kasir',
        });

        await db.insert('users', {
          'username': 'pemilik',
          'password': '12345',
          'role': 'pemilik',
        });
      },
      version: 2, // Naikkan version untuk trigger migration
    );
  }

  // ========== SUPPLIER CRUD ==========

  Future<int> insertSupplier(Supplier supplier) async {
    final db = await database;
    try {
      return await db.insert(tableSuplier, supplier.toMap());
    } catch (e) {
      print("Error inserting supplier: $e");
      return -1;
    }
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableSuplier);
    return maps.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await database;
    return await db.update(
      tableSuplier,
      supplier.toMap(),
      where: 'id_suplier = ?',
      whereArgs: [supplier.idSuplier],
    );
  }

  Future<int> deleteSupplier(int idSuplier) async {
    final db = await database;
    return await db.delete(
      tableSuplier,
      where: 'id_suplier = ?',
      whereArgs: [idSuplier],
    );
  }

  // ========== PEMBELIAN SUPLIER CRUD ==========

  Future<int> insertPembelianSuplier(Map<String, dynamic> pembelian) async {
    final db = await database;
    try {
      return await db.insert(tablePembelianSuplier, pembelian);
    } catch (e) {
      print("Error inserting pembelian suplier: $e");
      return -1;
    }
  }

  Future<int> insertDetailPembelianSuplier(Map<String, dynamic> detail) async {
    final db = await database;
    try {
      return await db.insert(tableDetailPembelianSuplier, detail);
    } catch (e) {
      print("Error inserting detail pembelian: $e");
      return -1;
    }
  }

  Future<List<Map<String, dynamic>>> getAllPembelianSuplier() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        ps.*,
        s.nama_suplier,
        COUNT(dps.id_detail) as total_items
      FROM $tablePembelianSuplier ps
      JOIN $tableSuplier s ON ps.id_suplier = s.id_suplier
      LEFT JOIN $tableDetailPembelianSuplier dps ON ps.id_pembelian = dps.id_pembelian
      GROUP BY ps.id_pembelian
      ORDER BY ps.tanggal_pembelian DESC
    ''');
  }

  Future<List<Map<String, dynamic>>> getPembelianBySuplier(int idSuplier) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        ps.*,
        s.nama_suplier,
        COUNT(dps.id_detail) as total_items
      FROM $tablePembelianSuplier ps
      JOIN $tableSuplier s ON ps.id_suplier = s.id_suplier
      LEFT JOIN $tableDetailPembelianSuplier dps ON ps.id_pembelian = dps.id_pembelian
      WHERE ps.id_suplier = ?
      GROUP BY ps.id_pembelian
      ORDER BY ps.tanggal_pembelian DESC
    ''', [idSuplier]);
  }

  Future<List<Map<String, dynamic>>> getDetailPembelianSuplier(int idPembelian) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        dps.*,
        p.nama_produk,
        p.kategori
      FROM $tableDetailPembelianSuplier dps
      JOIN $tableProduk p ON dps.id_produk = p.id_produk
      WHERE dps.id_pembelian = ?
    ''', [idPembelian]);
  }

  Future<int> updateStatusPembayaran(int idPembelian, String statusBaru) async {
    final db = await database;
    try {
      return await db.update(
        tablePembelianSuplier,
        {'status_bayar': statusBaru},
        where: 'id_pembelian = ?',
        whereArgs: [idPembelian],
      );
    } catch (e) {
      print("Error updating status pembayaran: $e");
      return -1;
    }
  }

  Future<Map<String, dynamic>?> getPerformanceSuplier(int idSuplier, {int bulan = 6}) async {
    final db = await database;
    final tanggalMulai = DateTime.now().subtract(Duration(days: bulan * 30));
    
    final result = await db.rawQuery('''
      SELECT 
        COUNT(ps.id_pembelian) as total_pembelian,
        COALESCE(SUM(ps.total_harga), 0) as total_nilai,
        COALESCE(AVG(ps.total_harga), 0) as rata_rata_pembelian,
        SUM(CASE WHEN ps.status_bayar = 'lunas' THEN 1 ELSE 0 END) as pembelian_lunas,
        SUM(CASE WHEN ps.status_bayar = 'terlambat' THEN 1 ELSE 0 END) as pembelian_terlambat
      FROM $tablePembelianSuplier ps
      WHERE ps.id_suplier = ? AND ps.tanggal_pembelian >= ?
    ''', [idSuplier, tanggalMulai.toIso8601String()]);
    
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getPembayaranTerlambat() async {
    final db = await database;
    final hariIni = DateTime.now();
    
    return await db.rawQuery('''
      SELECT 
        ps.*,
        s.nama_suplier,
        s.kontak
      FROM $tablePembelianSuplier ps
      JOIN $tableSuplier s ON ps.id_suplier = s.id_suplier
      WHERE ps.status_bayar = 'belum_bayar' 
      AND ps.tanggal_jatuh_tempo < ?
      ORDER BY ps.tanggal_jatuh_tempo ASC
    ''', [hariIni.toIso8601String()]);
  }

  Future<void> updateOverduePayments() async {
    final db = await database;
    final hariIni = DateTime.now();
    
    await db.rawUpdate('''
      UPDATE $tablePembelianSuplier 
      SET status_bayar = 'terlambat'
      WHERE status_bayar = 'belum_bayar' 
      AND tanggal_jatuh_tempo < ?
    ''', [hariIni.toIso8601String()]);
  }

  // ========== PRODUCT CRUD ==========

  Future<int> insertProduct(Product product) async {
    final db = await database;
    try {
      return await db.insert(tableProduk, product.toMap());
    } catch (e) {
      print("Error inserting product: $e");
      return -1;
    }
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableProduk);
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;

    final cleanedBarcode = barcode.trim().replaceAll('\n', '').replaceAll('\r', '');
    print('🔍 Mencari produk dengan barcode: "$cleanedBarcode"');

    final List<Map<String, dynamic>> maps = await db.query(
      tableProduk,
      where: 'LOWER(barcode) = LOWER(?)',
      whereArgs: [cleanedBarcode],
      limit: 1,
    );

    if (maps.isEmpty) {
      print('❌ Produk tidak ditemukan di database');
      return null;
    }

    print('✅ Produk ditemukan: ${maps.first}');
    return Product.fromMap(maps.first);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      tableProduk,
      product.toMap(),
      where: 'id_produk = ?',
      whereArgs: [product.idProduk],
    );
  }

  Future<int> deleteProduct(int productId) async {
    final db = await database;
    return await db.delete(
      tableProduk,
      where: 'id_produk = ?',
      whereArgs: [productId],
    );
  }

  Future<int> updateProductStock(int productId, int quantitySold) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE $tableProduk SET stok = stok - ? WHERE id_produk = ?',
      [quantitySold, productId],
    );
  }

  // Method untuk menambah stok saat pembelian dari supplier
Future<int> updateProductStockMasuk(int productId, int quantityReceived) async {
  final db = await database;
  try {
    print('📈 Menambah stok produk ID: $productId, jumlah: $quantityReceived');
    final result = await db.rawUpdate(
      'UPDATE $tableProduk SET stok = stok + ? WHERE id_produk = ?',
      [quantityReceived, productId],
    );
    print('✅ Stok berhasil ditambah: $result rows affected');
    return result;
  } catch (e) {
    print('❌ Error update stok masuk: $e');
    return -1;
  }
}

// Method untuk save pembelian dengan transaction (lebih aman)
Future<int> savePembelianWithStockUpdate(
  Map<String, dynamic> pembelianData,
  List<Map<String, dynamic>> detailItems,
) async {
  final db = await database;
  
  try {
    return await db.transaction((txn) async {
      print('🔄 Starting transaction untuk pembelian supplier...');
      
      // 1. Insert data pembelian
      final idPembelian = await txn.insert(tablePembelianSuplier, pembelianData);
      print('✅ Pembelian inserted dengan ID: $idPembelian');
      
      // 2. Insert detail dan update stok untuk setiap item
      for (final detail in detailItems) {
        // Insert detail pembelian
        await txn.insert(tableDetailPembelianSuplier, {
          'id_pembelian': idPembelian,
          'id_produk': detail['id_produk'],
          'jumlah': detail['jumlah'],
          'harga_beli': detail['harga_beli'],
          'subtotal': detail['subtotal'],
        });
        print('✅ Detail item inserted: Produk ${detail['id_produk']}, qty: ${detail['jumlah']}');
        
        // Update stok produk (TAMBAH stok)
        await txn.rawUpdate(
          'UPDATE $tableProduk SET stok = stok + ? WHERE id_produk = ?',
          [detail['jumlah'], detail['id_produk']],
        );
        print('📈 Stok produk ${detail['id_produk']} ditambah: ${detail['jumlah']}');
        
        // Insert ke tabel stok_masuk untuk tracking
        await txn.insert(tableStokMasuk, {
          'id_produk': detail['id_produk'],
          'id_suplier': pembelianData['id_suplier'],
          'jumlah': detail['jumlah'],
          'tanggal': pembelianData['tanggal_pembelian'],
        });
        print('📋 Stok masuk tracking inserted');
      }
      
      print('🎉 Transaction completed successfully');
      return idPembelian;
    });
  } catch (e) {
    print('💥 Transaction failed: $e');
    rethrow;
  }
}


  // ========== TRANSACTION CRUD ==========

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    try {
      return await db.insert(tableTransaksi, transaction.toMap());
    } catch (e) {
      print("Error inserting transaction: $e");
      return -1;
    }
  }

  Future<int> insertTransactionDetail(TransactionDetail detail) async {
    final db = await database;
    try {
      return await db.insert(tableDetailTransaksi, detail.toMap());
    } catch (e) {
      print("Error inserting transaction detail: $e");
      return -1;
    }
  }

  Future<List<Transaction>> getTransactionsByDate(DateTime date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(''' 
      SELECT * FROM $tableTransaksi 
      WHERE DATE(tanggal) = DATE(?)
    ''', [date.toIso8601String()]);
    return maps.map((map) => Transaction.fromMap(map)).toList();
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    return await db.update(
      tableTransaksi,
      transaction.toMap(),
      where: 'id_transaksi = ?',
      whereArgs: [transaction.idTransaksi],
    );
  }

  Future<int> deleteTransaction(int transactionId) async {
    final db = await database;
    return await db.transaction((txn) async {
      await txn.delete(
        tableHutang,
        where: 'id_transaksi = ?',
        whereArgs: [transactionId],
      );
      await txn.delete(
        tableDetailTransaksi,
        where: 'id_transaksi = ?',
        whereArgs: [transactionId],
      );
      return await txn.delete(
        tableTransaksi,
        where: 'id_transaksi = ?',
        whereArgs: [transactionId],
      );
    });
  }

  // ========== DEBT CRUD ==========

  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    try {
      final result = await db.insert(tableHutang, debt.toMap());
      return result;
    } catch (e) {
      print("Error inserting debt: $e");
      return -1;
    }
  }

  Future<List<Debt>> getUnpaidDebts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableHutang,
      where: 'status = ?',
      whereArgs: ['belum lunas'],
    );
    return maps.map((map) => Debt.fromMap(map)).toList();
  }

  Future<int> updateDebtStatus(int debtId, String newStatus) async {
    final db = await database;
    try {
      final result = await db.update(
        tableHutang,
        {'status': newStatus},
        where: 'id_hutang = ?',
        whereArgs: [debtId],
      );
      return result;
    } catch (e) {
      print("Error updating debt status: $e");
      return -1;
    }
  }

  Future<int> deleteDebt(int debtId) async {
    final db = await database;
    try {
      final result = await db.delete(
        tableHutang,
        where: 'id_hutang = ?',
        whereArgs: [debtId],
      );
      return result;
    } catch (e) {
      print("Error deleting debt: $e");
      return -1;
    }
  }

  // ========== STOCK ENTRY CRUD ==========

  Future<int> insertStockEntry(StockEntry stockEntry) async {
    final db = await database;
    return await db.transaction((txn) async {
      final id = await txn.insert(tableStokMasuk, stockEntry.toMap());
      await updateProductStock(stockEntry.idProduk, stockEntry.jumlah);
      return id;
    });
  }

  Future<List<StockEntry>> getAllStockEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableStokMasuk);
    return maps.map((map) => StockEntry.fromMap(map)).toList();
  }

  Future<int> deleteStockEntry(int stockEntryId) async {
    final db = await database;
    return await db.delete(
      tableStokMasuk,
      where: 'id_stok = ?',
      whereArgs: [stockEntryId],
    );
  }

  // ========== REPORTS ==========

  Future<List<Map<String, dynamic>>> getDailyReport(DateTime date) async {
    final db = await database;
    return await db.rawQuery(''' 
      SELECT t.id_transaksi, t.tanggal, t.total_harga, 
             COUNT(dt.id_detail) as jumlah_item
      FROM $tableTransaksi t
      JOIN $tableDetailTransaksi dt ON t.id_transaksi = dt.id_transaksi
      WHERE DATE(t.tanggal) = DATE(?)
      GROUP BY t.id_transaksi
    ''', [date.toIso8601String()]);
  }

  Future<double> getTotalSales(DateTime startDate, DateTime endDate) async {
    final db = await database;
    final result = await db.rawQuery(''' 
      SELECT SUM(total_harga) as total_sales
      FROM $tableTransaksi
      WHERE tanggal BETWEEN ? AND ?
    ''', [startDate.toIso8601String(), endDate.toIso8601String()]);
    return result.first['total_sales'] as double? ?? 0.0;
  }

  // function buat data dummy

// Tambahkan method ini di class DatabaseHelper
Future<void> generateBulkSampleData() async {
  final db = await database;
  
  try {
    // 1. Insert 10 suppliers
    List<String> supplierNames = ['Alpha', 'Beta', 'Gamma', 'Delta', 'Prima', 'Jaya', 'Maju', 'Sejahtera', 'Makmur', 'Berkah'];
    for (int i = 1; i <= 10; i++) {
      await db.insert('suplier', {
        'nama_suplier': 'Supplier ${supplierNames[i-1]}',
        'kontak': '0812345678${i.toString().padLeft(2, '0')}',
        'alamat': 'Jl. Raya No. ${10 + i}'
      });
    }

    // 2. Insert 50 products
    List<String> categories = ['Makanan', 'Minuman', 'Sembako', 'Snack', 'Perlengkapan'];
    List<String> productNames = [
      'Indomie Goreng', 'Mie Sedaap', 'Aqua 600ml', 'Teh Botol', 'Beras Premium',
      'Gula Pasir', 'Minyak Goreng', 'Chitato', 'Tango', 'Oreo',
      'Susu Bear Brand', 'Kopi ABC', 'Teh Celup', 'Garam', 'Tepung Terigu',
      'Sabun Mandi', 'Pasta Gigi', 'Shampoo', 'Deterjen', 'Tissue'
    ];
    
    for (int i = 1; i <= 50; i++) {
      double hargaEcer = (2000 + (i * 500)).toDouble();
      await db.insert('produk', {
        'nama_produk': '${productNames[i % productNames.length]} ${i}',
        'kategori': categories[i % categories.length],
        'harga_ecer': hargaEcer,
        'harga_grosir': (hargaEcer * 0.85).round().toDouble(),
        'stok': Random().nextInt(100) + 10,
        'barcode': '${1000000000000 + i}',
        'id_suplier': (i % 10) + 1
      });
    }

    // 3. Generate transactions (3 bulan terakhir)
    for (int i = 1; i <= 200; i++) {
      DateTime transDate = DateTime.now().subtract(Duration(days: Random().nextInt(90)));
      double totalHarga = (Random().nextInt(50) + 5) * 1000.0;
      
      await db.insert('transaksi', {
        'tanggal': transDate.toIso8601String(),
        'total_harga': totalHarga,
        'metode_bayar': Random().nextBool() ? 'tunai' : 'non-tunai',
        'status_bayar': 'lunas'
      });
      
      // Detail transaksi (1-3 item per transaksi)
      int itemCount = Random().nextInt(3) + 1;
      for (int j = 0; j < itemCount; j++) {
        int productId = Random().nextInt(50) + 1;
        int qty = Random().nextInt(5) + 1;
        double harga = (Random().nextInt(10) + 1) * 1000.0;
        
        await db.insert('detail_transaksi', {
          'id_transaksi': i,
          'id_produk': productId,
          'jumlah': qty,
          'harga_satuan': harga,
          'subtotal': harga * qty
        });
      }
    }

    // 4. Generate hutang pelanggan
    for (int i = 1; i <= 15; i++) {
      await db.insert('hutang_pelanggan', {
        'nama_pelanggan': 'Pelanggan ${i}',
        'total_hutang': (Random().nextInt(20) + 5) * 1000.0,
        'status': Random().nextBool() ? 'lunas' : 'belum lunas',
        'tanggal_jatuh_tempo': DateTime.now().add(Duration(days: Random().nextInt(30))).toIso8601String()
      });
    }

    print('✅ Bulk sample data generated successfully!');
  } catch (e) {
    print('❌ Error generating bulk data: $e');
  }
}
}