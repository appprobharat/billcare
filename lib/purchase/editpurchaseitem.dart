import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  Item({
    required this.id,
    required this.name,
    required this.mrp,
    required this.salePrice,
    required this.purchasePrice,
    required this.stock,
    required this.category,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as int,
      name: json['Name'] as String? ?? 'N/A',
      mrp: json['MRP'] as String? ?? '0',
      salePrice: json['SalePrice'] as String? ?? '0',
      purchasePrice: json['PurchasePrice'] as String? ?? '0',
      stock: json['Stock'] as String? ?? '0',
      category: json['Category'] as String? ?? 'N/A',
    );
  }
}

class EditPurchaseItemsPage extends StatefulWidget {
  final int purchaseId;
  final List<Map<String, dynamic>> initialItems;
  final String pageTitle;

  const EditPurchaseItemsPage({
    super.key,
    required this.purchaseId,
    required this.initialItems,
    this.pageTitle = "Edit Items in Purchase",
  });

  @override
  State<EditPurchaseItemsPage> createState() => _EditPurchaseItemsPageState();
}

class _EditPurchaseItemsPageState extends State<EditPurchaseItemsPage> {
  final _formKey = GlobalKey<FormState>();

  final itemSearchController = TextEditingController();
  final quantity1Controller = TextEditingController();
  final quantity2Controller = TextEditingController();
  final DiscountController = TextEditingController();
  final GSTAmtController = TextEditingController();
  final _itemFocusNode = FocusNode();
  String? selectedUnit1 = 'Piece';
  bool _isLoadingItems = true;
  List<Item> savedItems = [];
  List<Item> filteredItems = [];
  bool showItemList = false;
  bool _isEditingItem = false;
  int? _editingItemOriginalIndex;
  List<Map<String, dynamic>> addedItems = [];
  double totalAmount = 0.0;
  double totalDiscount = 0.0;
  double totalGST = 0.0;
  double totalSubtotal = 0.0;
  Item? _selectedItem;

  @override
  void initState() {
    super.initState();
    addedItems = List<Map<String, dynamic>>.from(widget.initialItems);
    print("🟢 INIT: Initial items loaded: ${addedItems.length}");
    _calculateTotals();
    _fetchItems();
    itemSearchController.addListener(_filterItems);
    _itemFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            showItemList =
                _itemFocusNode.hasFocus && itemSearchController.text.isNotEmpty;
          });
        }
      });
    }
  }

  // --- API and Total Calculation Methods ---
  Future<void> _fetchItems() async {
    print("🔄 Fetching items from API...");
    if (mounted) {
      setState(() {
        _isLoadingItems = true;
      });
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      print("🟩 Token found: $token");
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Authentication token missing.')),
          );
        }
        return;
      }
      final itemData = await ApiService.fetchItems(token);
      print("🟩 Fetched items: $itemData");
      if (mounted) {
        setState(() {
          savedItems = itemData.map((json) => Item.fromJson(json)).toList();
          filteredItems = List.from(savedItems);
        });
      }
    } on Exception catch (e) {
      print("❌ ERROR in _fetchItems: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load items: $e')));
      }
    } finally {
      if (mounted) {
        print("🟢 Item fetch complete. Saved Items: ${savedItems.length}");
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
      tempTotalSubtotal += (item['subtotal'] as num?)?.toDouble() ?? 0.0;
      tempTotalGST += (item['GSTAmt'] as num?)?.toDouble() ?? 0.0;
      tempTotalDiscount += (item['Discount'] as num?)?.toDouble() ?? 0.0;
    }

    tempTotalAmount = tempTotalSubtotal + tempTotalGST - tempTotalDiscount;
    print(
      "➡️ Subtotal: $tempTotalSubtotal | GST: $tempTotalGST | "
      "Discount: $tempTotalDiscount | Total: $tempTotalAmount",
    );
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
        showItemList = _itemFocusNode.hasFocus && query.isNotEmpty;
      });
    }
  }

  void _onItemSelect(Item item) {
    setState(() {
      _selectedItem = item;
    });
    itemSearchController.text = item.name;

    if (!_isEditingItem) {
      quantity1Controller.text = '1';
      quantity2Controller.text = item.salePrice;
      GSTAmtController.text = "0";
      DiscountController.text = "0";
    }

    if (mounted) {
      setState(() {
        selectedUnit1 = 'Piece';
        showItemList = false;
      });
      FocusScope.of(context).requestFocus(FocusNode());
    }
  }

  // --- ADDED: The missing _itemTile widget helper ---
  Widget _itemTile(Item item) {
    final titleText = item.category != 'N/A' && item.category != 'Custom'
        ? "${item.category} - ${item.name}"
        : item.name;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: Text(
        titleText,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        "Qty: ${item.stock} | MRP: ₹${item.mrp} | Sale: ₹${item.salePrice}",
        style: const TextStyle(fontSize: 12),
      ),
      onTap: () => _onItemSelect(item),
    );
  }

  // --- Dialog for Adding New Item (No Functional Change) ---
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
                  decoration: _compactDecoration(labelText: "Item Name"),
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
                  decoration: _compactDecoration(labelText: "Stock"),
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

  // --- LOGIC FOR ADD/UPDATE ITEM ---
  void _updateItem() {
    if (_editingItemOriginalIndex == null || _selectedItem == null) return;

    final quantity = double.tryParse(quantity1Controller.text) ?? 0.0;
    final price = double.tryParse(quantity2Controller.text) ?? 0.0;
    final DiscountRate = double.tryParse(DiscountController.text) ?? 0.0;
    final GSTRate = double.tryParse(GSTAmtController.text) ?? 0.0;

    double subtotal = quantity * price;
    double GSTAmt = subtotal * (GSTRate / 100);
    double DiscountAmount = subtotal * (DiscountRate / 100);

    final updatedItem = {
      'id': _selectedItem!.id,
      'name': _selectedItem!.name,
      'category': _selectedItem!.category,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'GSTAmt': GSTAmt,
      'Discount': DiscountAmount,
      'total': subtotal + GSTAmt - DiscountAmount,
      'unit': selectedUnit1,
    };

    if (mounted) {
      setState(() {
        addedItems[_editingItemOriginalIndex!] = updatedItem;

        _calculateTotals();
        _resetForm();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item updated successfully!"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _addItem() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fix validation errors in fields."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final itemName = itemSearchController.text.trim();
    if (itemName.isEmpty || _selectedItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an item before adding/updating."),
        ),
      );
      return;
    }

    if (_isEditingItem) {
      _updateItem();
      return;
    }

    final quantity = double.tryParse(quantity1Controller.text) ?? 0.0;
    final price = double.tryParse(quantity2Controller.text) ?? 0.0;
    final DiscountRate = double.tryParse(DiscountController.text) ?? 0.0;
    final GSTRate = double.tryParse(GSTAmtController.text) ?? 0.0;

    double subtotal = quantity * price;
    double GSTAmt = subtotal * (GSTRate / 100);
    double DiscountAmount = subtotal * (DiscountRate / 100);

    final newItem = {
      'id': _selectedItem!.id,
      'name': _selectedItem!.name,
      'category': _selectedItem!.category,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
      'GSTAmt': GSTAmt,
      'Discount': DiscountAmount,
      'total': subtotal + GSTAmt - DiscountAmount,
      'unit': selectedUnit1,
    };

    if (mounted) {
      setState(() {
        addedItems.add(newItem);
        _calculateTotals();
        _resetForm();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item added successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetForm() {
    itemSearchController.clear();
    quantity1Controller.clear();
    quantity2Controller.clear();
    DiscountController.text = '0';
    GSTAmtController.text = '0';
    selectedUnit1 = 'Piece';
    _selectedItem = null;
    _isEditingItem = false;
    _editingItemOriginalIndex = null;
    FocusScope.of(context).unfocus();
  }

  void _removeItem(int index) {
    if (mounted) {
      setState(() {
        if (_isEditingItem && _editingItemOriginalIndex == index) {
          _resetForm();
        }
        addedItems.removeAt(index);
        _calculateTotals();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Item removed."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editItem(int index) {
    _resetForm();

    final itemToEdit = addedItems[index];

    itemSearchController.text = itemToEdit['name'].toString();

    final double itemQuantity =
        (itemToEdit['quantity'] as num?)?.toDouble() ?? 0.0;
    quantity1Controller.text = itemQuantity.toString();

    final double itemPrice = (itemToEdit['price'] as num?)?.toDouble() ?? 0.0;
    quantity2Controller.text = itemPrice.toString();

    final double subtotal = (itemToEdit['subtotal'] as num?)?.toDouble() ?? 0.0;
    final double discountAmount =
        (itemToEdit['Discount'] as num?)?.toDouble() ?? 0.0;
    final double gstAmount = (itemToEdit['GSTAmt'] as num?)?.toDouble() ?? 0.0;

    if (subtotal > 0) {
      final discountPercentage = (discountAmount / subtotal) * 100;
      final gstPercentage = (gstAmount / subtotal) * 100;

      DiscountController.text = discountPercentage.toStringAsFixed(2);
      GSTAmtController.text = gstPercentage.toStringAsFixed(2);
    } else {
      DiscountController.text = "0";
      GSTAmtController.text = "0";
    }

    selectedUnit1 = itemToEdit['unit'] ?? 'Piece';

    final originalItem = savedItems.firstWhere(
      (item) => item.id == itemToEdit['id'],
      orElse: () => Item(
        id: itemToEdit['id'],
        name: itemToEdit['name'],
        category: itemToEdit['category'] ?? 'N/A',
        mrp: '0',
        salePrice: itemPrice.toString(),
        purchasePrice: '0',
        stock: '0',
      ),
    );
    _selectedItem = originalItem;

    if (mounted) {
      setState(() {
        showItemList = false;
        _isEditingItem = true;
        _editingItemOriginalIndex = index;
      });
    }
    Scrollable.ensureVisible(
      _formKey.currentContext!,
      duration: const Duration(milliseconds: 300),
      alignment: 0.0,
    );
  }

  void _saveEditsAndClose() {
    final result = {
      'items': addedItems,
      'total': totalAmount,
      'subtotal': totalSubtotal,
      'Discount': totalDiscount,
      'GSTAmt': totalGST,
    };
    print("Updated purchase items: ${addedItems.map((e) => e['id']).toList()}");

    Navigator.pop(context, result);
  }

  // --- Compact Input Decoration Helper (No Change) ---
  InputDecoration _compactDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      border: const OutlineInputBorder(),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      labelStyle: const TextStyle(fontSize: 14),
    );
  }

  // --- Build Added Items List (No Functional Change) ---
  Widget _buildAddedItemsList() {
    Widget buildCompactSummaryRow(
      String title,
      double value, {
      bool isGrandTotal = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isGrandTotal ? 14 : 12,
              ),
            ),
            Text(
              "₹${value.toStringAsFixed(1)}",
              style: TextStyle(
                fontWeight: isGrandTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isGrandTotal ? 14 : 12,
              ),
            ),
          ],
        ),
      );
    }

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
                  final itemSubtotal =
                      (item['subtotal'] as num?)?.toDouble() ?? 0.0;
                  final itemGSTAmt =
                      (item['GSTAmt'] as num?)?.toDouble() ?? 0.0;
                  final itemDiscount =
                      (item['Discount'] as num?)?.toDouble() ?? 0.0;

                  final itemTotal = itemSubtotal + itemGSTAmt - itemDiscount;

                  final isCurrentlyEditing =
                      _isEditingItem && _editingItemOriginalIndex == index;

                  return Column(
                    children: [
                      IntrinsicHeight(
                        child: Container(
                          padding: isCurrentlyEditing
                              ? const EdgeInsets.all(4)
                              : EdgeInsets.zero,
                          decoration: isCurrentlyEditing
                              ? BoxDecoration(
                                  color: Colors.yellow.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: Colors.yellow.shade700,
                                  ),
                                )
                              : null,
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
                                      "Rate: ₹${(item['price'] as num?)?.toStringAsFixed(1) ?? '0.0'} x Qty: ${(item['quantity'] as num?)?.toStringAsFixed(0) ?? '0'}",
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "Disc: ₹${itemDiscount.toStringAsFixed(1)}",
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "| GST: ₹${itemGSTAmt.toStringAsFixed(1)}",
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
                                      SizedBox(
                                        width: 26,
                                        height: 24,
                                        child: IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: isCurrentlyEditing
                                                ? Colors.green
                                                : Colors.blue,
                                            size: 14,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _editItem(index),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 26,
                                        height: 24,
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 14,
                                          ),
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _removeItem(index),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            const Divider(height: 8),
            // Totals
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: buildCompactSummaryRow("Subtotal", totalSubtotal),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: buildCompactSummaryRow("Discount", totalDiscount),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(child: buildCompactSummaryRow("GST", totalGST)),
                    const SizedBox(width: 20),
                    Expanded(
                      child: buildCompactSummaryRow(
                        "Total",
                        totalAmount,
                        isGrandTotal: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Main Build Method (No Major Functional Change) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.pageTitle,
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
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
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item Search Field
                        TextFormField(
                          controller: itemSearchController,
                          focusNode: _itemFocusNode,
                          decoration:
                              _compactDecoration(
                                labelText: "Item Name (Search)",
                              ).copyWith(
                                suffixIcon: _isLoadingItems
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          height: 12,
                                          width: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      )
                                    : null,
                                prefixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.add_box_outlined,
                                    size: 20,
                                    color: Colors.green,
                                  ),
                                  onPressed: _addNewItemDialog,
                                  tooltip: 'Add New Item',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ),
                          onTap: () {
                            setState(() {
                              showItemList = true;
                            });
                          },
                        ),
                        const SizedBox(height: 10),

                        // Quantity and Rate/Price Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: quantity1Controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  final qty = double.tryParse(value);
                                  if (qty == null || qty <= 0) {
                                    return 'Min > 0';
                                  }
                                  return null;
                                },
                                decoration: _compactDecoration(
                                  labelText: "Quantity",
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: quantity2Controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
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
                        const SizedBox(height: 10),

                        // Discount and GST Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: DiscountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  final discount = double.tryParse(value ?? '');
                                  if (discount == null || discount < 0) {
                                    return 'Cannot be negative';
                                  }
                                  return null;
                                },
                                decoration: _compactDecoration(
                                  labelText: "Discount(%)",
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: GSTAmtController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  final gst = double.tryParse(value ?? '');
                                  if (gst == null || gst < 0) {
                                    return 'Cannot be negative';
                                  }
                                  return null;
                                },
                                decoration: _compactDecoration(
                                  labelText: "GST (%)",
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Add/Edit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addItem,
                            icon: Icon(
                              _isEditingItem ? Icons.save : Icons.add,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isEditingItem ? "Update Item" : "Add Item",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEditingItem
                                  ? Color(0xFF1E3A8A)
                                  : Color(0xFF1E3A8A),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Added Items List
                  _buildAddedItemsList(),

                  const SizedBox(height: 20),

                  // Save Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _saveEditsAndClose,
                      icon: const Icon(Icons.done_all, color: Colors.white),
                      label: const Text(
                        "Update Items",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),

            // --- Item Search Dropdown Overlay ---
            if (showItemList && filteredItems.isNotEmpty)
              Positioned(
                top: 50,
                left: 12,
                right: 12,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredItems.length,
                      // Now using the correctly defined _itemTile
                      itemBuilder: (context, index) {
                        return _itemTile(filteredItems[index]);
                      },
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
