import 'dart:async';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/purchase/edit_purchase.dart';
import 'package:billcare/purchase/pdf_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:billcare/purchase/add.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class ClientData {
  final String id;
  final String name;
  final String contact;
  final String refNo;
  final String date;
  final String amount;

  const ClientData({
    required this.id,
    required this.name,
    required this.contact,
    required this.refNo,
    required this.date,
    required this.amount,
  });

  factory ClientData.fromJson(Map<String, dynamic> json) {
    return ClientData(
      id: json['id']?.toString() ?? '',
      name: json['Name'] as String? ?? 'N/A',
      contact: json['ContactNo']?.toString() ?? 'N/A',
      refNo: json['RefNo']?.toString() ?? 'N/A',
      amount: json['Amount']?.toString() ?? '0',
      date: json['Date']?.toString() ?? 'N/A',
    );
  }
}

class PurchaseManagePage extends StatefulWidget {
  const PurchaseManagePage({super.key});

  @override
  State<PurchaseManagePage> createState() => _PurchaseManagePageState();
}

class _PurchaseManagePageState extends State<PurchaseManagePage> {
  // --- Controllers & State Variables ---
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController clientController = TextEditingController();
  final FocusNode _clientFocusNode = FocusNode();

  List<dynamic> _purchasesList = [];
  List<dynamic> _filteredPurchasesList = [];

  bool _isLoading = false;
  String? _authToken;

  // --- Lifecycle & Initialization ---

  @override
  void initState() {
    super.initState();
    _setDefaultDateRange();
    _loadAuthTokenAndClients();
  }

  @override
  void dispose() {
    fromDateController.dispose();
    toDateController.dispose();
    clientController.dispose();
    _clientFocusNode.dispose();
    super.dispose();
  }

  void _setDefaultDateRange() {
    final now = DateTime.now();
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

    fromDateController.text = DateFormat('dd-MM-yyyy').format(oneMonthAgo);
    toDateController.text = DateFormat('dd-MM-yyyy').format(now);
  }

  // --- API & Data Handling ---

  Future<void> _loadAuthTokenAndClients() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('authToken');

    if (_authToken == null) {
      if (mounted) {
        _showSnackbar("Authentication token is missing.", Colors.red);
      }
      setState(() => _isLoading = false);
      return;
    }
    try {
      await _searchPurchases(shouldClearClientFilter: false);
    } catch (e) {
      if (mounted) _showSnackbar('Error fetching clients: $e', Colors.red);
      await _searchPurchases(shouldClearClientFilter: false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _searchPurchases({bool shouldClearClientFilter = true}) async {
    if (_authToken == null || _authToken!.isEmpty) {
      if (mounted) _showSnackbar("Authentication failed.", Colors.red);
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _purchasesList = [];
      _filteredPurchasesList = [];
      if (shouldClearClientFilter) clientController.clear();
    });

    try {
      // Date conversion: dd-MM-yyyy to yyyy-MM-dd
      final fromDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(fromDateController.text));
      final toDate = DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(toDateController.text));

      final Map<String, dynamic> requestBody = {'from': fromDate, 'to': toDate};

      final List<dynamic> fetchedPurchases = await ApiService.fetchPurchases(
        _authToken!,
        requestBody,
      );
      if (mounted) {
        fetchedPurchases.sort((a, b) {
          final refA = int.tryParse(a['RefNo'].toString()) ?? 0;
          final refB = int.tryParse(b['RefNo'].toString()) ?? 0;
          return refB.compareTo(refA);
        });

        setState(() {
          _purchasesList = fetchedPurchases;
          _filteredPurchasesList = List.from(fetchedPurchases);
        });
      }
    } catch (e) {
      final message = e.toString().contains('Unauthenticated')
          ? "Session expired. Please log in again."
          : 'Error fetching purchases data: $e';
      if (mounted) _showSnackbar(message, Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Navigation & UI Actions ---

  void _navigateToAddPurchasePage() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddNewPurchasePage()));
    if (result == true) _searchPurchases();
  }

  // --- Filtering & Utility ---

  String _formatName(String name) {
    if (name.isEmpty || name == 'N/A') return 'N/A';
    return name[0].toUpperCase() + name.substring(1);
  }

  void _onClientFilterChanged(String query) {
    final input = query.toLowerCase().trim();
    if (input.isEmpty) {
      setState(() => _filteredPurchasesList = List.from(_purchasesList));
      return;
    }

    final filteredList = _purchasesList.where((purchase) {
      final name = (purchase['Name'] as String? ?? '').toLowerCase();
      final contact = (purchase['ContactNo']?.toString() ?? '').toLowerCase();
      return name.contains(input) || contact.contains(input);
    }).toList();

    setState(() => _filteredPurchasesList = filteredList);
  }

  void _showSnackbar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // --- PDF & Share Functions ---

  Future<void> _printDocument(Map<String, dynamic> purchase) async {
    if (_authToken == null || _authToken!.isEmpty) {
      _showSnackbar("Authentication failed.", Colors.red);
      return;
    }
    try {
      if (mounted) setState(() => _isLoading = true);
      // Assuming PdfService handles API call and printing logic
      await PdfService.printDocument(
        authToken: _authToken!,
        purchase: purchase,
      );
      _showSnackbar('PDF sent to printer/download successfully!', Colors.green);
    } catch (e) {
      _showSnackbar('Error generating PDF: $e', Colors.red);
      print('Error generating PDF: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sharePurchasePdf(Map<String, dynamic> purchase) async {
    if (_authToken == null || _authToken!.isEmpty) {
      _showSnackbar("Authentication failed.", Colors.red);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Generating and saving PDF for ${purchase['RefNo'] ?? 'Purchase'}...',
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    // Set loading state to prevent multiple clicks
    if (mounted) setState(() => _isLoading = true);

    try {
      final String filePath = await PdfService.generateAndSavePdf(
        authToken: _authToken!,
        purchase: purchase,
      );

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (filePath.isNotEmpty) {
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'Invoice: ${purchase['RefNo'] ?? 'N/A'}',
          text: 'Please find the purchase invoice attached.',
        );
        _showSnackbar('Invoice shared successfully!', Colors.green);
      } else {
        _showSnackbar(
          'Failed to generate or save PDF for sharing.',
          Colors.red,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnackbar('Error sharing PDF: $e', Colors.red);
      print('Error sharing PDF: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI Widgets Extraction ---

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,

      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateFormat('dd-MM-yyyy').parse(controller.text),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          setState(() {
            controller.text = DateFormat('dd-MM-yyyy').format(picked);
          });
        }
      },
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        isDense: true,

        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 20,
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: 48,
      height: 40,
      child: ElevatedButton(
        onPressed: _searchPurchases,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          minimumSize: const Size(48, 48),
        ),
        child: const Icon(Icons.search, size: 20),
      ),
    );
  }

  Widget _buildClientFilterField() {
    return TextField(
      controller: clientController,
      focusNode: _clientFocusNode,
      decoration: InputDecoration(
        hintText: "Search by client name or mobile no.",
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: IconButton(
          icon: const Icon(Icons.clear, size: 20),
          onPressed: () {
            clientController.clear();
            _onClientFilterChanged('');
            _clientFocusNode.unfocus();
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 10.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[200],
      ),
      onChanged: _onClientFilterChanged,
    );
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text("Purchases Manage")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildDateField("From Date", fromDateController),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: _buildDateField("To Date", toDateController),
                      ),
                      const SizedBox(width: 8),
                      _buildSearchButton(),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_purchasesList.isNotEmpty) _buildClientFilterField(),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildPurchasesList()),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GestureDetector(
              onTap: () => _navigateToAddPurchasePage(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Purchase',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPurchasesList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_purchasesList.isEmpty) {
      return const Center(
        child: Text("No purchases found for the selected criteria."),
      );
    } else if (_filteredPurchasesList.isEmpty) {
      return Center(
        child: Text("No results match '${clientController.text}'."),
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _filteredPurchasesList.length,
        itemBuilder: (context, index) {
          final purchase = _filteredPurchasesList[index];
          final String gstNo = purchase['GSTNo'] ?? 'N/A';
          final String name = _formatName(purchase['Name'] ?? 'N/A');

          return GestureDetector(
            onTap: () async {
              final int? purchaseId = purchase['id'];
              if (purchaseId != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditPurchasePage(purchaseId: purchaseId),
                  ),
                );
                if (result == true) _searchPurchases();
              }
            },
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(7.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Name and Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          purchase['Date'] ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Row 2: Contact, Ref
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.call,
                              size: 12,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${purchase['ContactNo']?.toString()}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "Ref: ${purchase['RefNo'] ?? 'N/A'}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Row 3: GST No & Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    size: 12,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    gstNo,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Amount: ₹ ${purchase['Amount'] ?? '0'}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // PDF Icon (Print/Download)
                            IconButton(
                              onPressed: () => _printDocument(purchase),
                              icon: const Icon(
                                Icons.picture_as_pdf,
                                size: 20,
                                color: Colors.red,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: 'Generate PDF',
                              constraints: BoxConstraints.tight(
                                const Size(32, 32),
                              ),
                            ),
                            // Share Icon (Share PDF)
                            IconButton(
                              onPressed: () => _sharePurchasePdf(purchase),
                              icon: const Icon(
                                Icons.share,
                                size: 20,
                                color: Colors.blueGrey,
                              ),
                              padding: EdgeInsets.zero,
                              tooltip: 'Share Invoice PDF',
                              constraints: BoxConstraints.tight(
                                const Size(32, 32),
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
          );
        },
      );
    }
  }
}
