class StockEntry {
  final int? idStok;
  final int idProduk;
  final int? idSuplier;
  final int jumlah;
  final DateTime tanggal;

  StockEntry({
    this.idStok,
    required this.idProduk,
    this.idSuplier,
    required this.jumlah,
    required this.tanggal,
  });

  factory StockEntry.fromMap(Map<String, dynamic> map) {
    return StockEntry(
      idStok: map['id_stok'],
      idProduk: map['id_produk'],
      idSuplier: map['id_suplier'],
      jumlah: map['jumlah'],
      tanggal: DateTime.parse(map['tanggal']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_stok': idStok,
      'id_produk': idProduk,
      'id_suplier': idSuplier,
      'jumlah': jumlah,
      'tanggal': tanggal.toIso8601String(),
    };
  }
}