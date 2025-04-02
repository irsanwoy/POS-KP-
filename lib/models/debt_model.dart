class Debt {
  int? idHutang;
  int? idTransaksi;
  String namaPelanggan;
  double totalHutang;
  String status;
  DateTime? tanggalJatuhTempo;

  Debt({
    this.idHutang,
    this.idTransaksi,
    required this.namaPelanggan,
    required this.totalHutang,
    required this.status,
    this.tanggalJatuhTempo,
  });

  // Convert Debt object to a Map (for database insert)
  Map<String, dynamic> toMap() {
    return {
      'id_hutang': idHutang,
      'id_transaksi': idTransaksi,
      'nama_pelanggan': namaPelanggan,
      'total_hutang': totalHutang,
      'status': status,
      'tanggal_jatuh_tempo': tanggalJatuhTempo?.toIso8601String(),
    };
  }

  // Convert Map to a Debt object
  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      idHutang: map['id_hutang'],
      idTransaksi: map['id_transaksi'],
      namaPelanggan: map['nama_pelanggan'],
      totalHutang: map['total_hutang'],
      status: map['status'],
      tanggalJatuhTempo: map['tanggal_jatuh_tempo'] != null
          ? DateTime.parse(map['tanggal_jatuh_tempo'])
          : null,
    );
  }
}
