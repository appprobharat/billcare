import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class IncomeExpenseChart extends StatelessWidget {
  final List<double> incomeData;
  final List<double> expenseData;

  const IncomeExpenseChart({
    super.key,
    required this.incomeData,
    required this.expenseData,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 TITLE
            const Text(
              "Income & Expense Graph",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// 🔥 LEGEND
            Row(
              children: const [
                Icon(Icons.circle, color: Colors.green, size: 10),
                SizedBox(width: 4),
                Text("Income"),

                SizedBox(width: 16),

                Icon(Icons.circle, color: Colors.red, size: 10),
                SizedBox(width: 4),
                Text("Expense"),
              ],
            ),

            const SizedBox(height: 16),

            /// 🔥 BAR GRAPH
            AspectRatio(
              aspectRatio: 1.6,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,

                  maxY: _getMaxY(),

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                  ),

                  borderData: FlBorderData(show: false),

                  /// 🔥 AXIS TITLES
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),

                    /// Y AXIS
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: 500,

                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),

                    /// X AXIS
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
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }

                          return const SizedBox();
                        },
                      ),
                    ),
                  ),

                  /// 🔥 BARS
                  barGroups: List.generate(
                    incomeData.length,
                    (i) => BarChartGroupData(
                      x: i,
                      barsSpace: 4,

                      barRods: [
                        /// INCOME
                        BarChartRodData(
                          toY: incomeData[i],
                          width: 8,
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),

                        /// EXPENSE
                        BarChartRodData(
                          toY: expenseData[i],
                          width: 8,
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getMaxY() {
    double maxIncome = incomeData.isNotEmpty
        ? incomeData.reduce((a, b) => a > b ? a : b)
        : 0;

    double maxExpense = expenseData.isNotEmpty
        ? expenseData.reduce((a, b) => a > b ? a : b)
        : 0;

    double maxValue =
        maxIncome > maxExpense ? maxIncome : maxExpense;

    return ((maxValue / 500).ceil() * 500).toDouble();
  }
}