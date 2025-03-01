import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';  // Import yang benar


class DatabaseHelper {
  final String _databaseName = 'my_database.db';
  final int _databaseVersion = 1;

  // product table
  final String tabel_barang = 'tabel_barang';
  final String id_barang = 'id_barang';
  final String nama_barang = 'nama_barang';
  final String harga_grosir = 'harga_grosir';
  final String harga_satuan = 'harga_satuan';

  Database? _database;

  // Inisialisasi database
  Future<Database?> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  // Fungsi untuk membuka atau membuat database
  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,  // Menambahkan onCreate untuk membuat tabel saat pertama kali
    );
  }

  // Fungsi untuk membuat tabel saat pertama kali database dibuat
  Future _onCreate(Database db, int version) async {
    await db.execute(
      'CREATE TABLE $tabel_barang ('
      '$id_barang INTEGER PRIMARY KEY, '
      '$nama_barang TEXT NULL, '
      '$harga_grosir INTEGER NULL, '
      '$harga_satuan INTEGER NULL)'
    );
  }
  
}
