import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MaterialApp(home: SalesOrderPage()));
}

// Item Model
class OrderItem {
  final String name;
  final int quantity;
  final double price;

  OrderItem({required this.name, required this.quantity, required this.price});

  double get total => quantity * price;

  Map<String, dynamic> toJson() => {
    "name": name,
    "quantity": quantity,
    "price": price,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? '',
      quantity: (json['quantity'] ?? 0) as int,
      price: (json['price'] ?? 0).toDouble(),
    );
  }
}

// Sales Order Page
class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final TextEditingController _customerController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController totalController = TextEditingController();

  double total = 0;
  List<OrderItem> orderItems = [];
  List<Map<String, dynamic>> ordersList = [];
  int nextOrderNo = 1;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _qtyController.addListener(_calculateTotal);
    priceController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0;
    setState(() {
      total = qty * price;
      totalController.text = total.toStringAsFixed(2); // 👈 Live update
    });
  }

  void _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList("orders") ?? [];
    List<Map<String, dynamic>> loadedOrders = saved
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    setState(() {
      ordersList = loadedOrders;
      if (ordersList.isNotEmpty) {
        nextOrderNo =
            ordersList
                .map((e) {
                  final no = e['orderNo'];
                  if (no == null) return 0;
                  if (no is int) return no;
                  if (no is String) return int.tryParse(no) ?? 0;
                  return 0;
                })
                .reduce((a, b) => a > b ? a : b) +
            1;
      }
    });
  }

  @override
  void dispose() {
    _itemController.dispose();
    _qtyController.dispose();
    priceController.dispose();
    totalController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _itemController.text.trim();
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final price = double.tryParse(priceController.text) ?? 0.0;

    if (name.isEmpty || qty <= 0 || price <= 0) return;

    setState(() {
      orderItems.add(OrderItem(name: name, quantity: qty, price: price));
    });

    _itemController.clear();
    _qtyController.clear();
    priceController.clear();
    totalController.clear();
    total = 0;
  }

  void _saveOrder() async {
    if (_customerController.text.isEmpty ||
        _phoneController.text.length != 10 ||
        orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly")),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    // 👇 sab items ka total calculate
    double totalAmount = orderItems.fold(0, (sum, item) => sum + item.total);

    Map<String, dynamic> orderData = {
      "orderNo": nextOrderNo,
      "customer": _customerController.text.trim(),
      "phone": _phoneController.text.trim(),
      "date": selectedDate.toIso8601String(),
      "items": orderItems.map((e) => e.toJson()).toList(),
      "totalAmount": totalAmount,
    };

    List<String> savedOrders = prefs.getStringList("orders") ?? [];
    savedOrders.add(jsonEncode(orderData));
    await prefs.setStringList("orders", savedOrders);

    setState(() {
      ordersList.add(orderData);
      nextOrderNo++;
      orderItems.clear();
      _customerController.clear();
      _phoneController.clear();
      selectedDate = DateTime.now();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Order saved successfully")));
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    setState(() => selectedDate = picked!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sales Order Page")),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "Order No: $nextOrderNo",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 60),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: Text(
                    "Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: "Customer Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: "Item Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceController,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: totalController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Total",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _addItem, child: const Text("Add")),
              ],
            ),
            const SizedBox(height: 10),
            if (orderItems.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orderItems.length,
                  itemBuilder: (context, index) {
                    final item = orderItems[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: Text(
                        "Qty: ${item.quantity}, Price: ₹${item.price.toStringAsFixed(2)}",
                      ),
                      trailing: Text(
                        "Total: ₹${item.total.toStringAsFixed(2)}",
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Center(
              child: ElevatedButton(
                onPressed: _saveOrder,
                child: const Text("Save Order"),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              "Saved Orders",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ordersList.length,
              itemBuilder: (context, index) {
                final order = ordersList[index];
                final items = (order['items'] as List<dynamic>)
                    .map((e) => OrderItem.fromJson(e))
                    .toList();
                return Card(
                  child: ListTile(
                    title: Text(
                      "Order ${order['orderNo']}: ${order['customer']}",
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Phone: ${order['phone']}"),
                        Text(
                          "Date: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(order['date']))}",
                        ),
                        ...items.map(
                          (e) => Text(
                            "${e.name} - Qty:${e.quantity} x ₹${e.price}",
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "👉 Total Amount: ₹${(order['totalAmount'] ?? 0).toStringAsFixed(2)}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
