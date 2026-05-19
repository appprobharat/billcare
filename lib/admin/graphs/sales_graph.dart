import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class SalesPurchaseChart extends StatelessWidget {
  final List<double> salesData;
  final List<double> purchaseData;

  const SalesPurchaseChart({
    super.key,
    required this.salesData,
    required this.purchaseData,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Column(
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

                gridData: FlGridData(show: true, drawVerticalLine: false),

                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 500,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              months[value.toInt()],
                              style: const TextStyle(fontSize: 11),
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
                      /// SALES BAR
                      BarChartRodData(
                        toY: salesData[i],
                        color: Colors.green,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),

                      /// PURCHASE BAR
                      BarChartRodData(
                        toY: purchaseData[i],
                        color: Colors.red,
                        width: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _getMaxY() {
    double maxSales = salesData.isNotEmpty
        ? salesData.reduce((a, b) => a > b ? a : b)
        : 0;

    double maxPurchase = purchaseData.isNotEmpty
        ? purchaseData.reduce((a, b) => a > b ? a : b)
        : 0;

    double maxValue = maxSales > maxPurchase ? maxSales : maxPurchase;

    return ((maxValue / 1000).ceil() * 1000).toDouble();
  }
}
