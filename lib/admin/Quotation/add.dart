// ------------------------------------------------------------------------------------------------
// add_quotation_page.dart
// ------------------------------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// AddQuotationPage class: यह नया कोटेशन बनाने के लिए पेज है।
class AddQuotationPage extends StatefulWidget {
  const AddQuotationPage({super.key});

  @override
  State<AddQuotationPage> createState() => _AddQuotationPageState();
}

class _AddQuotationPageState extends State<AddQuotationPage> {
  // Client और items के लिए Mock data.
  final List<String> _clients = ["Client A", "Client B", "Client C"];
  final List<Map<String, dynamic>> _availableItems = [
    {"name": "Item 1", "price": 100.0, "tax": 5.0},
    {"name": "Item 2", "price": 150.0, "tax": 10.0},
    {"name": "Item 3", "price": 250.0, "tax": 18.0},
    {"name": "Item 4", "price": 300.0, "tax": 12.0},
  ];

  String? _selectedClient;
  String? _selectedItemName;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _discountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _taxController = TextEditingController(text: '0');

  final List<Map<String, dynamic>> _selectedItems = [];
  double _grandTotal = 0.0;
  double _currentItemTotal = 0.0;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(_calculateItemTotal);
    _discountController.addListener(_calculateItemTotal);
    _taxController.addListener(_calculateItemTotal);
  }

  @override
  void dispose() {
    _quantityController.removeListener(_calculateItemTotal);
    _discountController.removeListener(_calculateItemTotal);
    _taxController.removeListener(_calculateItemTotal);
    super.dispose();
  }

  // आइटम के लिए कुल राशि की गणना करें।
  void _calculateItemTotal() {
    final double price = double.tryParse(_priceController.text) ?? 0.0;
    final int quantity = int.tryParse(_quantityController.text) ?? 0;
    final double discount = double.tryParse(_discountController.text) ?? 0.0;
    final double tax = double.tryParse(_taxController.text) ?? 0.0;

    setState(() {
      final subtotal = (price * quantity);
      final taxAmount = (subtotal - discount) * (tax / 100);
      _currentItemTotal = (subtotal - discount) + taxAmount;
    });
  }

  // आइटम को सूची में जोड़ें।
  void _addItem() {
    if (_selectedItemName != null && _quantityController.text.isNotEmpty) {
      final item = _availableItems.firstWhere(
        (i) => i['name'] == _selectedItemName,
      );
      final newItem = {
        "name": item['name'],
        "price": item['price'],
        "quantity": int.tryParse(_quantityController.text) ?? 1,
        "discount": double.tryParse(_discountController.text) ?? 0.0,
        "tax": double.tryParse(_taxController.text) ?? 0.0,
        "total": _currentItemTotal,
      };

      setState(() {
        _selectedItems.add(newItem);
        _grandTotal += _currentItemTotal;
        // Fields को रीसेट करें।
        _selectedItemName = null;
        _priceController.text = '';
        _quantityController.text = '1';
        _discountController.text = '0';
        _taxController.text = '0';
        _currentItemTotal = 0.0;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an item and quantity.')),
      );
    }
  }

  // कोटेशन को सेव करें और वापस पिछले पेज पर जाएं।
  void _saveQuotation() {
    if (_selectedClient == null || _selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client and add at least one item.'),
        ),
      );
      return;
    }

    final newQuotation = {
      "invoiceNo":
          "INV-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}",
      "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
      "clientName": _selectedClient,
      "contactNo": "N/A",
      "noOfItems": _selectedItems.length,
      "total": _grandTotal,
      "items": _selectedItems,
    };

    Navigator.pop(context, newQuotation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Quotation")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select Client Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              value: _selectedClient,
              items: _clients
                  .map(
                    (String client) => DropdownMenuItem<String>(
                      value: client,
                      child: Text(client),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) =>
                  setState(() => _selectedClient = newValue),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Select Item Name",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              value: _selectedItemName,
              items: _availableItems
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item['name'],
                      child: Text(item['name']),
                    ),
                  )
                  .toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedItemName = newValue;
                  if (newValue != null) {
                    final item = _availableItems.firstWhere(
                      (i) => i['name'] == newValue,
                    );
                    _priceController.text = item['price'].toString();
                    _taxController.text = item['tax'].toString();
                    _calculateItemTotal();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Price",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Quantity",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Discount",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Tax %",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: _currentItemTotal.toStringAsFixed(2),
                    ),
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: "Total",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _addItem,
                    child: const Text("Add Item"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              "Added Items",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Divider(),
            if (_selectedItems.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  final item = _selectedItems[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${index + 1}. ${item['name']}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text("Price: ₹${item['price'].toStringAsFixed(2)}"),
                          Text("Quantity: ${item['quantity']}"),
                          Text(
                            "Discount: ₹${item['discount'].toStringAsFixed(2)}",
                          ),
                          Text("Tax: ${item['tax']}%"),
                          Text(
                            "Total: ₹${item['total'].toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              const Center(child: Text("No items added yet.")),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Grand Total:",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      "₹${_grandTotal.toStringAsFixed(2)}",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveQuotation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Save Quotation"),
            ),
          ],
        ),
      ),
    );
  }
}
