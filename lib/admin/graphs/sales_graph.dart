import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesPurchaseChart extends StatelessWidget {
  final List<double> salesData;
  final List<double> purchaseData;
  final List<String> months;

  const SalesPurchaseChart({
    super.key,
    required this.salesData,
    required this.purchaseData,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              "Sales & Purchase Graph",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),

          /// LEGEND
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 10),
            child: Row(
              children: const [
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 4),
                Text("Sales"),
                SizedBox(width: 16),
                Icon(Icons.circle, color: Colors.red, size: 10),
                SizedBox(width: 4),
                Text("Purchase"),
              ],
            ),
          ),

          /// BAR CHART
          AspectRatio(
            aspectRatio: 1.6,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,

                  maxY: _getMaxY(),

                  groupsSpace: 12,

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getInterval(),
                  ),

                  borderData: FlBorderData(show: false),

                  titlesData: FlTitlesData(
                    /// TOP
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    /// RIGHT
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    /// LEFT
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,

                        reservedSize: 42,

                        interval: _getInterval(),

                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),

                            child: Text(
                              _formatAmount(value),

                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    /// BOTTOM
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,

                        reservedSize: 32,

                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();

                          if (index >= 0 && index < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),

                              child: Text(
                                months[index],

                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }

                          return const SizedBox();
                        },
                      ),
                    ),
                  ),

                  barGroups: List.generate(
                    salesData.length,

                    (i) => BarChartGroupData(
                      x: i,

                      barsSpace: 4,

                      barRods: [
                        /// SALES
                        BarChartRodData(
                          toY: salesData[i].isFinite ? salesData[i].abs() : 0,
                          color: Colors.green,
                          width: 7,
                        ),

                        /// PURCHASE
                        BarChartRodData(
                          toY: purchaseData[i].isFinite
                              ? purchaseData[i].abs()
                              : 0,
                          color: Colors.red,
                          width: 7,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double value) {
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}k";
    }

    return value.toInt().toString();
  }

  double _getMaxY() {
    double maxSales = salesData.isNotEmpty
        ? salesData.reduce((a, b) => a > b ? a : b)
        : 0;

    double maxPurchase = purchaseData.isNotEmpty
        ? purchaseData.reduce((a, b) => a > b ? a : b)
        : 0;

    double maxValue = maxSales > maxPurchase ? maxSales : maxPurchase;

    // SAFE DEFAULT
    if (maxValue <= 0) {
      return 5;
    }

    return maxValue + (maxValue * 0.2);
  }

  double _getInterval() {
    double interval = _getMaxY() / 5;

    // NEVER RETURN 0
    if (interval <= 0 || interval.isNaN || interval.isInfinite) {
      return 1;
    }

    return interval;
  }
}
