import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/supplier_model.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../models/debt_model.dart';
import '../models/stock_model.dart';

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
      },
      version: 1,
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
    final List<Map<String, dynamic>> maps = await db.query(
      tableProduk,
      where: 'barcode = ?',
      whereArgs: [barcode],
      limit: 1,
    );
    if (maps.isEmpty) return null;
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

  Future<int> updateProductStock(int productId, int quantityChange) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE $tableProduk SET stok = stok + ? WHERE id_produk = ?',
      [quantityChange, productId],
    );
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
      // Delete related debts
      await txn.delete(
        tableHutang,
        where: 'id_transaksi = ?',
        whereArgs: [transactionId],
      );
      // Delete transaction details
      await txn.delete(
        tableDetailTransaksi,
        where: 'id_transaksi = ?',
        whereArgs: [transactionId],
      );
      // Delete the main transaction
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
      // Insert debt record into the database
      final result = await db.insert(tableHutang, debt.toMap());
      return result; // Return the id of the inserted record
    } catch (e) {
      print("Error inserting debt: $e");
      return -1; // Return -1 if error occurs
    }
  }

  Future<List<Debt>> getUnpaidDebts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableHutang,
      where: 'status = ?',
      whereArgs: ['belum lunas'],
    );

    if (maps.isEmpty) {
      print("No unpaid debts found");
    }

    // Map the query result to a list of Debt objects
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
      return result; // Return the number of rows affected
    } catch (e) {
      print("Error updating debt status: $e");
      return -1; // Return -1 if error occurs
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
      return result; // Return the number of rows affected
    } catch (e) {
      print("Error deleting debt: $e");
      return -1; // Return -1 if error occurs
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
}
