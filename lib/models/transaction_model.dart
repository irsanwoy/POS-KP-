// Model untuk tabel transaksi
class Transaction {
  final int? idTransaksi;
  final DateTime tanggal;
  final double totalHarga;
  final String metodeBayar; // 'tunai' atau 'non-tunai'
  final String statusBayar; // 'lunas' atau 'hutang'

  Transaction({
    this.idTransaksi,
    required this.tanggal,
    required this.totalHarga,
    required this.metodeBayar,
    required this.statusBayar,
  });

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      idTransaksi: map['id_transaksi'],
      tanggal: DateTime.parse(map['tanggal']),
      totalHarga: map['total_harga'],
      metodeBayar: map['metode_bayar'],
      statusBayar: map['status_bayar'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_transaksi': idTransaksi,
      'tanggal': tanggal.toIso8601String(),
      'total_harga': totalHarga,
      'metode_bayar': metodeBayar,
      'status_bayar': statusBayar,
    };
  }
}

// Model untuk tabel detail_transaksi
class TransactionDetail {
  final int? idDetail;
  final int idTransaksi;
  final int idProduk;
  final int jumlah;
  final double hargaSatuan;
  final double subtotal;

  TransactionDetail({
    this.idDetail,
    required this.idTransaksi,
    required this.idProduk,
    required this.jumlah,
    required this.hargaSatuan,
    required this.subtotal,
  });

  factory TransactionDetail.fromMap(Map<String, dynamic> map) {
    return TransactionDetail(
      idDetail: map['id_detail'],
      idTransaksi: map['id_transaksi'],
      idProduk: map['id_produk'],
      jumlah: map['jumlah'],
      hargaSatuan: map['harga_satuan'],
      subtotal: map['subtotal'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_detail': idDetail,
      'id_transaksi': idTransaksi,
      'id_produk': idProduk,
      'jumlah': jumlah,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
    };
  }
}