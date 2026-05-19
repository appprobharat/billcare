import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaleReportPage extends StatefulWidget {
  const SaleReportPage({super.key});

  @override
  State<SaleReportPage> createState() => _SaleReportPageState();
}

class _SaleReportPageState extends State<SaleReportPage> {
  String selectedFilter = 'Today';
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();
  List<Map<String, dynamic>> savedData = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  String formatDate(DateTime date) {
    final yearLastTwoDigits = (date.year % 100).toString().padLeft(2, '0');
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '$yearLastTwoDigits';
  }

  Future<void> _loadSavedData() async {
    print("📦 Fetching SharedPreferences instance...");
    final prefs = await SharedPreferences.getInstance();

    print("🔑 Checking if 'salesData' exists...");
    final List<String>? jsonList = prefs.getStringList('salesData');

    print("📃 Raw list from prefs: $jsonList");

    if (jsonList != null) {
      setState(() {
        savedData = jsonList.map((e) {
          print("📤 Decoding entry: $e");
          return json.decode(e) as Map<String, dynamic>;
        }).toList();
      });
      print("✅ Decoded savedData: $savedData");
    } else {
      setState(() {
        savedData = [];
      });
      print("⚠️ No saved data found in prefs.");
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate,
      firstDate: startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => endDate = picked);
    }
  }

  void _updateFromDropdown(String? val) {
    if (val == null) return;
    final now = DateTime.now();
    setState(() {
      selectedFilter = val;
      if (val == 'Today') {
        startDate = now;
        endDate = now;
      } else if (val == 'This Month') {
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
      } else if (val == 'Last Month') {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        startDate = lastMonth;
        endDate = DateTime(lastMonth.year, lastMonth.month + 1, 0);
      }
    });
  }

  double _calculateTotalSale() {
    double total = 0.0;
    for (var transaction in savedData) {
      double amount = double.tryParse(transaction['totalAmount'] ?? '0') ?? 0;
      total += amount;
    }
    return total;
  }

  double _calculateBalanceDue() {
    double totalBalance = 0.0;
    for (var transaction in savedData) {
      double total = double.tryParse(transaction['totalAmount'] ?? '0') ?? 0;
      double received = double.tryParse(transaction['received'] ?? '0') ?? 0;
      totalBalance += (total - received);
    }
    return totalBalance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9F3FE),
      appBar: AppBar(
        title: const Text('Sale Report'),
        elevation: 1,
        leading: const BackButton(),
        actions: [
          IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: () {}),
          IconButton(icon: const Icon(Icons.grid_on), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // 🔹 Filter Section
            Row(
              children: [
                // Dropdown
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: selectedFilter,
                    items: ['Today', 'This Month', 'Last Month'].map((value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontSize: 11),
                        ),
                      );
                    }).toList(),
                    onChanged: _updateFromDropdown,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Start Date Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _pickStartDate,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      formatDate(startDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),

                // TO Text
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    "TO",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),

                // End Date Button
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    onPressed: _pickEndDate,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.black),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      formatDate(endDate),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),

            //row one more
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Filter Applied :",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.filter_alt_outlined),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.black),
                    // padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  label: const Text('Filters'),

                  onPressed: () {},
                ),
              ],
            ),
            SizedBox(height: 10),
            // 🔹 Filter Chips
            Row(
              children: [
                Chip(
                  label: Text(
                    'Txns Type - Sale & Cr. Note',
                    style: TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
                SizedBox(width: 8),
                Chip(
                  label: Text(
                    'Party - All Party',
                    style: TextStyle(fontSize: 12),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.symmetric(horizontal: 8),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 🔹 Summary Cards
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryCard("No of Txns", "${savedData.length}"),
                _summaryCard(
                  "Total Sale",
                  "₹ ${_calculateTotalSale().toStringAsFixed(2)}",
                  textColor: Colors.green,
                ),
                _summaryCard(
                  "Balance Due",
                  "₹ ${_calculateBalanceDue().toStringAsFixed(2)}",
                  textColor: Colors.red,
                ),
              ],
            ),

            const SizedBox(height: 16),
            SingleChildScrollView(child: _buildTransactionCards()),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value, {
    Color textColor = Colors.black,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCards() {
    if (savedData.isEmpty) {
      return const Center(child: Text("No transactions found."));
    }

    return Column(
      children: savedData.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> transaction = entry.value;

        final partyName = transaction['partyName'] ?? 'N/A';
        final date = transaction['selectedDate'] ?? '';
        final totalAmount = transaction['totalAmount'] ?? '0';
        final receivedAmount = transaction['received'] ?? '0';

        double total = double.tryParse(totalAmount) ?? 0;
        double received = double.tryParse(receivedAmount) ?? 0;
        double balance = total - received;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      partyName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Sale ${index + 1}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(children: [const Spacer(), Text(date)]),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total\n₹ $totalAmount",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      "Balance\n₹ ${balance.toStringAsFixed(2)}",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
