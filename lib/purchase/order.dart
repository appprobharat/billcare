import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PurchaseOrderPage extends StatefulWidget {
  const PurchaseOrderPage({super.key});

  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage> {
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<Map<String, dynamic>> orderItems = [];
  List<Map<String, dynamic>> savedOrders = [];

  int invoiceNo = 1;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final ordersString = prefs.getString('purchase_orders');
    if (ordersString != null) {
      final List decoded = jsonDecode(ordersString);
      setState(() {
        savedOrders = decoded.cast<Map<String, dynamic>>();
        invoiceNo = savedOrders.length + 1; // auto increment
      });
    }
  }

  Future<void> _saveOrdersToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('purchase_orders', jsonEncode(savedOrders));
  }

  void _addItem() {
    if (_itemNameController.text.isEmpty ||
        _qtyController.text.isEmpty ||
        _priceController.text.isEmpty) {
      return;
    }

    final int qty = int.tryParse(_qtyController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0;
    final double total = qty * price;

    setState(() {
      orderItems.add({
        'name': _itemNameController.text,
        'qty': qty,
        'price': price,
        'total': total,
      });
    });

    _itemNameController.clear();
    _qtyController.clear();
    _priceController.clear();
  }

  void _saveOrder() {
    if (_supplierController.text.isEmpty ||
        _phoneController.text.length != 10 ||
        orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields properly")),
      );
      return;
    }

    final double grandTotal = orderItems.fold(
      0,
      (sum, item) => sum + (item['total'] as double),
    );

    final order = {
      'invoiceNo': invoiceNo,
      'date': DateFormat('dd-MM-yyyy').format(selectedDate),
      'supplier': _supplierController.text,
      'phone': _phoneController.text,
      'items': orderItems,
      'total': grandTotal,
    };

    setState(() {
      savedOrders.add(order);
      invoiceNo++;
      orderItems = [];
      _supplierController.clear();
      _phoneController.clear();
    });

    _saveOrdersToPrefs();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Purchase Order Page")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice No & Date Row
            Row(
              children: [
                Text(
                  "Invoice No: $invoiceNo",
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Date",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat('dd-MM-yyyy').format(selectedDate),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Supplier Name
            TextField(
              controller: _supplierController,
              decoration: const InputDecoration(
                labelText: "Supplier Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),

            // Phone Number
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 10),

            // Add Item Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _itemNameController,
                    decoration: const InputDecoration(
                      labelText: "Item Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Qty",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(icon: const Icon(Icons.add), onPressed: _addItem),
              ],
            ),
            const SizedBox(height: 10),

            // Items List
            Column(
              children: orderItems
                  .map(
                    (item) => ListTile(
                      title: Text(item['name']),
                      subtitle: Text("Qty: ${item['qty']} × ${item['price']}"),
                      trailing: Text("Total: ${item['total']}"),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),

            Center(
              child: ElevatedButton(
                onPressed: _saveOrder,
                child: const Text("Save Order"),
              ),
            ),
            const Divider(height: 30),

            // Saved Orders List
            const Text(
              "Saved Purchase Orders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            Column(
              children: savedOrders.map((order) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Invoice No: ${order['invoiceNo']}"),
                        Text("Date: ${order['date']}"),
                        Text("Supplier: ${order['supplier']}"),
                        Text("Phone: ${order['phone']}"),
                        const SizedBox(height: 5),
                        const Text(
                          "Items:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Column(
                          children: (order['items'] as List)
                              .map(
                                (item) => Text(
                                  "${item['name']} - ${item['qty']} × ${item['price']} = ${item['total']}",
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Total: ${order['total']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
