import 'dart:convert';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/receipt/add.dart';
import 'package:billcare/receipt/receipt_pdf.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


class ManageReceiptPage extends StatefulWidget {
  const ManageReceiptPage({super.key});
  @override
  State<ManageReceiptPage> createState() => _ManageReceiptPageState();
}

class _ManageReceiptPageState extends State<ManageReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  // *** NEW: Global Key for custom dropdown position ***
  final GlobalKey _typeFieldKey = GlobalKey();

  List<Map<String, dynamic>> _receipts = [];
  List<Map<String, dynamic>> _filteredReceipts = [];
  bool _isLoading = true;
  String selectedType = "Party";
  final List<String> _types = ["Party", "Supplier", "Employee"];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final oneMonthAgo = today.subtract(const Duration(days: 30));
    fromDateController.text = DateFormat('dd-MM-yyyy').format(oneMonthAgo);
    toDateController.text = DateFormat('dd-MM-yyyy').format(today);
    _fetchReceipts();
  }
Future<String?> _getToken() async {
  final token = await AuthStorage.getToken();

  if (token == null || token.isEmpty) {
    if (!mounted) return null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Session expired. Please login again."),
      ),
    );

    Navigator.pop(context);
    return null;
  }

  return token;
}


  Future<void> _fetchReceipts() async {
    if (!_isLoading) {
      setState(() => _isLoading = true);
    }

    final token = await _getToken();
    if (token == null) {
      setState(() => _isLoading = false);
      return;
    }

    if (fromDateController.text.isEmpty || toDateController.text.isEmpty) {
      print("⚠️ Date fields are empty.");
      setState(() => _isLoading = false);
      return;
    }

    final url = Uri.parse("https://gst.billcare.in/api/receipt/list");

    // ✅ Format dates properly
    final body = {
      "from": DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(fromDateController.text)),
      "to": DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(toDateController.text)),
      "type": selectedType,
    };

    print("📡 Fetching Receipts: $body");

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: body,
      );

      print("📩 Status: ${res.statusCode}");
      print("📦 Response: ${res.body}");

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        // ✅ Sort receipts by date (latest first)
        data.sort((a, b) {
          try {
            final dateA = DateTime.tryParse(a["Date"]?.toString() ?? "");
            final dateB = DateTime.tryParse(b["Date"]?.toString() ?? "");
            if (dateA != null && dateB != null) {
              return dateB.compareTo(dateA); // latest first
            }
          } catch (e) {
            print("⚠️ Date parse error: $e");
          }
          return 0;
        });

        setState(() {
          _receipts = data.cast<Map<String, dynamic>>();
          _filteredReceipts = List.from(_receipts);
          _filterSearch(searchController.text);
          _isLoading = false;
        });
      } else {
        print("⚠️ Server returned status ${res.statusCode}");
        setState(() {
          _receipts = [];
          _filteredReceipts = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error in _fetchReceipts: $e");
      setState(() {
        _receipts = [];
        _filteredReceipts = [];
        _isLoading = false;
      });
    }
  }

  String _formatApiDate(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty) {
      return 'N/A';
    }
    try {
      final dateTime = DateTime.parse(apiDate);
      return DateFormat('dd-MM-yyyy').format(dateTime);
    } catch (e) {
      print("⚠️ Date format error in ListView: $e for date $apiDate");
      return apiDate;
    }
  }

  void _filterSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredReceipts = _receipts);
    } else {
      setState(() {
        _filteredReceipts = _receipts
            .where(
              (p) => p["Name"].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      });
    }
  }

  Future<void> _navigateToAddReceiptPage({int? receiptId, String? type}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddReceiptPage(
          isEdit: receiptId != null,
          receiptId: receiptId,
          type: type ?? selectedType,
        ),
      ),
    );
    if (result == true) {
      print("🔄 Refreshing receipt list after save/update...");
      await _fetchReceipts();
    }
  }

  Widget _buildTypeSelectionField(BuildContext context) {
    final InputDecoration inputDecoration = InputDecoration(
      hintText: "Type",
      hintStyle: const TextStyle(fontSize: 14),
      isDense: true,
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 10),
      suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 40),
    );

    return GestureDetector(
      key: _typeFieldKey, // GlobalKey सेट करें
      onTap: () {
        _showTypeListMenu(context); // मेनू दिखाने के लिए
      },
      child: AbsorbPointer(
        child: TextFormField(
          key: ValueKey(selectedType),
          controller: TextEditingController(text: selectedType),
          decoration: inputDecoration,
          readOnly: true,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  void _showTypeListMenu(BuildContext context) async {
    // GlobalKey से फ़ील्ड की पोजीशन और साइज़ प्राप्त करें
    final RenderBox renderBox =
        _typeFieldKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    final selectedValue = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 4.0, // फ़ील्ड के नीचे
        offset.dx + size.width,
        offset.dy + size.height + 4.0 + (30.0 * _types.length),
      ),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: EdgeInsets.zero,
          height: 0,
          child: SizedBox(
            height: 30.0 * (_types.length > 5 ? 5.5 : _types.length.toDouble()),
            width: size.width,
            child: Scrollbar(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final item = _types[index];
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context, item);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 2.0,
                        horizontal: 12.0,
                      ),
                      height: 30,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedType == item
                              ? Color(0xFF1E3A8A)
                              : Colors.black,
                          fontWeight: selectedType == item
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
      elevation: 8.0,
    );

    if (selectedValue != null) {
      setState(() {
        selectedType = selectedValue;
        // जब type बदलता है, तो Receipts को फिर से फ़ेच करें
        _fetchReceipts();
      });
    }
  }

  // ----------------------------------------------------------------------
  // *** Date Field Widget (Reused) ***
  // ----------------------------------------------------------------------

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
            _fetchReceipts(); // Date बदलने पर Receipts को फ़ेच करें
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
          horizontal: 10,
        ),
      ),
    );
  }

  // ----------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const double mainPadding = 12.0;

    if (_isLoading && _receipts.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Manage Receipts")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text("Manage Receipts")),
      body: Padding(
        padding: const EdgeInsets.all(mainPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Search Filters Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildDateField("From", fromDateController),
                  ),
                  const SizedBox(width: 5),

                  Expanded(
                    flex: 3,
                    child: _buildDateField("To", toDateController),
                  ),
                  const SizedBox(width: 5),

                  // *** CHANGED: Using Custom Selection Field ***
                  Expanded(flex: 4, child: _buildTypeSelectionField(context)),
                  const SizedBox(width: 5),

                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: _fetchReceipts,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Icon(
                        Icons.search,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Search Text Field
              TextField(
                controller: searchController,
                onChanged: _filterSearch,
                decoration: InputDecoration(
                  labelText: "Search by Name",
                  labelStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 1.0,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 20.0,
                  ),
                ),
              ),
              const SizedBox(height: 5),

              // Receipts List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredReceipts.isEmpty
                    ? const Center(child: Text("No Receipts found"))
                    : ListView.builder(
                        itemCount: _filteredReceipts.length,
                        itemBuilder: (context, index) {
                          final receipt = _filteredReceipts[index];
                          final remarkText = receipt["Remark"]?.toString();
                          final hasRemark =
                              remarkText != null && remarkText.isNotEmpty;
                          return GestureDetector(
                            onTap: () => _navigateToAddReceiptPage(
                              receiptId: receipt["id"],
                              type:
                                  (receipt["Type"]?.toString().isNotEmpty ??
                                      false)
                                  ? receipt["Type"].toString()
                                  : selectedType,
                            ),
                            child: Card(
                              // Reduced vertical margin for list item spacing
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 7,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Ref No: ${receipt["Ref_No"]}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Color(0xFF1E3A8A),
                                                ),
                                              ),
                                              Text(
                                                "Name: ${receipt["Name"]}",
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    "Contact: ${receipt["ContactNo"]}",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.print_rounded,
                                                          size: 20,
                                                          color: Color(
                                                            0xFF1E3A8A,
                                                          ),
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),

                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).push(
                                                            MaterialPageRoute(
                                                              builder: (_) => ReceiptPrintPage(
                                                                receiptId:
                                                                    receipt['id'],
                                                                receiptType:
                                                                    receipt['Type']
                                                                        ?.toString() ??
                                                                    selectedType,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.share_rounded,
                                                          size: 20,
                                                          color: Color(
                                                            0xFF1E3A8A,
                                                          ),
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                        constraints:
                                                            const BoxConstraints(),

                                                        onPressed: () {
                                                          Navigator.of(
                                                            context,
                                                          ).push(
                                                            MaterialPageRoute(
                                                              builder: (_) => ReceiptPrintPage(
                                                                receiptId:
                                                                    receipt['id'],
                                                                receiptType:
                                                                    receipt['Type']
                                                                        ?.toString() ??
                                                                    selectedType,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),

                                              if (hasRemark)
                                                Text(
                                                  "Remark: $remarkText",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.orange,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _formatApiDate(
                                                  receipt["Date"]?.toString(),
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              // Amount
                                              Text(
                                                "₹${receipt["Amount"]}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.green,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      // Floating Add Button
      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GestureDetector(
              onTap: () => _navigateToAddReceiptPage(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Receipt',
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
}
