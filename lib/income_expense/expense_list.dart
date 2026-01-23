import 'dart:convert';

import 'package:billcare/income_expense/add_expense.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExpenseListPage extends StatefulWidget {
  const ExpenseListPage({Key? key}) : super(key: key);

  @override
  State<ExpenseListPage> createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  DateTime? fromDate;
  DateTime? toDate;
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();

  TextEditingController searchCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();

    DateTime today = DateTime.now();
    DateTime lastMonth = DateTime(today.year, today.month - 1, today.day);

    fromDateController.text = DateFormat('dd-MM-yyyy').format(lastMonth);
    toDateController.text = DateFormat('dd-MM-yyyy').format(today);

    fetchExpenseList();
  }

  List<Map<String, dynamic>> expenseData = [];

  bool isLoading = true;
  List<Map<String, dynamic>> allExpenseData = [];

  void filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        expenseData = List.from(allExpenseData);
      } else {
        expenseData = allExpenseData.where((item) {
          return item["item"].toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              item["category"].toString().toLowerCase().contains(
                query.toLowerCase(),
              ) ||
              item["remark"].toString().toLowerCase().contains(
                query.toLowerCase(),
              );
        }).toList();
      }
    });
  }

  String Dateformat(dynamic date) {
    if (date == null || date.toString().trim().isEmpty) return "";

    try {
      DateTime dt = DateTime.parse(date.toString());
      return DateFormat("dd-MM-yy").format(dt);
    } catch (e) {
      return date.toString();
    }
  }

  String _convertToApiDate(String input) {
    try {
      final d = DateFormat("dd-MM-yyyy").parse(input);
      return DateFormat("yyyy-MM-dd").format(d);
    } catch (e) {
      return input;
    }
  }

  Future<void> fetchExpenseList() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("authToken") ?? "";

      final url = Uri.parse("https://gst.billcare.in/api/expense/list");

      final body = {
        "from": _convertToApiDate(fromDateController.text),
        "to": _convertToApiDate(toDateController.text),
      };

      print("📤 Sending Body: $body");

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: body,
      );

      print("📥 Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);

        setState(() {
          allExpenseData = data.map((e) {
            int price = int.tryParse(e["Price"].toString()) ?? 0;
            int qty = int.tryParse(e["Quantity"].toString()) ?? 0;

            return {
              "id": int.tryParse(e["id"].toString()) ?? 0,
              "date": e["Date"] ?? "",
              "category": e["Category"] ?? "",
              "item": e["ItemName"] ?? "",
              "price": price,
              "qty": qty,
              "remark": e["Remark"] ?? "",
            };
          }).toList();
          expenseData = List.from(allExpenseData);
        });
      } else {
        print("❌ Server Error: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ Expense Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Expense List")),

      body: Column(
        children: [
          /// --------------------- DATE FILTER -----------------------
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildDateField("From Date", fromDateController),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 5,
                  child: _buildDateField("To Date", toDateController),
                ),
                const SizedBox(width: 8),
                _buildSearchButton(),
              ],
            ),
          ),

          /// -------------------- SEARCH BAR -------------------------
          customSearchBar(searchCtrl, (value) {
            filterSearch(value);
          }),

          /// -------------------- EXPENSE LIST -----------------------
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : expenseData.isEmpty
                ? const Center(child: Text("No Expense found"))
                : ListView.builder(
                    itemCount: expenseData.length,
                    itemBuilder: (context, index) {
                      final item = expenseData[index];

                      return GestureDetector(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),

                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// ----------- SNO - TYPE - DATE ----------------
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['item'],
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  Text(
                                    Dateformat(item["date"]),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// ----------- PRICE - QTY - EXP - BAL ----------
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _miniVal("${item['category']}", "Category"),
                                  _miniVal("${item['qty']}", "Qty"),
                                  _miniVal("₹${item['price']}", "Price"),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Remarks: ${item['remark']}",

                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AddExpensePage(expenseId: item['id']),
                            ),
                          );

                          if (result == true) {
                            fetchExpenseList();
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GestureDetector(
              onTap: () => _navigateToAddExpensePage(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Expense',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -------------------- SEARCH BAR WIDGET -------------------------
  Widget customSearchBar(
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: "Search...",
          prefixIcon: const Icon(Icons.search, size: 22, color: Colors.grey),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: const Icon(Icons.close, color: Colors.grey, size: 20),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // -------------------- MINI VALUE TEXTS --------------------------
  Widget _miniVal(String value, String label, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  // -------------------- DATE FIELD -------------------------------
  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          controller.text = DateFormat('dd-MM-yyyy').format(picked);
        }
      },
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 20,
        ),
      ),
    );
  }

  // ------------------- SEARCH BUTTON ------------------------------
  Widget _buildSearchButton() {
    return SizedBox(
      width: 48,
      height: 40,
      child: ElevatedButton(
        onPressed: fetchExpenseList,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: const Icon(Icons.search, size: 20),
      ),
    );
  }

  // ------------------- NAVIGATE TO ADD EXPENSE --------------------
  void _navigateToAddExpensePage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpensePage()),
    );

    if (result == true) {
      fetchExpenseList();
    }
  }
}
