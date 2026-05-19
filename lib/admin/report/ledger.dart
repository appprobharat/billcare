import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:billcare/helper.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime toDate = DateTime.now();

  String selectedType = "Party";
  String? selectedName;

  final List<String> reportTypes = ["Party", "Employee", "Supplier"];

  final Map<String, List<String>> namesData = {
    "Party": ["Vishal", "Ravi", "Aman"],
    "Employee": ["Rahul", "Sohan"],
    "Supplier": ["ABC Traders", "XYZ Pvt Ltd"],
  };

  final Map<String, dynamic> ledgerData = {
    "Party": {
      "Vishal": {
        "name": "VISHAL RAJ",
        "contact": "8875495565",
        "address": "BIRHAR",
        "ledger": [
          {"date": "01/05/2026", "type": "Sale", "amount": 5000},
          {"date": "02/05/2026", "type": "Payment", "amount": -2000},
        ],
      },
      "Ravi": {
        "name": "RAVI",
        "contact": "9999999999",
        "address": "DELHI",
        "ledger": [
          {"date": "03/05/2026", "type": "Sale", "amount": 3000},
        ],
      },
    },

    "Employee": {
      "Rahul": {
        "name": "RAHUL",
        "contact": "8888888888",
        "address": "NOIDA",
        "ledger": [
          {"date": "01/05/2026", "type": "Salary", "amount": -10000},
        ],
      },
    },
  };
  Map<String, dynamic>? get currentData {
    if (selectedName == null) return null;
    return ledgerData[selectedType]?[selectedName];
  }

  List<Map<String, dynamic>> get filteredLedger {
    if (currentData == null) return [];

    final list = List<Map<String, dynamic>>.from(currentData!["ledger"]);

    return list.where((e) {
      final d = DateFormat("dd/MM/yyyy").parse(e["date"]);
      return d.isAfter(fromDate.subtract(const Duration(days: 1))) &&
          d.isBefore(toDate.add(const Duration(days: 1)));
    }).toList();
  }

  List<Map<String, dynamic>> get ledgerWithBalance {
    double balance = 0;

    return filteredLedger.map((e) {
      balance += e["amount"];
      return {...e, "balance": balance};
    }).toList();
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = namesData[selectedType] ?? [];
    final list = ledgerWithBalance;
    return Scaffold(
      appBar: AppBar(title: const Text("Ledger")),
      body: Column(
        children: [
          /// 🔽 FILTER AREA
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                /// 🔹 DATE ROW
                Row(
                  children: [
                    Expanded(
                      child: _dateBox("From", fromDate, () => pickDate(true)),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _dateBox("To", toDate, () => pickDate(false)),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                /// 🔹 DROPDOWN ROW
                Row(
                  children: [
                    Expanded(
                      child: OverlayDropdown(
                        label: "",
                        value: selectedType,
                        items: reportTypes,
                        onSelect: (v) {
                          setState(() {
                            selectedType = v;
                            selectedName = null; // 👈 reset
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 6),

                    Expanded(
                      child: OverlayDropdown(
                        label: "",
                        value: selectedName ?? "Select Name",
                        items: names,
                        onSelect: (v) {
                          setState(() => selectedName = v);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// 🔽 LEDGER LIST
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 COMPANY
                  /// 🔹 COMPANY (CENTERED)
                  Center(
                    child: Column(
                      children: const [
                        Text(
                          "ABCD ENTERPRISES",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Contact No: 9667586738",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11),
                        ),
                        Text(
                          "Address: HAIR RAM NAGAR, MEERAPUR, FARIDABAD",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  /// 🔹 PARTY DETAILS
                  if (currentData != null) ...[
                    Text(
                      "Name: ${currentData!["name"]}",
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "Contact No: ${currentData!["contact"]}",
                      style: const TextStyle(fontSize: 11),
                    ),
                    Text(
                      "Address: ${currentData!["address"]}",
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],

                  const SizedBox(height: 6),

                  /// 🔹 DATE RANGE
                  Text(
                    "From-To: ${DateFormat("dd MMM yyyy").format(fromDate)} - ${DateFormat("dd MMM yyyy").format(toDate)}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),

                  const SizedBox(height: 8),

                  /// 🔹 TABLE HEADER
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text("Particular")),
                        Expanded(flex: 2, child: Text("Date")),
                        Expanded(flex: 2, child: Text("Rem")),
                        Expanded(
                          flex: 2,
                          child: Text("Dbt", textAlign: TextAlign.right),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text("Cr", textAlign: TextAlign.right),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text("Bal", textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  Expanded(
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final l = list[i];

                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(l["type"]),
                              ), // Particular

                              Expanded(flex: 2, child: Text(l["date"])), // Date

                           

                              Expanded(
                                flex: 2,
                                child: Text(
                                  l["amount"] > 0 ? "${l["amount"]}" : "",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: Colors.green),
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  l["amount"] < 0 ? "${l["amount"].abs()}" : "",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${l["balance"]}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔽 DATE BOX
  Widget _dateBox(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14),
            const SizedBox(width: 6),
            Text(
              "${DateFormat("dd/MM/yyyy").format(date)}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
