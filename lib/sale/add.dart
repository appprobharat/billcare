import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/clients/add.dart';
import 'addsaleitems.dart';

class AddNewSalePage extends StatefulWidget {
  const AddNewSalePage({super.key});

  @override
  State<AddNewSalePage> createState() => _AddNewSalePageState();
}

class _AddNewSalePageState extends State<AddNewSalePage> {
  // --- State Variables ---
  late String _selectedDate;
  late final TextEditingController _dateController;
  final _customerController = TextEditingController();
  final _priceController = TextEditingController();
  final _receivedController = TextEditingController();
  final _remarkController = TextEditingController();
  Map<String, dynamic>? _billedItemsData;
  String? _selectedClientId;
  final FocusNode _customerFocusNode = FocusNode();
  String? _selectedReceiptMode;
  final List<String> _receiptModes = [
    "CASH",
    "NEFT",
    "IMPS",
    "RTGS",
    "PAYTM",
    "CHEQUE",
    "CARD",
    "DEMAND DRAFT(DD)",
    "OTHER",
  ];
  bool _isLoadingClients = true;
  List<dynamic> _allClients = [];
  List<dynamic> _filteredClients = [];
  bool _showClientList = false;
  bool _isReceived = false;
  double _balanceDue = 0.0;
  String? _authToken;
  final bool _allowClientSelection = true;
  bool _isLoading = false;
  static const _sharedPrefsKey = 'current_sale_items';

  @override
  void initState() {
    super.initState();

    _dateController = TextEditingController();
    _customerController.addListener(_filterClients);
    _priceController.addListener(_calculateBalance);
    _receivedController.addListener(_handleReceivedAmountChange);
    _customerFocusNode.addListener(_handleCustomerFocusChange);
    _initializePage();
  }

  @override
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_authToken != null) {
      _fetchClients(); // अब token null नहीं होगा
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _receivedController.dispose();
    _customerController.dispose();
    _dateController.dispose();
    _customerFocusNode.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  // --- INITIALIZATION FIX ---
  Future<void> _initializePage() async {
    await _loadAuthTokenAndClients();
    _selectedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _dateController.text = _selectedDate;
    await _clearBilledItemsFromPrefs();
    await _loadBilledItemsFromPrefs();
    _calculateBalance();
  }

  Future<void> _loadBilledItemsFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString(_sharedPrefsKey);

    if (itemsJson != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(itemsJson);
        final List<Map<String, dynamic>> newItemsList =
            List<Map<String, dynamic>>.from(data['items'] ?? []);

        if (newItemsList.isNotEmpty) {
          for (var item in newItemsList) {
            final price =
                double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
            final gst =
                double.tryParse(item['GSTAmt']?.toString() ?? '0.0') ?? 0.0;
            final discount =
                double.tryParse(item['Discount']?.toString() ?? '0.0') ?? 0.0;
            final itemLineTotal = (price + gst) - discount;
            item['total'] = itemLineTotal;
          }
          final Map<String, double> summaryTotals = _calculateSummaryTotals(
            newItemsList,
          );
          if (mounted) {
            setState(() {
              _billedItemsData = {
                'items': newItemsList,
                'total': summaryTotals['total'],
                'subtotal': summaryTotals['subtotal'],
                'Discount': summaryTotals['Discount'],
                'GSTAmt': summaryTotals['GSTAmt'],
              };
              _priceController.text = summaryTotals['total']!.toStringAsFixed(
                2,
              );
            });
          }
        } else {
          await _clearBilledItemsFromPrefs();
        }
      } catch (e) {
        print("❌ Failed to decode or load billed items from prefs: $e");
        await _clearBilledItemsFromPrefs();
      }
    } else {
      if (mounted) {
        setState(() {
          _priceController.text = '0.00';
          _billedItemsData = null;
        });
      }
    }
  }

  Future<void> _saveFormData() async {
    print("--- Save FormData Started ---");

    if (_customerController.text.trim().isEmpty ||
        _billedItemsData == null ||
        (_billedItemsData!['items'] as List).isEmpty) {
      print("DEBUG: Validation failed - Client or Items missing.");
      if (mounted) {
        _showSnackbar(
          "Please select a client and add at least one item.",
          Colors.red,
        );
      }
      return;
    }

    if (_selectedClientId == null) {
      final matchedClient = _allClients.firstWhere(
        (client) => client['Name']?.trim() == _customerController.text.trim(),
        orElse: () => null,
      );

      if (matchedClient != null) {
        _selectedClientId = matchedClient['id']?.toString();
        print("DEBUG: Client ID found by name match: $_selectedClientId");
      } else {
        print("DEBUG: Validation failed - Client ID is still null.");
        if (mounted) {
          _showSnackbar(
            "Please select a valid client from the list.",
            Colors.red,
          );
        }
        return;
      }
    } else {
      print("DEBUG: Selected Client ID: $_selectedClientId");
    }

    if (_isReceived && _selectedReceiptMode == null) {
      print(
        "DEBUG: Validation failed - Received checked but Receipt Mode missing.",
      );
      if (mounted) {
        _showSnackbar("Please choose the Receipt Mode.", Colors.red);
      }
      return;
    }

    // 2. Prepare API Data
    final saleItems = _billedItemsData!['items'] as List<dynamic>;

    final grandTotal = double.tryParse(_priceController.text) ?? 0.0;
    print("DEBUG: Grand Total: $grandTotal");

    if (grandTotal <= 0.0) {
      print("DEBUG: Validation failed - Grand Total is zero or negative.");
      if (mounted) {
        _showSnackbar(
          "The grand total of sales cannot be zero or negative. Add items first.",
          Colors.red,
        );
      }
      return;
    }

    final Map<String, dynamic> requestBody = {
      "Date": DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yyyy').parse(_selectedDate)),
      "ClientId": _selectedClientId,
      "GrandTotalAmt": grandTotal,
      "ItemId": saleItems.map((item) => item['id']).toList(),
      "Quantity": saleItems.map((item) => item['quantity']).toList(),
      "SalePrice": saleItems.map((item) => item['price']).toList(),
      "Discount": saleItems.map((item) => item['Discount']).toList(),
      "GSTAmt": saleItems.map((item) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final gstRate =
            double.tryParse(item['GSTRate']?.toString() ?? '0') ?? 0.0;
        final qty = double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0;
        return (price * qty * gstRate) / 100; // GST Amount
      }).toList(),

      "TotalAmt": saleItems.map((item) {
        final price = double.tryParse(item['price']?.toString() ?? '0') ?? 0.0;
        final qty = double.tryParse(item['quantity']?.toString() ?? '1') ?? 1.0;
        final gstRate =
            double.tryParse(item['GSTRate']?.toString() ?? '0') ?? 0.0;
        final discount =
            double.tryParse(item['Disc']?.toString() ?? '0') ?? 0.0;
        final gstAmt = (price * qty * gstRate) / 100;
        final discountAmt = (price * qty * discount) / 100;
        return (price * qty) + gstAmt - discountAmt;
      }).toList(),
      "IsReceived": _isReceived ? 1 : 0,
      "ReceiptAmt": _isReceived
          ? (double.tryParse(_receivedController.text) ?? 0.0)
          : 0.0,
      "ReceiptMode": _isReceived ? _selectedReceiptMode : null,
      "Remark": _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
    };

    setState(() {
      _isLoading = true;
    });
    print("DEBUG: Request Body Prepared: ${jsonEncode(requestBody)}");
    print("🧾 Final Sale Items to API:");
    for (int i = 0; i < saleItems.length; i++) {
      print({
        'ItemId': saleItems[i]['id'],
        'Qty': saleItems[i]['quantity'],
        'Price': saleItems[i]['price'],
        'GSTAmt':
            ((double.tryParse(saleItems[i]['price'].toString()) ?? 0.0) *
            (double.tryParse(saleItems[i]['quantity'].toString()) ?? 1.0) *
            (double.tryParse(saleItems[i]['GSTRate'].toString()) ?? 0.0) /
            100),
      });
    }

    // 4. API Call (Post New Sale)
    try {
      final newSaleData = await ApiService.postSaleData(
        requestBody,
       
      );

      print("DEBUG: API Response Received: $newSaleData");

      if (newSaleData != null &&
          newSaleData.containsKey('status') &&
          newSaleData['status'] == true) {
        // Check for the actual 'status: true'

        // Now execute the successful actions:
        await _clearBilledItemsFromPrefs();
        if (mounted) {
          _showSnackbar("Sale saved successfully! 🎉", Colors.green);
          Navigator.pop(context, true);
        }
      } else {
        // Handle unsuccessful status (e.g., status: false or missing status)
        if (mounted) {
          _showSnackbar(
            "Failed to save sale. Server response was invalid.",
            Colors.orange,
          );
        }
      }
    } catch (e) {
      print("DEBUG: Error caught during API call: $e");
      if (mounted) {
        _showSnackbar("Error while saving sale: $e", Colors.red);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    print("--- Save FormData Finished ---");
  }

  Future<void> _loadAuthTokenAndClients() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');

    if (_authToken != null) {
      await _fetchClients();
    } else {
      if (mounted) {
        setState(() => _isLoadingClients = false);
        _showSnackbar(
          "Authentication failed. Please log in again.",
          Colors.red,
        );
      }
    }
  }

  Future<void> _fetchClients() async {
    if (mounted) setState(() => _isLoadingClients = true);
    try {
      final clients = await ApiService.fetchClients();
      if (mounted) {
        setState(() {
          _allClients = clients;
          _filteredClients = _allClients;
          _isLoadingClients = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingClients = false);
        _showSnackbar("Failed to load clients. Please try again.", Colors.red);
      }
    }
  }

  void _showSnackbar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  Future<void> _saveBilledItemsToPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_billedItemsData != null) {
      final String itemsJson = jsonEncode(_billedItemsData);
      await prefs.setString(_sharedPrefsKey, itemsJson);
    } else {
      await prefs.remove(_sharedPrefsKey);
    }
  }

  Future<void> _clearBilledItemsFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sharedPrefsKey);

    if (mounted) {
      setState(() {
        _billedItemsData = null;
        _priceController.text = '0.00';
      });
    }
  }

  void _handleReceivedAmountChange() {
    if (_isReceived) {
      double total = double.tryParse(_priceController.text) ?? 0.0;
      double received = double.tryParse(_receivedController.text) ?? 0.0;
      if (received > total) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Invalid Amount"),
            content: const Text(
              "The amount received cannot exceed the total amount.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _receivedController.clear();
                  _calculateBalance();
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        _calculateBalance();
      }
    }
  }

  void _handleCustomerFocusChange() {
    if (_customerFocusNode.hasFocus) {
      setState(() {
        _filteredClients = _allClients;
        _showClientList = true;
      });
    }
  }

  void _calculateBalance() {
    double total = double.tryParse(_priceController.text) ?? 0.0;
    double received = _isReceived
        ? (double.tryParse(_receivedController.text) ?? 0.0)
        : 0.0;
    if (mounted) {
      setState(() {
        _balanceDue = total - received;
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime initialDate;
    try {
      initialDate = DateFormat('dd/MM/yyyy').parse(_selectedDate);
    } catch (e) {
      initialDate = DateTime.now();
    }
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('dd/MM/yyyy').format(picked);
        _dateController.text = _selectedDate;
      });
    }
  }

  void _filterClients() {
    final query = _customerController.text.toLowerCase();

    if (!_allowClientSelection) {
      setState(() => _showClientList = false);
      return;
    }

    if (query.isEmpty) {
      setState(() {
        _filteredClients = _allClients;
        _showClientList = true;
        _selectedClientId = null;
      });
      return;
    }

    setState(() {
      _showClientList = true;
      _filteredClients = _allClients
          .where(
            (client) =>
                (client['Name']?.toLowerCase().contains(query) ?? false) ||
                (client['ContactNo']?.toString().contains(query) ?? false) ||
                (client['State']?.toLowerCase().contains(query) ?? false) ||
                (client['Type']?.toLowerCase().contains(query) ?? false),
          )
          .toList();
      _selectedClientId = null;
    });
  }

  Widget _clientTile(Map<String, dynamic> client) {
    final String clientName = client['Name'] ?? 'N/A';
    final String clientMobile = client['ContactNo']?.toString() ?? 'N/A';
    final String clientState = client['State'] ?? 'N/A';
    final String type = client['Type'] ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        visualDensity: const VisualDensity(vertical: -4),
        title: Text(
          "$clientName | $clientMobile | $clientState ($type)",
          style: const TextStyle(fontSize: 14),
        ),
        onTap: () {
          _customerController.text = client['Name'] ?? '';
          setState(() {
            _showClientList = false;
            _selectedClientId = client['id'].toString();
          });
          _customerFocusNode.unfocus();
        },
      ),
    );
  }

  Map<String, double> _calculateSummaryTotals(
    List<Map<String, dynamic>> items,
  ) {
    double total = 0.0;
    double totalSubtotal = 0.0;
    double totalDiscount = 0.0;
    double totalGstAmt = 0.0;
    for (var item in items) {
      final double itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
      final double itemQuantity = (item['quantity'] as num?)?.toDouble() ?? 0.0;
      final double gstAmt = (item['GSTAmt'] as num?)?.toDouble() ?? 0.0;
      final double discount = (item['Discount'] as num?)?.toDouble() ?? 0.0;
      final double subtotal = itemPrice * itemQuantity;
      totalSubtotal += subtotal;
      totalGstAmt += gstAmt;
      totalDiscount += discount;
      total += subtotal + gstAmt - totalDiscount;
    }

    return {
      'total': total,
      'subtotal': totalSubtotal,
      'Discount': totalDiscount,
      'GSTAmt': totalGstAmt,
    };
  }

  Future<void> _navigateToAddItems() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddSaleItemsPage(
          initialItems: _billedItemsData != null
              ? List<Map<String, dynamic>>.from(_billedItemsData!['items'])
              : [],
          pageTitle: "Add Items to Sale",
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final List<Map<String, dynamic>> newItemsList =
          List<Map<String, dynamic>>.from(result['items'] ?? []);

      final Map<String, double> summaryTotals = _calculateSummaryTotals(
        newItemsList,
      );
      if (mounted) {
        setState(() {
          _billedItemsData = {
            'items': newItemsList,
            'total': summaryTotals['total'],
            'subtotal': summaryTotals['subtotal'],
            'Discount': summaryTotals['Discount'],
            'GSTAmt': summaryTotals['GSTAmt'],
          };
          final double calculatedTotal = summaryTotals['total']!;
          _priceController.text = calculatedTotal.toStringAsFixed(1);
        });
      }
      await _saveBilledItemsToPrefs();
      _calculateBalance();
    }
  }

  Widget _buildBilledItemsCard() {
    if (_billedItemsData == null ||
        (_billedItemsData!['items'] as List).isEmpty) {
      return const SizedBox.shrink();
    }
    final subtotal = (_billedItemsData!['subtotal'] as num?)?.toDouble() ?? 0.0;
    final discount = (_billedItemsData!['Discount'] as num?)?.toDouble() ?? 0.0;
    final gst = (_billedItemsData!['GSTAmt'] as num?)?.toDouble() ?? 0.0;
    final total = (_billedItemsData!['total'] as num?)?.toDouble() ?? 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Billed Items",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  _selectedDate,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),

            // --- Item List ---
            ...List.generate((_billedItemsData!['items'] as List).length, (
              index,
            ) {
              var item = _billedItemsData!['items'][index];
              final itemPrice = (item['price'] as num?)?.toDouble() ?? 0.0;
              final itemQuantity =
                  (item['quantity'] as num?)?.toDouble() ?? 0.0;
              final itemGSTAmt = (item['GSTRate'] as num?)?.toDouble() ?? 0;
              final itemDiscount = (item['Disc'] as num?)?.toDouble() ?? 0;
              final itemTotal =
                  (itemPrice * itemQuantity) + itemGSTAmt - itemDiscount;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "₹${itemTotal.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Rate: ₹${itemPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "Qty: ${itemQuantity.toString()}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Discount: ${itemDiscount.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        "GST: ${itemGSTAmt.toStringAsFixed(0)}%",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 4),
                ],
              );
            }),
            _buildSummaryRowone(
              subtotal: subtotal,
              discount: discount,
              gst: gst,
              total: total,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRowone({
    required double subtotal,
    required double discount,
    required double gst,
    required double total,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "Subtotal",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  "Discount",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  "GST",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: Text(
                  "Total",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Value row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  "₹${subtotal.toStringAsFixed(1)}",
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  "₹${discount.toStringAsFixed(1)}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
              ),
              Expanded(
                child: Text(
                  "₹${gst.toStringAsFixed(1)}",
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  "₹${total.toStringAsFixed(1)}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "₹ $value",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // --- Main Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Sale", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddClientPage()),
              ).then((result) async {
                if (result == true) {
                  print(
                    "Triggering FETCH after returning from AddClientPage...",
                  );
                  await _fetchClients();
                }
                print("DEBUG: Page Returned With --> $result");
              });
            },
            icon: const Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            if (mounted) {
              setState(() {
                _showClientList = false;
              });
            }
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Date Field
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: _dateController,
                            onTap: _pickDate,
                            decoration: const InputDecoration(
                              labelText: "Date",
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _customerController,
                      focusNode: _customerFocusNode,
                      autofocus: false,
                      enabled: _allowClientSelection,
                      decoration: InputDecoration(
                        labelText: "Client Name | Mobile | State (Search)",
                        isDense: true,
                        border: const OutlineInputBorder(),
                        suffixIcon: _isLoadingClients
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : null,
                      ),
                    ),
                    // Add Items Button
                    OutlinedButton.icon(
                      onPressed: _navigateToAddItems,
                      icon: const Icon(Icons.add),
                      label: const Text("Add Items"),
                    ),

                    // Billed Items Card
                    _buildBilledItemsCard(),

                    const SizedBox(height: 10),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryRow(
                                  "Total Amount",
                                  _priceController.text,
                                  isBold: true,
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: _isReceived,
                                      onChanged: (val) {
                                        setState(() {
                                          _isReceived = val!;
                                          if (!_isReceived) {
                                            _receivedController.clear();
                                            _selectedReceiptMode = null;
                                            _remarkController.clear();
                                          } else {
                                            if (_receivedController
                                                    .text
                                                    .isEmpty ||
                                                _receivedController.text ==
                                                    '0.00') {
                                              _receivedController.text =
                                                  _priceController.text;
                                            }
                                          }
                                        });
                                        _calculateBalance();
                                      },
                                    ),
                                    const Text(
                                      "Received",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                if (_isReceived)
                                  SizedBox(
                                    width: 100,
                                    child: TextFormField(
                                      controller: _receivedController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      decoration: const InputDecoration(
                                        labelText: "Amount",
                                        prefixText: '₹ ',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 8,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_isReceived) ...[
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: "Receipt Mode",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                value: _selectedReceiptMode,
                                hint: const Text("Select Payment Method"),
                                items: _receiptModes.map((String mode) {
                                  return DropdownMenuItem<String>(
                                    value: mode,
                                    child: Text(mode),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedReceiptMode = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),

                              TextFormField(
                                controller: _remarkController,
                                decoration: const InputDecoration(
                                  labelText: "Remark (Optional)",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],

                            // Balance Due
                            _buildSummaryRow(
                              "Balance Due",
                              _balanceDue.toStringAsFixed(2),
                              isBold: true,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      // बटन और लोडर को केन्द्रित करने के लिए `Center` विजेट का उपयोग करें यदि लोडर बटन से छोटा है
                      child: Center(
                        child:
                            _isLoading // यह जाँच करें कि लोडिंग चल रही है या नहीं
                            ? const Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: 15,
                                ), // ElevatedButton के समान पैडिंग रखें
                                child: SizedBox(
                                  height: 24, // लोडर का आकार
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3.0, // लोडर की मोटाई
                                  ),
                                ),
                              )
                            : ElevatedButton.icon(
                                onPressed: _saveFormData,
                                icon: const Icon(Icons.save),
                                label: const Text("Save"),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),

              // Client List Overlay
              if (_showClientList && _filteredClients.isNotEmpty)
                Positioned(
                  top: 130,
                  left: 16,
                  right: 16,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredClients.length,
                      itemBuilder: (context, index) {
                        return _clientTile(_filteredClients[index]);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
