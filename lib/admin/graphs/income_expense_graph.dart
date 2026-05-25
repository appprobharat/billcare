import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class IncomeExpenseChart extends StatelessWidget {
  final List<double> incomeData;
  final List<double> expenseData;
  final List<String> months;

  const IncomeExpenseChart({
    super.key,
    required this.incomeData,
    required this.expenseData,
    required this.months,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔥 TITLE
            const Text(
              "Income & Expense Graph",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

            AspectRatio(
              aspectRatio: 1.6,

              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,

                  maxY: _getMaxY(),

                  groupsSpace: 12,

                  gridData: FlGridData(
                    show: true,

                    drawVerticalLine: false,

                    horizontalInterval: _getMaxY() / 5,
                  ),

                  borderData: FlBorderData(show: false),

                  /// 🔥 AXIS
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

                        interval: _getMaxY() / 5,

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

                  /// 🔥 BARS
                  barGroups: List.generate(
                    incomeData.length,

                    (i) => BarChartGroupData(
                      x: i,

                      barsSpace: 4,

                      barRods: [
                        /// INCOME
                        BarChartRodData(
                          toY: incomeData[i].abs(),

                          width: 7,

                          color: Colors.green,

                          borderRadius: BorderRadius.circular(4),
                        ),

                        /// EXPENSE
                        BarChartRodData(
                          toY: expenseData[i].abs(),

                          width: 7,

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
        ? incomeData.map((e) => e.abs()).reduce((a, b) => a > b ? a : b)
        : 0;

    double maxExpense = expenseData.isNotEmpty
        ? expenseData.map((e) => e.abs()).reduce((a, b) => a > b ? a : b)
        : 0;

    double maxValue = maxIncome > maxExpense ? maxIncome : maxExpense;

    return maxValue + (maxValue * 0.2);
  }

  String _formatAmount(double value) {
    if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}k";
    }

    return value.toInt().toString();
  }
}
