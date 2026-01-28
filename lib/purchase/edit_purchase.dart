import 'dart:convert';
import 'package:billcare/purchase/editpurchaseitem.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:billcare/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditPurchasePage extends StatefulWidget {
  final int purchaseId;

  const EditPurchasePage({super.key, required this.purchaseId});

  @override
  State<EditPurchasePage> createState() => _EditPurchasePageState();
}

class _EditPurchasePageState extends State<EditPurchasePage> {
  // --- State Variables ---
  late String _selectedDate;
  late final TextEditingController _dateController;
  final _customerController = TextEditingController();
  final _remarkController = TextEditingController();
  double _grandTotalAmt = 0.0;
  double _PaymentAmt = 0.0;

  Map<String, dynamic>? _billedItemsData;
  String? _selectedClientId;
  final FocusNode _customerFocusNode = FocusNode();
  String? _selectedPaymentMode;

  bool _isLoadingClients = true;
  List<dynamic> _allClients = [];
  List<dynamic> _filteredClients = [];
  bool _showClientList = false;
  bool _isReceived = false;
  bool _isUpdating = false;
  static const _sharedPrefsKey = 'current_purchase_items';

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _customerController.addListener(_filterClients);
    _customerFocusNode.addListener(_handleCustomerFocusChange);
    _initializePage();
  }

  @override
  void dispose() {
    // CLEANUP 1: Disposed the removed controllers
    _customerController.dispose();
    _dateController.dispose();
    _customerFocusNode.dispose();
    _remarkController.dispose();
    super.dispose();
  }

Future<void> _initializePage() async {
  await _fetchClients(); // 🔥 MISSING CALL

  _selectedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
  _dateController.text = _selectedDate;

  await _fetchPurchaseDataForEdit(widget.purchaseId);
}


  // --- API and Data Handling ---

 Future<void> _fetchPurchaseDataForEdit(int purchaseId) async {
  try {
    await _clearBilledItemsFromPrefs();

    final purchaseData =
        await ApiService.fetchPurchaseForEdit(purchaseId);

    print("🟢 DEBUG: Raw purchase data => $purchaseData");

    if (mounted && purchaseData != null) {
      _populateFormData(purchaseData);
    } else if (mounted) {
      _showSnackbar(
        "Failed to load purchase data for ID: $purchaseId",
        Colors.red,
      );
      Navigator.pop(context);
    }
  } catch (e) {
    if (mounted) {
      _showSnackbar("Error loading purchase: $e", Colors.red);
    }
  }
}

  void _populateFormData(Map<String, dynamic> data) {
    print("🟡 DEBUG: Populating form with data => ${jsonEncode(data)}");
    Map<String, dynamic> tempBilledItemsData = {};

    // 1. Parse Items
    if (data.containsKey('items') && data['items'] is List) {
      final List<dynamic> itemsData = data['items'];
      print("🟢 DEBUG: Received ${itemsData.length} items => $itemsData");
      final List<Map<String, dynamic>> parsedItems = itemsData.map((item) {
        double safeParse(dynamic value) {
          if (value == null) return 0.0;
          return double.tryParse(value.toString()) ?? 0.0;
        }
        return {
          'id': item['ItemId'],
          'name': item['ItemName'] ?? 'Unknown Item',
          'quantity': safeParse(item['Quantity']),
          'price': safeParse(item['PurchasePrice']),
          'subtotal':
              safeParse(item['PurchasePrice']) * safeParse(item['Quantity']),
          'GSTAmt': safeParse(item['GSTAmt']),
          'Discount': safeParse(item['Discount']),
          'total': safeParse(item['TotalAmt']),
        };
      }).toList();

      final Map<String, double> summaryTotals = _calculateSummaryTotals(
        parsedItems,
      );
      tempBilledItemsData = {
        'subtotal': summaryTotals['subtotal'],
        'Discount': summaryTotals['Discount'],
        'GSTAmt': summaryTotals['GSTAmt'],
        'total': summaryTotals['total'],
        'items': parsedItems,
      };
    }

    // 2. Find Client
    final client = _allClients.firstWhere(
      (c) => c['id']?.toString() == data['ClientId']?.toString(),
      orElse: () => null,
    );

    double grandTotalAmt =
        double.tryParse(data['GrandTotalAmt']?.toString() ?? '0.0') ?? 0.0;
    double PaymentAmt =
        double.tryParse(data['PaymentAmt']?.toString() ?? '0.0') ?? 0.0;
    int isReceivedInt = int.tryParse(data['IsPaid']?.toString() ?? '0') ?? 0;

    // 3. Set State
    if (mounted) {
      setState(() {
        // Date
        try {
          String dateString =
              data['Date']?.toString() ??
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          DateTime dateParsed;
          if (dateString.contains('-')) {
            dateParsed = DateFormat('yyyy-MM-dd').parse(dateString);
          } else if (dateString.contains('/')) {
            dateParsed = DateFormat('dd/MM/yyyy').parse(dateString);
          } else {
            dateParsed = DateTime.now();
          }
          _selectedDate = DateFormat('dd/MM/yyyy').format(dateParsed);
        } catch (_) {
          _selectedDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
        }
        _dateController.text = _selectedDate;

        // Client
        _customerController.text =
            client?['Name'] ?? (data['ClientName'] ?? 'N/A');
        _selectedClientId = data['ClientId']?.toString();
        // MODIFICATION 1: Hide dropdown when loading a selected client
        _showClientList = false;

        // Billed Items & Total
        _billedItemsData = tempBilledItemsData;

        // CLEANUP 1: Update state variables instead of controllers
        _grandTotalAmt = grandTotalAmt;

        // Payment Details (Retain values for API call)
        _isReceived = isReceivedInt == 1;
        _PaymentAmt = PaymentAmt; // CLEANUP 1: Update state variable
        _selectedPaymentMode = data['PaymentMode'] as String?;
        _remarkController.text = data['Remark'] as String? ?? '';
      });
    }
    print(
      "✅ DEBUG: Form populated => "
      "Date=$_selectedDate | "
      "Client=$_selectedClientId | "
      "Total=$_grandTotalAmt | "
      "PaymentAmt=$_PaymentAmt | "
      "ItemsCount=${_billedItemsData?['items']?.length ?? 0}",
    );

    _saveBilledItemsToPrefs();
  }

  Future<void> _saveFormData() async {
    // 1. Validation
    if (_customerController.text.trim().isEmpty ||
        _billedItemsData == null ||
        (_billedItemsData!['items'] as List).isEmpty) {
      if (mounted) {
        _showSnackbar(
          "Please ensure a client is selected and at least one item is added.",
          Colors.red,
        );
      }
      return;
    }
    // Check if the current text in the customer controller matches a selected client
    if (_selectedClientId == null) {
      if (mounted) {
        _showSnackbar(
          "Please select a valid client from the dropdown list.",
          Colors.red,
        );
      }
      return;
    }

    // 2. Prepare API Data
    final purchaseItems = _billedItemsData!['items'] as List<dynamic>;

    for (var item in purchaseItems) {
      if (item['total'] == null) {
        _showSnackbar(
          "Item total calculation error. Please re-edit items.",
          Colors.red,
        );
        return;
      }
    }

    // Use the stored receipt amount
    double finalPaymentAmt = _PaymentAmt;

    final Map<String, dynamic> requestBody = {
      "PurchaseId": widget.purchaseId,
      "Date": DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd/MM/yyyy').parse(_selectedDate)),
      "ClientId": _selectedClientId,
      "GrandTotalAmt": _billedItemsData!['total'],
      "ItemId": purchaseItems.map((item) => item['id']).toList(),
      "Quantity": purchaseItems.map((item) => item['quantity']).toList(),
      "PurchasePrice": purchaseItems.map((item) => item['price']).toList(),
      "Discount": purchaseItems.map((item) => item['Discount']).toList(),
      "GSTAmt": purchaseItems.map((item) => item['GSTAmt']).toList(),
      "TotalAmt": purchaseItems.map((item) => item['total']).toList(),
      // Retain original received status for API if it's not being modified in the UI
      "IsPaid": _isReceived ? 1 : 0,
      "PaymentAmt": finalPaymentAmt,
      "PaymentMode": _selectedPaymentMode,
      "Remark": _remarkController.text.trim().isEmpty
          ? null
          : _remarkController.text.trim(),
    };
    setState(() {
      _isUpdating = true;
    });
    // 3. API Call (Update Purchase)
    try {final success = await ApiService.updatePurchase(requestBody);

      if (success) {
        await _clearBilledItemsFromPrefs();
        if (mounted) {
          _showSnackbar("Purchase updated successfully! 🎉", Colors.green);
          Navigator.pop(context, true); // Return 'true' to indicate success
        }
      } else {
        if (mounted) {
          setState(() {
            _isUpdating = false;
          });
          _showSnackbar(
            "Failed to update purchase. Server response indicated failure.",
            Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        _showSnackbar("Error updating purchase: $e", Colors.red);
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

  // --- UI and Utility Helpers ---

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
  }

  void _handleCustomerFocusChange() {
    if (!_customerFocusNode.hasFocus) {
      // Delay to allow onTap of list item to register before hiding list
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _showClientList = false;
          });
        }
      });
    } else {
     
      if (_customerController.text.isEmpty) {
        setState(() {
          _filteredClients = _allClients;
          _showClientList = true;
        });
      } else {
        // If text is present, call filter to show list immediately
        _filterClients();
      }
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

  Map<String, double> _calculateSummaryTotals(
    List<Map<String, dynamic>> items,
  ) {
    double total = 0.0;
    double totalSubtotal = 0.0;
    double totalDiscount = 0.0;
    double totalGstAmt = 0.0;

    for (var item in items) {
      final double itemPrice =
          double.tryParse(item['price']?.toString() ?? '0.0') ?? 0.0;
      final double itemQuantity =
          double.tryParse(item['quantity']?.toString() ?? '0.0') ?? 0.0;
      final double gstAmt =
          double.tryParse(item['GSTAmt']?.toString() ?? '0.0') ?? 0.0;
      final double discount =
          double.tryParse(item['Discount']?.toString() ?? '0.0') ?? 0.0;

      final double subtotal = itemPrice * itemQuantity;

      totalSubtotal += subtotal;
      totalGstAmt += gstAmt;
      totalDiscount += discount;
      total += (subtotal + gstAmt - discount);
    }

    return {
      'total': total,
      'subtotal': totalSubtotal,
      'Discount': totalDiscount,
      'GSTAmt': totalGstAmt,
    };
  }

  Future<void> _navigateToEditItems() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditPurchaseItemsPage(
          initialItems: _billedItemsData != null
              ? List<Map<String, dynamic>>.from(_billedItemsData!['items'])
              : [],
          pageTitle: "Edit Purchase Items",
          purchaseId: widget.purchaseId,
        ),
      ),
    );

    // This block handles the result returned from EditPurchaseItemsPage
    if (result != null && result is Map<String, dynamic>) {
      final List<Map<String, dynamic>> newItemsList =
          List<Map<String, dynamic>>.from(result['items'] ?? []);

      final Map<String, double> summaryTotals = _calculateSummaryTotals(
        newItemsList,
      );
      print("🧮 DEBUG: Summary totals => $summaryTotals");
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

          // CLEANUP 1: Update state variable
          _grandTotalAmt = calculatedTotal;

          // Logic to update received amount if required
          if (_isReceived && _PaymentAmt > calculatedTotal) {
            _PaymentAmt = calculatedTotal;
          } else if (_isReceived &&
              _PaymentAmt == 0.0 &&
              calculatedTotal > 0.0) {
            // Set to total if it was previously 0.0 and it's still marked as received
            _PaymentAmt = calculatedTotal;
          }
        });
      }

      await _saveBilledItemsToPrefs();
    }
  }

  void _filterClients() {
    final query = _customerController.text.toLowerCase();

    // 1. If the user clears the text field, clear the selected ID
    if (query.isEmpty) {
      setState(() {
        _filteredClients = _allClients;
        // MODIFICATION 1: Show dropdown only when empty/typing
        _showClientList = true;
        _selectedClientId = null;
      });
      return;
    }

    // 2. Filter and show list
    setState(() {
      // MODIFICATION 1: Show dropdown when user is typing/filtering
      _showClientList = true;
      _filteredClients = _allClients
          .where(
            (client) =>
                (client['Name']?.toLowerCase().contains(query) ?? false) ||
                (client['ContactNo']?.toString().contains(query) ?? false) ||
                (client['State']?.toLowerCase().contains(query) ?? false),
          )
          .toList();

      // ✅ LOGIC REFINEMENT: Only clear ID if the entered text does NOT exactly match the name of the currently selected client.
      final currentClientName = _allClients
          .firstWhere(
            (c) => c['id']?.toString() == _selectedClientId,
            orElse: () => null,
          )?['Name']
          ?.toLowerCase();

      if (currentClientName == null ||
          query.toLowerCase() != currentClientName) {
        _selectedClientId = null;
      }
    });
  }

  Widget _clientTile(Map<String, dynamic> client) {
    return ListTile(
      title: Text(
        "${client['Name']} | Mob: ${client['ContactNo'] ?? 'N/A'} | ${client['State'] ?? 'N/A'}",
        style: const TextStyle(fontSize: 14),
      ),
      onTap: () {
        _customerController.text = client['Name'] ?? '';
        setState(() {
          // MODIFICATION 1: Hide dropdown after selection
          _showClientList = false;
          _selectedClientId = client['id'].toString();
        });
        _customerFocusNode.unfocus();
      },
    );
  }

  Widget _buildBilledItemsCard() {
    if (_billedItemsData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<Map<String, dynamic>> items = _billedItemsData!['items'];
    final double subtotal = _billedItemsData!['subtotal'];
    final double discount = _billedItemsData!['Discount'];
    final double gst = _billedItemsData!['GSTAmt'];
    final double total = _billedItemsData!['total'];

    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title + Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Billed Items",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  _selectedDate,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
                ),
              ],
            ),

            // Item List
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            "${item['name']} | ${item['quantity'].toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Text(
                          "₹${item['total'].toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Rate: ₹${(item['price'] ?? 0.0).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Qty: ${item['quantity'] ?? 0}",
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
                          "Discount: ₹${(item['Discount'] ?? 0.0).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "GST: ₹${(item['GSTAmt'] ?? 0.0).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _summaryColumn("Subtotal", subtotal),
                  _summaryColumn("Discount", discount, color: Colors.red),
                  _summaryColumn("GST", gst),
                  _summaryColumn(
                    "Total",
                    total,
                    isBold: true,
                    // ✅ BEST PRACTICE: Use colorScheme for primary brand color
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),

            // Grand Total Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Grand Total",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "₹${total.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    // ✅ BEST PRACTICE: Use colorScheme for primary brand color
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for horizontal summary
  Widget _summaryColumn(
    String title,
    double value, {
    bool isBold = false,
    Color color = Colors.black87,
  }) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "₹${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Purchase",
          style: TextStyle(color: Colors.white),
        ),
        // ✅ BEST PRACTICE: Use colorScheme
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard and dropdown on tap outside
            _customerFocusNode.unfocus();
            setState(() {
              _showClientList = false;
            });
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // --- Date Field ---
                    TextFormField(
                      readOnly: true,
                      controller: _dateController,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: "Date",
                        border: OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // --- Client Search Field ---
                    TextFormField(
                      controller: _customerController,
                      focusNode: _customerFocusNode,
                      autofocus: false,
                      decoration: InputDecoration(
                        labelText: "Client Name / Mobile / State",
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
                        prefixIcon: const Icon(Icons.person),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Edit Items Button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _navigateToEditItems,
                        icon: const Icon(Icons.edit, color: Colors.white),
                        label: const Text(
                          "Edit Items",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          // ✅ BEST PRACTICE: Use colorScheme for secondary color
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // --- Billed Items Summary ---
                    _buildBilledItemsCard(),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        // 1. 'ElevatedButton.icon' se 'ElevatedButton' mein badlein

                        // 2. Loading ke dauraan button ko disable karein
                        onPressed: _isUpdating ? null : _saveFormData,

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

                        // 3. Child ko state ke anusaar badlein (Loader ya Text)
                        child: _isUpdating
                            // JAB LOADING HO RAHI HO (Loader)
                            ? Container(
                                width: 24, // Loader ka size set karein
                                height: 24,
                                child: const CircularProgressIndicator(
                                  color: Colors.white, // Loader ka rang
                                  strokeWidth: 3,
                                ),
                              )
                            // JAB LOADING NAHI HO RAHI HO (Icon aur Text)
                            : Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Content ko center mein rakhein
                                children: const [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                                  SizedBox(
                                    width: 8,
                                  ), // Icon aur text ke beech space
                                  Text(
                                    "Update Purchase",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),

              // --- Client Dropdown Overlay ---
              if (_showClientList && _filteredClients.isNotEmpty)
                Positioned(
                  top: 140, // Position aligned with the TextFormField
                  left: 16,
                  right: 16,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: ListView.builder(
                        // Add a key to prevent errors when items change rapidly
                        key: ValueKey(_customerController.text),
                        shrinkWrap: true,
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          return _clientTile(_filteredClients[index]);
                        },
                      ),
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
