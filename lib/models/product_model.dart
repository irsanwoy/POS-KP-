class Product {
  final int? idProduk; // AUTOINCREMENT
  final String namaProduk;
  final double hargaEcer;
  final double? hargaGrosir;
  final int stok;
  final String? barcode;
  final int? idSuplier; // Foreign Key

  Product({
    this.idProduk,
    required this.namaProduk,
    required this.hargaEcer,
    this.hargaGrosir,
    this.stok = 0,
    this.barcode,
    this.idSuplier,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      idProduk: map['id_produk'],
      namaProduk: map['nama_produk'],
      hargaEcer: map['harga_ecer'],
      hargaGrosir: map['harga_grosir'],
      stok: map['stok'],
      barcode: map['barcode'],
      idSuplier: map['id_suplier'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_produk': idProduk,
      'nama_produk': namaProduk,
      'harga_ecer': hargaEcer,
      'harga_grosir': hargaGrosir,
      'stok': stok,
      'barcode': barcode,
      'id_suplier': idSuplier,
    };
  }
}