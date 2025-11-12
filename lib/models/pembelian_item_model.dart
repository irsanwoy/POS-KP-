import 'product_model.dart';

class PembelianItem {
  final Product product;
  final int jumlah;
  final double hargaBeli;

  PembelianItem({
    required this.product,
    required this.jumlah,
    required this.hargaBeli,
  });

  double get subtotal => hargaBeli * jumlah;
}