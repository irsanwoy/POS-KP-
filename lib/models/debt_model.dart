class Debt {
  int? idHutang;
  final int? idTransaksi;
  final String namaPelanggan;
  final double totalHutang;
  String status; // 'lunas' atau 'belum lunas'
  final DateTime? tanggalJatuhTempo;

  Debt({
    this.idHutang,
    this.idTransaksi,
    required this.namaPelanggan,
    required this.totalHutang,
    required this.status,
    this.tanggalJatuhTempo,
  });

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
}