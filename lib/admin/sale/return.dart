import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReturnPage extends StatefulWidget {
  const ReturnPage({super.key});

  @override
  State<ReturnPage> createState() => _ReturnPageState();
}

class _ReturnPageState extends State<ReturnPage> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<Map<String, dynamic>> returnOrders = [];
  int invoiceCounter = 1;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final String? ordersJson = prefs.getString('returnOrders');
    if (ordersJson != null) {
      setState(() {
        returnOrders = List<Map<String, dynamic>>.from(jsonDecode(ordersJson));
        invoiceCounter = returnOrders.length + 1;
      });
    }
  }

  Future<void> _saveOrders() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('returnOrders', jsonEncode(returnOrders));
  }

  void _addOrder() {
    if (_customerController.text.isEmpty ||
        _phoneController.text.length != 10 ||
        _itemNameController.text.isEmpty ||
        _qtyController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields correctly")),
      );
      return;
    }

    final int qty = int.tryParse(_qtyController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final double total = qty * price;

    setState(() {
      returnOrders.add({
        "invoice": invoiceCounter,
        "date": DateTime.now().toString().split(" ")[0], // yyyy-mm-dd
        "customer": _customerController.text,
        "phone": _phoneController.text,
        "item": _itemNameController.text,
        "qty": qty,
        "price": price,
        "total": total,
      });
      invoiceCounter++;
    });

    _saveOrders();

    _customerController.clear();
    _phoneController.clear();
    _itemNameController.clear();
    _qtyController.clear();
    _priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Return Page")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📌 Invoice Number (ReadOnly)
            TextField(
              controller: TextEditingController(
                text: invoiceCounter.toString(),
              ),
              decoration: const InputDecoration(
                labelText: "Invoice No",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 10),

            // 📌 Date (ReadOnly - default today)
            TextField(
              controller: TextEditingController(
                text:
                    "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}",
              ),
              decoration: const InputDecoration(
                labelText: "Date",
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 10),

            // 📌 Customer Name
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: "Customer Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // 📌 Phone Number (10 digits only)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
                counterText: "", // hide counter
              ),
            ),
            const SizedBox(height: 10),

            // 📌 Item Details
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: "Item Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Qty",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _addOrder,
              child: const Text("➕ Add Return Item"),
            ),
            const SizedBox(height: 20),

            // 📌 Return Orders List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: returnOrders.length,
              itemBuilder: (context, index) {
                final order = returnOrders[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Invoice + Date
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "📑 Invoice: ${order['invoice']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text("📅 ${order['date']}"),
                          ],
                        ),
                        const Divider(),

                        // Row 2: Customer Name
                        Text("👤 Customer: ${order['customer']}"),
                        const SizedBox(height: 5),

                        // Row 3: Phone
                        Text("📞 Phone: ${order['phone']}"),
                        const SizedBox(height: 5),

                        // Row 4: Item Details
                        Text(
                          "📦 Item: ${order['item']} (x${order['qty']}) @ ₹${order['price']}",
                        ),
                        const SizedBox(height: 5),

                        // Row 5: Total
                        Text(
                          "💰 Total: ₹${order['total']}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
