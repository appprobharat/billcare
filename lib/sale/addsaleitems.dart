import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Item Model (No Change) ---
class Item {
  final int id;
  final String name;
  final String mrp;
  final String salePrice;
  final String purchasePrice;
  final String stock;
  final String category;
  final int cgst;
  final int igst;
  final int sgst;

  Item({
    required this.id,
    required this.name,
    required this.mrp,
    required this.sgst,
    required this.igst,
    required this.cgst,
    required this.salePrice,
    required this.purchasePrice,
    required this.stock,
    required this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    int _safeIntParse(dynamic value) {
      if (value is int) {
        return value;
      }
      if (value is String) {
        return int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return Item(
      id: json['id'] as int,
      name: json['Name'] as String? ?? 'N/A',
      mrp: json['MRP'] as String? ?? '0',
      salePrice: json['SalePrice'] as String? ?? '0',
      purchasePrice: json['PurchasePrice'] as String? ?? '0',
      stock: json['Stock'] as String? ?? '0',
      category: json['Category'] as String? ?? 'N/A',
      cgst: _safeIntParse(json['CGST']),
      sgst: _safeIntParse(json['SGST']),
      igst: _safeIntParse(json['IGST']),
    );
  }
}

class AddSaleItemsPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialItems;
  final String pageTitle;

  const AddSaleItemsPage({
    super.key,
    this.initialItems = const [],
    this.pageTitle = "Add Items to Sale",
  });

  @override
  State<AddSaleItemsPage> createState() => _AddSaleItemsPageState();
}

class _AddSaleItemsPageState extends State<AddSaleItemsPage> {
  final _formKey = GlobalKey<FormState>();

  final itemSearchController = TextEditingController();
  final quantity1Controller = TextEditingController();
  final quantity2Controller = TextEditingController();
  final DiscountController = TextEditingController();
  final GSTAmtController = TextEditingController();
  final _itemFocusNode = FocusNode();

  String? selectedUnit1;

  bool _isLoadingItems = true;
  List<Item> savedItems = [];
  List<Item> filteredItems = [];
  bool showItemList = false;
  bool _isEditingItem = false;

  List<Map<String, dynamic>> addedItems = [];
  double totalAmount = 0.0;
  double totalDiscount = 0;
  double totalGST = 0.0;
  double totalSubtotal = 0.0;

  Item? _selectedItem;

  @override
  void initState() {
    super.initState();
    addedItems = List.from(widget.initialItems);
    _calculateTotals();
    _fetchItems();

    itemSearchController.addListener(_filterItems);
    _itemFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        showItemList = _itemFocusNode.hasFocus;
      });
    }
  }

  // --- API and Total Calculation Methods (No Change in logic) ---
  Future<void> _fetchItems() async {
    if (mounted) {
      setState(() {
        _isLoadingItems = true;
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication token missing.')),
          );
        }
        return;
      }
      final itemData = await ApiService.fetchItems(token);
      if (mounted) {
        setState(() {
          savedItems = itemData.map((json) => Item.fromJson(json)).toList();
          filteredItems = List.from(savedItems);
        });
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingItems = false;
        });
      }
    }
  }

  void _calculateTotals() {
    double tempTotalAmount = 0.0;
    double tempTotalDiscount = 0.0;
    double tempTotalGST = 0.0;
    double tempTotalSubtotal = 0.0;

    for (var item in addedItems) {
      tempTotalSubtotal += item['subtotal'] ?? 0.0;
      tempTotalGST += item['GSTAmt'] ?? 0.0;
      tempTotalDiscount += item['Discount'] ?? 0.0;
    }
    tempTotalAmount = tempTotalSubtotal - tempTotalDiscount + tempTotalGST;

    if (mounted) {
      setState(() {
        totalSubtotal = tempTotalSubtotal;
        totalGST = tempTotalGST;
        totalDiscount = tempTotalDiscount;
        totalAmount = tempTotalAmount;
      });
    }
  }

  @override
  void dispose() {
    itemSearchController.removeListener(_filterItems);
    itemSearchController.dispose();
    quantity1Controller.dispose();
    quantity2Controller.dispose();
    DiscountController.dispose();
    GSTAmtController.dispose();
    _itemFocusNode.removeListener(_onFocusChange);
    _itemFocusNode.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = itemSearchController.text.toLowerCase();
    if (mounted) {
      setState(() {
        filteredItems = savedItems
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      });
    }
  }

  void _onItemSelect(Item item) {
    setState(() {
      _selectedItem = item;
    });
    itemSearchController.text = item.name;
    quantity1Controller.text = '1';

    quantity2Controller.text = item.salePrice;
    final int cgst = item.cgst;
    final int sgst = item.sgst;
    final int igst = item.igst;

    final int finalGSTRate;
    if (igst > 0) {
      finalGSTRate = igst;
    } else {
      finalGSTRate = cgst + sgst;
    }

    // --- Print for Debugging ---
    debugPrint('--- CGST: $cgst, SGST: $sgst, IGST: $igst ---');
    debugPrint(
      '--- Calculated Final GST Rate for ${item.name}: $finalGSTRate% ---',
    );
    DiscountController.text = "0";
    GSTAmtController.text = finalGSTRate.toString();

    if (mounted) {
      setState(() {
        selectedUnit1 = 'Piece';
        showItemList = false;
      });
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  int calculateFinalGSTRate({
    required int cgst,
    required int sgst,
    required int igst,
  }) {
    // 1. यदि IGST > 0 है, तो यह इंटर-स्टेट सेल है, IGST का उपयोग करें।
    if (igst > 0) {
      return igst;
    }
    // 2. अन्यथा, यह इंट्रा-स्टेट सेल है, CGST और SGST को जोड़ें।
    else {
      return cgst + sgst;
    }
  }

  // --- Dialog is kept as is, but validators are included ---
  void _addNewItemDialog() {
    final newNameController = TextEditingController();
    final newStockController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Item", style: TextStyle(fontSize: 16)),
          contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: newNameController,
                  decoration: const InputDecoration(
                    labelText: "Item Name",
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: newStockController,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final stock = double.tryParse(value ?? '');
                    if (stock != null && stock < 0) {
                      return 'Stock cannot be negative.';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: "Stock",
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (dialogFormKey.currentState!.validate()) {
                  final itemName = newNameController.text.trim();
                  final itemStock = newStockController.text.trim();

                  final newItem = Item(
                    id: -1,
                    name: itemName,
                    mrp: '0',
                    salePrice: '0',
                    purchasePrice: '0',
                    stock: itemStock.isNotEmpty ? itemStock : '0',
                    category: 'Custom',
                    cgst: 0,
                    sgst: 0,
                    igst: 0,
                  );

                  if (mounted) {
                    setState(() {
                      savedItems.insert(0, newItem);
                      filteredItems.insert(0, newItem);
                      Navigator.pop(context);
                      _onItemSelect(newItem);
                    });
                  }
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  // --- Item Tile is made more compact ---
  Widget _itemTile(Item item) {
    final titleText = item.category != 'N/A' && item.category != 'Custom'
        ? "${item.category} - ${item.name}"
        : item.name;
    return ListTile(
      dense: true, // Makes the tile smaller
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 0,
      ), // Smaller padding
      title: Text(
        titleText,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ), // Smaller font
      ),
      subtitle: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12, color: Colors.black),
          children: [
            TextSpan(
              text: "Stock: ${item.stock}",
              style: TextStyle(
                color: (double.tryParse(item.stock.toString()) ?? 0) > 0
                    ? Colors.green
                    : Colors.red,
              ),
            ),
            TextSpan(text: " | MRP: ₹${item.mrp}"),
            TextSpan(text: " | Sale: ₹${item.salePrice}"),
          ],
        ),
      ),

      onTap: () => _onItemSelect(item),
    );
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix validation errors in fields."),
        ),
      );
      return;
    }

    final itemName = itemSearchController.text.trim();
    if (itemName.isEmpty || _selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an item before adding.")),
      );
      return;
    }

    final quantity = double.tryParse(quantity1Controller.text) ?? 0.0;
    final price = double.tryParse(quantity2Controller.text) ?? 0.0;
    final DiscountRate = double.tryParse(DiscountController.text) ?? 0.0;
    final GSTRate = double.tryParse(GSTAmtController.text) ?? 0.0;

    double baseSubtotal = quantity * price;
    double DiscountAmount = baseSubtotal * (DiscountRate / 100);
    double taxableValue = baseSubtotal - DiscountAmount;
    double GSTAmt = taxableValue * (GSTRate / 100);
    double itemTotalAmount = taxableValue + GSTAmt;
    final newItem = {
      'id': _selectedItem!.id,
      'name': _selectedItem!.name,
      'category': _selectedItem!.category,
      'quantity': quantity.toInt(),
      'price': price,
      'subtotal': baseSubtotal,
      'GSTAmt': GSTAmt,
      'Discount': DiscountAmount,
      'unit': selectedUnit1,
      'GSTRate': GSTRate,
      'Disc': DiscountRate,
      'itemTotal': itemTotalAmount,
    };

    if (mounted) {
      setState(() {
        addedItems.add(newItem);
        _calculateTotals();
        itemSearchController.clear();
        quantity1Controller.clear();
        quantity2Controller.clear();
        DiscountController.clear();
        GSTAmtController.clear();
        selectedUnit1 = null;
        _selectedItem = null;
        _isEditingItem = false;
      });
    }
  }

  void _removeItem(int index) {
    if (mounted) {
      setState(() {
        addedItems.removeAt(index);
        _calculateTotals();
      });
    }
  }

  void _editItem(int index) {
    final itemToEdit = addedItems[index];

    final tempItem = Map<String, dynamic>.from(itemToEdit);
    addedItems.removeAt(index);
    _calculateTotals();

    itemSearchController.text = tempItem['name'].toString();
    quantity1Controller.text = tempItem['quantity'].toString();
    quantity2Controller.text = tempItem['price'].toString();

    final subtotal = tempItem['subtotal'] ?? 0.0;
    if (subtotal > 0) {
      final discountPercentage = (tempItem['Discount'] / subtotal) * 100;
      final gstPercentage = (tempItem['GSTAmt'] / subtotal) * 100;
      DiscountController.text = discountPercentage.toStringAsFixed(2);
      GSTAmtController.text = gstPercentage.toStringAsFixed(2);
    } else {
      DiscountController.text = "0";
      GSTAmtController.text = "0";
    }

    selectedUnit1 = tempItem['unit'];

    _selectedItem = Item(
      id: tempItem['id'],
      name: tempItem['name'],
      category: tempItem['category'],
      mrp: '0',
      salePrice: '0',
      purchasePrice: '0',
      stock: '0',
      cgst: 0,
      sgst: 0,
      igst: 0,
    );

    setState(() {
      showItemList = false;
      _isEditingItem = true;
    });
  }

  // --- Compact Input Decoration Helper ---
  InputDecoration _compactDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      // 👇 Key for compact design
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      labelStyle: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildAddedItemsList() {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                "Added Items",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 8),
            if (addedItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: Text(
                    "No items added yet.",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: addedItems.length,
                itemBuilder: (context, index) {
                  final item = addedItems[index];
                  final itemTotal =
                      (item['subtotal'] ?? 0.0) +
                      (item['GSTAmt'] ?? 0.0) -
                      (item['Discount'] ?? 0);
                  return Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['category'] != null &&
                                            item['category'] != 'N/A' &&
                                            item['category'] != 'Custom'
                                        ? "${item['category']} - ${item['name']}"
                                        : item['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Rate: ₹${(item['price'] ?? 0).toStringAsFixed(1)} x Qty: ${item['quantity'] ?? 0}",
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "Disc: ${(item['Disc'] as double? ?? 0.0).toStringAsFixed(0)}%",
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "| GST: ${(item['GSTRate'] as double? ?? 0.0).toStringAsFixed(0)}%",
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "₹${itemTotal.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                        size: 14,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _editItem(index),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 14,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _removeItem(index),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

            // --- New One-Line Totals Row ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          "Subtotal",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Discount",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "GST",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Total",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text("₹${totalSubtotal.toStringAsFixed(1)}"),
                      ),
                      Expanded(
                        child: Text(
                          "₹${totalDiscount.toStringAsFixed(1)}",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "₹${totalGST.toStringAsFixed(1)}",
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "₹${totalAmount.toStringAsFixed(1)}",
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Build Method ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.pageTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
          ), // Slightly smaller title
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          setState(() {
            showItemList = false;
          });
        },
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(12), // Reduced main padding
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Search Field (Compact)
                    TextFormField(
                      controller: itemSearchController,
                      focusNode: _itemFocusNode,
                      decoration: _compactDecoration(
                        labelText: "Item Name (Search)",
                      ),
                      onTap: () {
                        setState(() {
                          showItemList = true;
                        });
                      },
                    ),
                    const SizedBox(height: 10), // Reduced spacing
                    // Quantity and Rate/Price Row (Compact)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: quantity1Controller,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required'; // Shorter error message
                              }
                              final qty = double.tryParse(value);
                              if (qty == null || qty < 1) {
                                return 'Min 1'; // Shorter error message
                              }
                              return null;
                            },
                            decoration: _compactDecoration(
                              labelText: "Quantity",
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Reduced spacing
                        Expanded(
                          child: TextFormField(
                            controller: quantity2Controller,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final rate = double.tryParse(value ?? '');
                              if (rate == null || rate < 0) {
                                return 'Cannot be negative';
                              }
                              return null;
                            },
                            decoration: _compactDecoration(
                              labelText: "Rate/Price",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10), // Reduced spacing
                    // Discount and GST Row (Compact)
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: DiscountController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final discount = double.tryParse(value ?? '');
                              if (discount == null || discount < 0) {
                                return 'Cannot be negative'; // Shorter error message
                              }
                              return null;
                            },
                            decoration: _compactDecoration(
                              labelText: "Discount(%)",
                            ),
                          ),
                        ),
                        const SizedBox(width: 10), // Reduced spacing
                        Expanded(
                          child: TextFormField(
                            controller: GSTAmtController,

                            keyboardType: TextInputType.number,

                            readOnly: true,
                            decoration: _compactDecoration(
                              labelText: "GST (%)",
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10), // Reduced spacing
                    // Add/Edit Button (Compact)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addItem,
                        icon: Icon(
                          _isEditingItem ? Icons.edit : Icons.add,
                          size: 18, // Smaller icon
                        ),
                        label: Text(
                          _isEditingItem ? "Edit Item" : "Add Item",
                          style: const TextStyle(fontSize: 14), // Smaller text
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ), // Reduced padding
                        ),
                      ),
                    ),
                    _buildAddedItemsList(),
                  ],
                ),
              ),
            ),

            // Item List Overlay (Compact)
            if (showItemList)
              Positioned(
                top: 52,
                left: 12,
                right: 12,
                child: _isLoadingItems
                    ? const Center(child: CircularProgressIndicator())
                    : Card(
                        margin: EdgeInsets.zero,
                        elevation: 2,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              // Vertical padding 6 से घटाकर 4 किया गया
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Saved Items",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13, // थोड़ा छोटा फ़ॉन्ट
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: _addNewItemDialog,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero, // Padding Zero
                                      minimumSize: const Size(50, 18),
                                      tapTargetSize: MaterialTapTargetSize
                                          .shrinkWrap, // Tap size कम किया गया
                                    ),
                                    child: const Text(
                                      "Add New",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12, // फ़ॉन्ट और छोटा
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 0.5, thickness: 0.5),

                            if (filteredItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(
                                  4,
                                ), // Padding 8 से 6 किया गया
                                child: Text(
                                  "No item found",
                                  style: TextStyle(
                                    fontSize: 12,
                                  ), // फ़ॉन्ट और छोटा
                                ),
                              )
                            else
                              SizedBox(
                                height: (filteredItems.length > 5
                                    ? 5 * 40.0
                                    : filteredItems.length * 35.0),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: filteredItems.length,
                                  itemBuilder: (_, index) =>
                                      _itemTile(filteredItems[index]),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
          ],
        ),
      ),

      // Bottom Bar (Compact)
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 30),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(fontSize: 14),
                ), // Smaller font
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: addedItems.isEmpty
                    ? null
                    : () {
                        final Map<String, dynamic> saleDetails = {
                          'items': addedItems,
                          'TotalAmt': totalAmount,
                          'Discount': totalDiscount,
                          'GSTAmt': totalGST,
                          'subtotal': totalSubtotal,
                        };
                        debugPrint('--- Sale Details Payload ---');
                        debugPrint(saleDetails.toString());
                        debugPrint('----------------------------');
                        Navigator.pop(context, saleDetails);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text("Save", style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
