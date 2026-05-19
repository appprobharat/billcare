import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PurchaseReturnPage extends StatefulWidget {
  const PurchaseReturnPage({super.key});

  @override
  State<PurchaseReturnPage> createState() => _PurchaseReturnPageState();
}

class _PurchaseReturnPageState extends State<PurchaseReturnPage> {
  final TextEditingController _supplierController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  List<Map<String, dynamic>> purchaseReturns = [];
  int _invoiceNo = 1;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadReturns();
  }

  Future<void> _loadReturns() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString("purchase_returns");
    if (savedData != null) {
      setState(() {
        purchaseReturns = List<Map<String, dynamic>>.from(
          jsonDecode(savedData),
        );
        _invoiceNo = purchaseReturns.length + 1;
      });
    }
  }

  Future<void> _saveReturns() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("purchase_returns", jsonEncode(purchaseReturns));
  }

  void _addReturn() {
    if (_supplierController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _itemController.text.isEmpty ||
        _qtyController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please fill all fields")),
      );
      return;
    }

    final int qty = int.tryParse(_qtyController.text) ?? 0;
    final double price = double.tryParse(_priceController.text) ?? 0;
    final double total = qty * price;

    setState(() {
      purchaseReturns.add({
        "invoiceNo": _invoiceNo,
        "date": DateFormat("dd-MM-yyyy").format(_selectedDate),
        "supplier": _supplierController.text,
        "phone": _phoneController.text,
        "item": _itemController.text,
        "qty": qty,
        "price": price,
        "total": total,
      });
      _invoiceNo++;
    });

    _saveReturns();

    _itemController.clear();
    _qtyController.clear();
    _priceController.clear();
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    setState(() {
      _selectedDate = picked!;
    });
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Purchase Return")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Invoice + Date Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(
                      text: _invoiceNo.toString(),
                    ),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Invoice No",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: "Date",
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        DateFormat("dd-MM-yyyy").format(_selectedDate),
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

            // Phone Number (10 digits only)
            TextField(
              controller: _phoneController,
              maxLength: 10,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                border: OutlineInputBorder(),
                counterText: "",
              ),
            ),
            const SizedBox(height: 10),

            // Item, Qty, Price Row
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: "Item Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                const SizedBox(width: 8),
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
              ],
            ),
            const SizedBox(height: 15),

            ElevatedButton(
              onPressed: _addReturn,
              child: const Text("➕ Add Purchase Return"),
            ),
            const SizedBox(height: 20),

            // Show Saved Returns
            ...purchaseReturns.map(
              (ret) => Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📄 Invoice No: ${ret["invoiceNo"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("📅 Date: ${ret["date"]}"),
                      Text("🏢 Supplier: ${ret["supplier"]}"),
                      Text("📞 Phone: ${ret["phone"]}"),
                      Text("📦 Item: ${ret["item"]}"),
                      Text(
                        "🔢 Qty: ${ret["qty"]}  |  💰 Price: ${ret["price"]}",
                      ),
                      Text(
                        "💵 Total: ${ret["total"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
