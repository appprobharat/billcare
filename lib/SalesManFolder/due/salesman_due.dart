import 'package:flutter/material.dart';

class SalesDuePaymentPage extends StatelessWidget {
  const SalesDuePaymentPage({super.key});

  // 🔹 Dummy Data (replace with API)
  final List<Map<String, dynamic>> dues = const [
    {
      "invoice": "INV101",
      "amount": 3000.0,
      "dueDate": "10 Apr 2026",
      "isOverdue": true
    },
    {
      "invoice": "INV102",
      "amount": 1500.0,
      "dueDate": "28 Apr 2026",
      "isOverdue": false
    },
    {
      "invoice": "INV103",
      "amount": 2200.0,
      "dueDate": "05 Apr 2026",
      "isOverdue": true
    },
  ];

  double get totalOutstanding {
    double sum = 0;
    for (var d in dues) {
      sum += d["amount"];
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Due Payments")),
      body: Column(
        children: [
          // 🔴 TOP SUMMARY CARD
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xffFF6B6B), Color(0xffFF4D4D)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Total Outstanding",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "₹${totalOutstanding.toStringAsFixed(0)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 🔹 LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dues.length,
              itemBuilder: (_, i) {
                final item = dues[i];
                return _dueCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dueCard(Map<String, dynamic> item) {
    final bool isOverdue = item["isOverdue"];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isOverdue
            ? Border.all(color: Colors.red.withOpacity(0.4))
            : null,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          // 🔹 ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isOverdue
                  ? Colors.red.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.receipt_long,
              color: isOverdue ? Colors.red : Colors.orange,
            ),
          ),

          const SizedBox(width: 12),

          // 🔹 DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Invoice: ${item["invoice"]}",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  "Due Date: ${item["dueDate"]}",
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? Colors.red : Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "₹${item["amount"].toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // 🔹 STATUS
          Column(
            children: [
              Text(
                isOverdue ? "OVERDUE" : "DUE",
                style: TextStyle(
                  color: isOverdue ? Colors.red : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          )
        ],
      ),
    );
  }
}