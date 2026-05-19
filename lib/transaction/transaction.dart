import 'package:billcare/helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);
  String selectedUser = "User";
  String selectedMonth = "Month";
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String selectedTransaction = "All";
  String selectedParty = "All";

  List<Map<String, dynamic>> dummyTransactions = [
    {
      "party": "Official Expenses",
      "type": "Expense : 1",
      "date": "20/04/2026",
      "total": "2000",
      "balance": "0",
    },
    {
      "party": "Vishal",
      "type": "PI : 1",
      "date": "20/04/2026",
      "total": "10000",
      "balance": "10000",
    },
    {
      "party": "abcd",
      "type": "Sale : 2",
      "date": "02/04/2026",
      "total": "1000",
      "balance": "1000",
    },
    {
      "party": "Ram",
      "type": "PayIn : 1",
      "date": "20/04/2026",
      "total": "500",
      "balance": "500",
    },
    {
      "party": "xyh",
      "type": "Challan : 1",
      "date": "20/04/2026",
      "total": "10000",
      "balance": "10000",
    },
    {
      "party": "azad",
      "type": "SO : 1",
      "date": "21/05/2026",
      "total": "2000",
      "balance": "2000",
    },
    {
      "party": "Raaaj",
      "type": "CN : 1",
      "date": "20/04/2026",
      "total": "20000",
      "balance": "20000",
    },
  ];
  @override
  void initState() {
    super.initState();
    fromDateController.text = DateFormat('dd-MM-yyyy').format(fromDate);
    toDateController.text = DateFormat('dd-MM-yyyy').format(toDate);
  }

  List<Map<String, dynamic>> get filteredTransactions {
    return dummyTransactions.where((t) {
      DateTime tDate;

      try {
        tDate = DateFormat("dd/MM/yyyy").parse(t["date"]);
      } catch (e) {
        return false; // crash avoid
      }

      final from = normalize(fromDate);
      final to = normalize(toDate);
      final current = normalize(tDate);

      if (current.isBefore(from) || current.isAfter(to)) {
        return false;
      }

      if (selectedTransaction != "All" &&
          !t["type"].toString().toLowerCase().contains(
            selectedTransaction.toLowerCase(),
          )) {
        return false;
      }

      if (selectedParty != "All" && t["party"] != selectedParty) {
        return false;
      }

      return true;
    }).toList();
  }

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

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                /// FIRST ROW (date + search)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDateField("From", fromDateController),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _buildDateField("To", toDateController),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 1, child: _buildSearchButton()),
                  ],
                ),

                const SizedBox(height: 10),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: OverlayDropdown(
                            label: "",
                            value: selectedTransaction,
                            items: [
                              "All",
                              "Sales",
                              "PI",
                              "Purchase",
                              "Expense",
                            ],
                            onSelect: (v) {
                              setState(() => selectedTransaction = v);
                            },
                          ),
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          flex: 4,
                          child: OverlayDropdown(
                            label: "",
                            value: selectedMonth,
                            items: ["Today", "Yest", "Month", "Last"],
                            onSelect: (val) {
                              setState(() {
                                selectedMonth = val;

                                final now = DateTime.now();

                                if (val == "Today") {
                                  fromDate = now;
                                  toDate = now;
                                } else if (val == "Yest") {
                                  final y = now.subtract(
                                    const Duration(days: 1),
                                  );
                                  fromDate = y;
                                  toDate = y;
                                } else if (val == "Month") {
                                  fromDate = DateTime(now.year, now.month, 1);
                                  toDate = now;
                                } else if (val == "Last") {
                                  fromDate = DateTime(
                                    now.year,
                                    now.month - 1,
                                    1,
                                  );
                                  toDate = DateTime(now.year, now.month, 0);
                                }
                              });
                            },
                          ),
                        ),

                        const SizedBox(width: 6),

                        Expanded(
                          flex: 3,
                          child: OverlayDropdown(
                            label: "",
                            value: selectedParty,
                            items: ["All", "Raaa", "Office"],
                            onSelect: (v) {
                              setState(() => selectedParty = v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          /// --- LIST OF TRANSACTIONS ---
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTransactions.length,

            itemBuilder: (context, index) {
              final t = filteredTransactions[index];

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
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        DateTime initialDate;

        try {
          initialDate = controller.text.isEmpty
              ? DateTime.now()
              : DateFormat('dd-MM-yyyy').parse(controller.text);
        } catch (e) {
          initialDate = DateTime.now();
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          setState(() {
            controller.text = DateFormat('dd-MM-yyyy').format(picked);

            if (label == "From") {
              fromDate = picked;
            } else {
              toDate = picked;
            }
          });
        }
      },
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: 48,
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          FocusScope.of(context).unfocus(); // keyboard close
          setState(() {}); // refresh
        },

        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          minimumSize: const Size(48, 48),
        ),
        child: const Icon(Icons.search, size: 20),
      ),
    );
  }

  Widget _transactionCard({
    required String party,
    required String type,
    required String date,
    required String total,
    required String balance,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.pink.shade50,
            child: Text(party[0]),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(date, style: TextStyle(color: Colors.grey.shade600)),
                Text(type, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹ $total",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Text(
                "Bal: ₹ $balance",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
