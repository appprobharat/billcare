import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  String selectedUser = "User";
  String selectedMonth = "This month";
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String selectedTransaction = "All Transactions";
  String selectedParty = "All parties";

  List<Map<String, dynamic>> dummyTransactions = [
    {
      "party": "Official Expenses",
      "type": "Expense : 1",
      "date": "20/11/2025",
      "total": "2000",
      "balance": "0",
    },
    {
      "party": "Vishal",
      "type": "PI : 1",
      "date": "25/11/2025",
      "total": "10000",
      "balance": "10000",
    },
    {
      "party": "abcd",
      "type": "Sale : 2",
      "date": "25/11/2025",
      "total": "1000",
      "balance": "1000",
    },
    {
      "party": "Ram",
      "type": "PayIn : 1",
      "date": "25/11/2025",
      "total": "500",
      "balance": "500",
    },
    {
      "party": "xyh",
      "type": "Challan : 1",
      "date": "25/11/2025",
      "total": "10000",
      "balance": "10000",
    },
    {
      "party": "azad",
      "type": "SO : 1",
      "date": "25/11/2025",
      "total": "2000",
      "balance": "2000",
    },
    {
      "party": "Raaaj",
      "type": "CN : 1",
      "date": "25/11/2025",
      "total": "20000",
      "balance": "20000",
    },
  ];

  Future<void> pickFromDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => fromDate = picked);
    }
  }

  Future<void> pickToDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => toDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("All Transactions"),

        actions: const [
          Icon(Icons.picture_as_pdf, color: Colors.red),
          SizedBox(width: 12),
          Icon(Icons.table_view, color: Colors.green),
          SizedBox(width: 12),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),

            /// MONTH DROPDOWN + DATE PICKERS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _dropdownTile("This month", [
                    "Today",
                    "Yesterday",
                    "This month",
                    "Last month",
                  ], (val) => setState(() => selectedMonth = val!)),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(Icons.calendar_month),
                      const SizedBox(width: 8),

                      Expanded(
                        child: InkWell(
                          onTap: pickFromDate,
                          child: _dateBox(
                            DateFormat("dd/MM/yyyy").format(fromDate),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text("To"),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: pickToDate,
                          child: _dateBox(
                            DateFormat("dd/MM/yyyy").format(toDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _dropdownTile(
                      selectedTransaction,
                      [
                        "All Transactions",
                        "Sales",
                        "PI",
                        "Purchase",
                        "Expense",
                      ],
                      (v) => setState(() => selectedTransaction = v!),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _dropdownTile(selectedParty, [
                      "All parties",
                      "Raaa",
                      "Official Expenses",
                    ], (v) => setState(() => selectedParty = v!)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// --- LIST OF TRANSACTIONS ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dummyTransactions.length,
              itemBuilder: (context, index) {
                final t = dummyTransactions[index];

                return _transactionCard(
                  party: t["party"],
                  type: t["type"],
                  date: t["date"],
                  total: t["total"],
                  balance: t["balance"],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- UI WIDGETS ----------------

  Widget _dropdownTile(
    String selectedValue,
    List<String> items,
    Function(String?) onChange,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButton<String>(
        value: selectedValue,
        isExpanded: true,
        underline: const SizedBox(),
        style: const TextStyle(
          fontSize: 13, // ← dropdown closed state font size
          color: Colors.black,
        ),
        items: items.map((e) {
          return DropdownMenuItem(
            value: e,
            child: Text(
              e,
              style: const TextStyle(fontSize: 13), // ← dropdown list font size
            ),
          );
        }).toList(),
        onChanged: onChange,
      ),
    );
  }

  Widget _dateBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(text),
    );
  }

  Widget _transactionCard({
    required String party,
    required String type,
    required String date,
    required String total,
    required String balance,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            /// LEFT SIDE: PARTY + DATE
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(date, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),

            /// CENTER: TYPE
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(type, style: const TextStyle(fontSize: 15))],
            ),

            /// RIGHT SIDE: TOTAL + BALANCE
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Total : ₹ $total",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  "Balance: ₹ $balance",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
