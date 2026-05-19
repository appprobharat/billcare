import 'package:flutter/material.dart';

class AddTxnPage extends StatefulWidget {
  const AddTxnPage({super.key});

  @override
  State<AddTxnPage> createState() => _AddTxnPageState();
}

class _AddTxnPageState extends State<AddTxnPage> {
  final List<Map<String, dynamic>> allTransactions = [
    {'title': 'Sale', 'amount': 1500.0, 'type': 'income'},
    {'title': 'Office Rent', 'amount': 500.0, 'type': 'expense'},
    {'title': 'Electricity Bill', 'amount': 200.0, 'type': 'expense'},
    {'title': 'Client Payment', 'amount': 1000.0, 'type': 'income'},
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = allTransactions
        .where(
          (txn) =>
              txn['title'].toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();

    final totalAmount = allTransactions
        .where((txn) => txn['type'] == 'income')
        .fold(0.0, (sum, txn) => sum + txn['amount']);

    final totalExpense = allTransactions
        .where((txn) => txn['type'] == 'expense')
        .fold(0.0, (sum, txn) => sum + txn['amount']);

    final balance = totalAmount - totalExpense;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7F0),
      appBar: AppBar(
        title: Text("Transactions"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search transactions...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

         
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _summaryCard(
                  "Total",
                  totalAmount,
                  Icons.account_balance_wallet,
                  Colors.blue,
                ),
                const SizedBox(width: 10),
                _summaryCard(
                  "Expenses",
                  totalExpense,
                  Icons.money_off,
                  Colors.redAccent,
                ),
                const SizedBox(width: 10),
                _summaryCard("Balance", balance, Icons.savings, Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 📃 List of transactions
          Expanded(
            child: ListView.builder(
              itemCount: filteredTransactions.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final txn = filteredTransactions[index];
                final isIncome = txn['type'] == 'income';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: isIncome ? Colors.greenAccent : Colors.redAccent,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: isIncome
                          ? Colors.green[100]
                          : Colors.red[100],
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      txn['title'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      isIncome ? "Income" : "Expense",
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Text(
                      "₹ ${txn['amount'].toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "₹ ${value.toStringAsFixed(2)}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
