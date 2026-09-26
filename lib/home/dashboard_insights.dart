import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardInsights extends StatelessWidget {
  final Map<String, dynamic>? dashboardData;

  const DashboardInsights({super.key, required this.dashboardData});
  double _growth(List<double> values) {
    final valid = values.where((e) => e != 0).toList();

    if (valid.length < 2) return 0;

    final previous = valid[valid.length - 2];
    final current = valid.last;

    if (previous == 0) return 0;

    return ((current - previous) / previous) * 100;
  }

  String _lowestValidMonth(List<String> months, List<double> values) {
    double? min;
    int index = 0;

    for (int i = 0; i < values.length; i++) {
      if (values[i] <= 0) continue;

      if (min == null || values[i] < min) {
        min = values[i];
        index = i;
      }
    }

    return min == null ? "-" : months[index];
  }

  double _sum(List<double> values) {
    return values.fold(0, (a, b) => a + b.abs());
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;

    final valid = values.where((e) => e != 0).toList();

    if (valid.isEmpty) return 0;

    return valid.fold(0.0, (a, b) => a + b.abs()) / valid.length;
  }

  @override
  Widget build(BuildContext context) {
    if (dashboardData == null) {
      return const SizedBox();
    }

    final months = List<String>.from(dashboardData?["months"] ?? []);

    final sales = List<double>.from(
      (dashboardData?["SaleActivity"] ?? []).map((e) => (e as num).toDouble()),
    );

    final purchase = List<double>.from(
      (dashboardData?["PurchaseActivity"] ?? []).map(
        (e) => (e as num).toDouble(),
      ),
    );

    final income = List<double>.from(
      (dashboardData?["Income"] ?? []).map((e) => (e as num).toDouble()),
    );

    final expense = List<double>.from(
      (dashboardData?["Expense"] ?? []).map((e) => (e as num).toDouble()),
    );

    final highestSale = _findHighest(months, sales);

    final highestPurchase = _findHighest(
      months,
      purchase.map((e) => e.abs()).toList(),
    );

    final highestIncome = _findHighest(months, income);

    final highestExpense = _findHighest(months, expense);
    final totalSale = _sum(sales);

    final totalPurchase = _sum(purchase.map((e) => e.abs()).toList());

    final avgSale = _average(sales);

    final avgPurchase = _average(purchase.map((e) => e.abs()).toList());

    final saleGrowth = _growth(sales);

    final purchaseGrowth = _growth(purchase.map((e) => e.abs()).toList());

    final lowestValidSale = _lowestValidMonth(months, sales);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Dashboard Insights",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),
          BusinessStatusCard(
            saleGrowth: saleGrowth,

            purchaseGrowth: purchaseGrowth,
          ),

          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.7,

            children: [
              _InsightCard(
                title: "Highest Sale",
                value: highestSale.value,
                month: highestSale.month,
                icon: Icons.trending_up,
                color: Colors.green,
              ),

              _InsightCard(
                title: "Highest Purchase",
                value: highestPurchase.value,
                month: highestPurchase.month,
                icon: Icons.shopping_cart,
                color: Colors.blue,
              ),

              _InsightCard(
                title: "Highest Income",
                value: highestIncome.value,
                month: highestIncome.month,
                icon: Icons.account_balance_wallet,
                color: Colors.orange,
              ),

              _InsightCard(
                title: "Highest Expense",
                value: highestExpense.value,
                month: highestExpense.month,
                icon: Icons.money_off,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 8),

          BusinessHighlightsCard(
            bestSaleMonth: highestSale.month,

            lowestSaleMonth: lowestValidSale,

            totalSale: totalSale,

            totalPurchase: totalPurchase,

            avgSale: avgSale,

            avgPurchase: avgPurchase,
          ),
        ],
      ),
    );
  }

  _InsightModel _findHighest(List<String> months, List<double> values) {
    if (values.isEmpty) {
      return _InsightModel(month: "-", value: "₹0");
    }

    double max = values.first;
    int index = 0;

    for (int i = 0; i < values.length; i++) {
      if (values[i] > max) {
        max = values[i];
        index = i;
      }
    }

    return _InsightModel(
      month: months[index],
      value: NumberFormat.currency(
        locale: "en_IN",
        symbol: "₹",
        decimalDigits: 0,
      ).format(max),
    );
  }
}

class BusinessStatusCard extends StatelessWidget {
  final double saleGrowth;
  final double purchaseGrowth;

  const BusinessStatusCard({
    super.key,
    required this.saleGrowth,
    required this.purchaseGrowth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xff2563EB), Color(0xff3B82F6)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.white, size: 18),
              SizedBox(width: 6),
              Text(
                "Business Status",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(child: _statusCard("Sales", saleGrowth, Colors.green)),
              const SizedBox(width: 10),
              Expanded(
                child: _statusCard("Purchase", purchaseGrowth, Colors.orange),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusCard(String title, double value, Color accent) {
    final positive = value >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: Icon(
              positive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  "${positive ? '+' : ''}${value.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BusinessHighlightsCard extends StatelessWidget {
  final String bestSaleMonth;
  final String lowestSaleMonth;

  final double totalSale;
  final double totalPurchase;

  final double avgSale;
  final double avgPurchase;

  const BusinessHighlightsCard({
    super.key,

    required this.bestSaleMonth,

    required this.lowestSaleMonth,

    required this.totalSale,

    required this.totalPurchase,

    required this.avgSale,

    required this.avgPurchase,
  });

  String format(double value) {
    return NumberFormat.currency(
      locale: "en_IN",
      symbol: "₹",
      decimalDigits: 0,
    ).format(value);
  }

  Widget row(IconData icon, Color color, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),

      child: Row(
        children: [
          CircleAvatar(
            radius: 18,

            backgroundColor: color.withOpacity(.12),

            child: Icon(icon, color: color, size: 18),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              title,

              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),

            blurRadius: 18,

            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Business Highlights",

            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 16),

          row(
            Icons.emoji_events,
            Colors.orange,
            "Best Sales Month",
            bestSaleMonth,
          ),

          row(
            Icons.trending_down,
            Colors.red,
            "Lowest Sales Month",
            lowestSaleMonth,
          ),

          row(
            Icons.currency_rupee,
            Colors.green,
            "Total Sales",
            format(totalSale),
          ),

          row(
            Icons.shopping_cart,
            Colors.blue,
            "Total Purchase",
            format(totalPurchase),
          ),

          row(
            Icons.show_chart,
            Colors.deepPurple,
            "Average Sale",
            format(avgSale),
          ),

          row(
            Icons.bar_chart,
            Colors.teal,
            "Average Purchase",
            format(avgPurchase),
          ),
        ],
      ),
    );
  }
}

class _InsightModel {
  final String month;
  final String value;

  _InsightModel({required this.month, required this.value});
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String month;
  final IconData icon;
  final Color color;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.month,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: compact ? 40 : 44,
            width: compact ? 40 : 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(colors: [color, color.withOpacity(.75)]),
            ),
            child: Icon(icon, color: Colors.white, size: compact ? 20 : 22),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 2),

                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: compact ? 17 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 5),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    month,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
