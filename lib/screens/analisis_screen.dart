import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AnalisisScreen extends StatefulWidget {
  const AnalisisScreen({super.key});

  @override
  State<AnalisisScreen> createState() => _AnalisisScreenState();
}

class _AnalisisScreenState extends State<AnalisisScreen> {
  List<SalesData> _salesData = [];
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    // Data dummy untuk sementara
    final dummySalesData = [
      SalesData('Indomie Goreng', 120, DateTime(2024, 1, 1)),
      SalesData('Aqua 600ml', 95, DateTime(2024, 2, 15)),
      SalesData('Mie Sedap Goreng', 80, DateTime(2024, 1, 20)),
      SalesData('Teh Botol Sosro', 70, DateTime(2024, 2, 10)),
      SalesData('Kopi Kapal Api', 60, DateTime(2024, 3, 1)),
    ];

    setState(() {
      _salesData = dummySalesData;
    });
  }

  // Fungsi untuk memilih rentang tanggal
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        // Filter data berdasarkan rentang tanggal
        _salesData = _salesData.where((sales) {
          return sales.date.isAfter(picked.start.subtract(const Duration(days: 1))) &&
              sales.date.isBefore(picked.end.add(const Duration(days: 1)));
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analisis Produk Terlaris'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul
            Text(
              'Produk Terlaris',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
            ),
            const SizedBox(height: 16),

            // Grafik bar chart
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: <CartesianSeries<SalesData, String>>[
                  BarSeries<SalesData, String>(
                    dataSource: _salesData,
                    xValueMapper: (SalesData sales, _) => sales.productName,
                    yValueMapper: (SalesData sales, _) => sales.sales,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                    color: Colors.deepPurple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // List produk terlaris
            Expanded(
              child: ListView.builder(
                itemCount: _salesData.length,
                itemBuilder: (context, index) {
                  final sales = _salesData[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 4,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      title: Text(
                        sales.productName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                      ),
                      trailing: Text(
                        '${sales.sales} terjual',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SalesData {
  final String productName;
  final int sales;
  final DateTime date;

  SalesData(this.productName, this.sales, this.date);
}
