import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DashboardService _dashboardService = DashboardService();

  List<dynamic> _lowStockItems = [];
  List<dynamic> _mostUsedItems = [];
  bool _isLoading = true;
  String _errorMessage = '';
  double _totalLowStock = 0.0;
  double _totalUsage = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final data = await _dashboardService.fetchDashboardData();

      // Calculate the total occurrences for normalization
      double totalLowStock =
          data["top_low_stock_items"]
              ?.map(
                (item) => int.tryParse(item["low_stock_count"].toString()) ?? 0,
              )
              .fold(0, (a, b) => a + b)
              ?.toDouble() ??
          0.0;

      double totalUsage =
          data["most_used_items"]
              ?.map((item) => int.tryParse(item["total_usage"].toString()) ?? 0)
              .fold(0, (a, b) => a + b)
              ?.toDouble() ??
          0.0;

      setState(() {
        _lowStockItems = data["top_low_stock_items"] ?? [];
        _mostUsedItems = data["most_used_items"] ?? [];
        _totalLowStock = totalLowStock;
        _totalUsage = totalUsage;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Widget _buildBarChart(
    List<dynamic> data,
    String title,
    Color color,
    double totalOccurrences,
  ) {
    if (data.isEmpty || totalOccurrences == 0) {
      return const SizedBox(); // Prevent division by zero
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  barGroups:
                      data.asMap().entries.map((entry) {
                        double value =
                            (int.tryParse(
                                      entry.value["low_stock_count"].toString(),
                                    ) ??
                                    int.tryParse(
                                      entry.value["total_usage"].toString(),
                                    ) ??
                                    0)
                                .toDouble();
                        double percentage =
                            (value / totalOccurrences) *
                            100; // Normalize as percentage of total

                        return BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(
                              toY: percentage, // Convert to percentage
                              width: 16,
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        );
                      }).toList(),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            "${value.toInt()}%",
                          ); // Display as percentage
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() < data.length) {
                            return Text(data[value.toInt()]["name"] ?? "");
                          }
                          return const Text("");
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ), // Hide duplicate scale
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ), // Remove top numbers
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard Insights")),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : (_lowStockItems.isNotEmpty || _mostUsedItems.isNotEmpty)
              ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_lowStockItems.isNotEmpty)
                      _buildBarChart(
                        _lowStockItems,
                        "Top Low Stock Items",
                        Colors.red,
                        _totalLowStock,
                      ),
                    if (_mostUsedItems.isNotEmpty)
                      _buildBarChart(
                        _mostUsedItems,
                        "Most Used Items",
                        Colors.blue,
                        _totalUsage,
                      ),
                  ],
                ),
              )
              : const Center(child: Text("No data available.")),
    );
  }
}
