class Supplier {
  final int? idSuplier; // AUTOINCREMENT
  final String namaSuplier;
  final String? kontak;
  final String? alamat;

  Supplier({
    this.idSuplier,
    required this.namaSuplier,
    this.kontak,
    this.alamat,
  });

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      idSuplier: map['id_suplier'],
      namaSuplier: map['nama_suplier'],
      kontak: map['kontak'],
      alamat: map['alamat'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_suplier': idSuplier,
      'nama_suplier': namaSuplier,
      'kontak': kontak,
      'alamat': alamat,
    };
  }
}