import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController categoryController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController qtyController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController itemNameController = TextEditingController();

  DateTime selectedDate = DateTime.now();
  String paymentType = "Cash";

  double qty = 0;
  double rate = 0;

  List<Map<String, dynamic>> items = [];

  void _calculateAmount() {
    setState(() {
      qty = double.tryParse(qtyController.text) ?? 0;
      rate = double.tryParse(rateController.text) ?? 0;
    });
  }

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item['amount']);
  }

  void _saveItem() {
    if (itemNameController.text.isNotEmpty && qty > 0 && rate > 0) {
      final amount = qty * rate;
      setState(() {
        items.add({
          'name': itemNameController.text,
          'qty': qty,
          'rate': rate,
          'amount': amount,
        });

        // Clear input fields
        itemNameController.clear();
        qtyController.clear();
        rateController.clear();
        qty = 0;
        rate = 0;
      });
      _calculateAmount();
    }
  }

  double _calculateTotalAmount() {
    double total = 0;
    for (var item in items) {
      total += item['amount'] ?? 0;
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    qtyController.addListener(_calculateAmount);
    rateController.addListener(_calculateAmount);
  }

  @override
  void dispose() {
    categoryController.dispose();
    descriptionController.dispose();
    qtyController.dispose();
    rateController.dispose();
    itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense"),

        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        actions: const [
          Icon(Icons.search),
          SizedBox(width: 12),
          Icon(Icons.settings),
          SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top section
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Expense No",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                          const Icon(Icons.calendar_today, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: "Expense Category",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  "Billed Items",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Delete Items", style: TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),

            /// Billed item row (inputs)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemNameController,
                    decoration: const InputDecoration(labelText: "Item Name"),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Qty"),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Rate"),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 80,
                  child: Text("₹ ${(qty * rate).toStringAsFixed(2)}"),
                ),
              ],
            ),
            const SizedBox(height: 12),

            /// Items Table
            if (items.isNotEmpty)
              DataTable(
                columnSpacing: 45,
                horizontalMargin: 0,
                columns: const [
                  DataColumn(label: Text("Item Name")),
                  DataColumn(label: Text("Qty")),
                  DataColumn(label: Text("Rate")),
                  DataColumn(label: Text("Amount")),
                ],
                rows: items.map((e) {
                  return DataRow(
                    cells: [
                      DataCell(Text(e['name'])),
                      DataCell(Text(e['qty'].toString())),
                      DataCell(Text(e['rate'].toString())),
                      DataCell(Text(e['amount'].toStringAsFixed(2))),
                    ],
                  );
                }).toList(),
              ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    "₹ ${_calculateTotalAmount().toStringAsFixed(2)}",

                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            /// Payment Section
            Row(
              children: [
                const Text("Payment Type"),
                const SizedBox(width: 12),
                Icon(Icons.money, color: Colors.green.shade700),
                const SizedBox(width: 6),
                DropdownButton<String>(
                  value: paymentType,
                  onChanged: (String? newValue) {
                    setState(() => paymentType = newValue!);
                  },
                  items: ['Cash', 'Card', 'Bank', 'UPI']
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                ),
              ],
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                "+ Add Payment Type",
                style: TextStyle(color: Colors.blue),
              ),
            ),
            const SizedBox(height: 12),

            /// Note
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: "Add Note",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),

      /// Bottom Buttons
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(17),
        child: Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  _saveItem(); // Save and clear
                },
                child: const Text("Save & New"),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  _saveItem(); // Save item on Save
                },

                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
