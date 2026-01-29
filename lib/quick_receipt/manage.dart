// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/quick_receipt/add.dart';
import 'package:billcare/quick_receipt/edit.dart';
import 'package:billcare/quick_receipt/quick_pdf.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


class ManageQuickReceiptPage extends StatefulWidget {
  const ManageQuickReceiptPage({super.key});

  @override
  State<ManageQuickReceiptPage> createState() => _ManageQuickReceiptPageState();
}

class _ManageQuickReceiptPageState extends State<ManageQuickReceiptPage> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> _receipts = [];
  List<Map<String, dynamic>> _filteredReceipts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final oneMonthAgo = today.subtract(const Duration(days: 30));
    fromDateController.text = DateFormat('dd-MM-yyyy').format(oneMonthAgo);
    toDateController.text = DateFormat('dd-MM-yyyy').format(today);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReceipts();
    });
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
    setState(() {
      _isLoading = true;
    });
    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    final url = Uri.parse("https://gst.billcare.in/api/quick/receipt/list");

    final body = {
      "from": DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(fromDateController.text)),
      "to": DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(toDateController.text)),
    };

    print("📡 Fetching Quick Receipts: $body");
    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: body,
      );

      print("📩 Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _receipts = data.cast<Map<String, dynamic>>();
          _filterSearch(searchController.text);
          _isLoading = false; // ✅ STOP LOADING
        });
      } else {
        setState(() {
          _receipts = [];
          _filteredReceipts = [];
          _isLoading = false; // ✅ STOP LOADING
        });
      }
    } catch (e) {
      print("⚠️ Error fetching receipts: $e");
      setState(() {
        _receipts = [];
        _filteredReceipts = [];
        _isLoading = false; // ✅ STOP LOADING
      });
    }
  }

  // Function to capitalize the first letter of a string
  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _filterSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredReceipts = _receipts);
    } else {
      setState(() {
        _filteredReceipts = _receipts
            .where(
              (r) => r["Name"].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      });
    }
  }

  void _openEditPage(Map<String, dynamic> receipt) async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditQuickReceiptPage(receipt: receipt)),
    );

    if (updated == true) {
      _fetchReceipts();
    }
  }

  void _printReceipt(int id) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuickReceiptPdfPage(receiptId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text("Manage Quick Receipts")),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Date Range and Search Button
            Row(
              children: [
                Expanded(
                  child: _buildDateField("From Date", fromDateController),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildDateField("To Date", toDateController)),
                const SizedBox(width: 8),
                // Search Button
                SizedBox(
                  height: 37,
                  width: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    onPressed: _fetchReceipts,
                    child: Icon(Icons.search, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              onChanged: (query) {
                setState(() {});
                _filterSearch(query);
              },
              decoration: InputDecoration(
                labelText: "Search by Name",
                labelStyle: const TextStyle(fontSize: 14),
                isDense: true,
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
                    color: Color(0xFF1E3A8A),
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 20.0,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          searchController.clear();
                          _filterSearch('');
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    ) // ✅ Full page loader
                  : _filteredReceipts.isEmpty
                  ? const Center(child: Text("No receipts found"))
                  : ListView.builder(
                      itemCount: _filteredReceipts.length,
                      itemBuilder: (context, index) {
                        final r = _filteredReceipts[index];

                        final capitalizedName = _capitalize(
                          r["Name"]?.toString() ?? 'N/A',
                        );

                        String displayDate = 'N/A';
                        try {
                          if (r["Date"]?.toString().isNotEmpty == true) {
                            final dateObj = DateFormat(
                              'yyyy-MM-dd',
                            ).parse(r["Date"].toString());
                            displayDate = DateFormat(
                              'dd-MM-yyyy',
                            ).format(dateObj);
                          }
                        } catch (_) {
                          displayDate = 'Invalid Date';
                        }

                        return GestureDetector(
                          onTap: () => _openEditPage(r),
                          child: Card(
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
                                              "Name: $capitalizedName",
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            if (r["ChequeNo"]
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true)
                                              Text.rich(
                                                TextSpan(
                                                  children: [
                                                    const TextSpan(
                                                      text: "Cheque: ",
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ), // ✅ BOLD
                                                    ),
                                                    TextSpan(
                                                      text: r["ChequeNo"]
                                                          .toString(),
                                                    ),
                                                  ],
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),

                                            if (r["Remark"]
                                                    ?.toString()
                                                    .isNotEmpty ==
                                                true)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 4.0,
                                                ),
                                                child: Text(
                                                  "Remark: ${r["Remark"]}",
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors
                                                        .orange, // ✅ ORANGE COLOUR
                                                    fontSize: 12,
                                                  ),
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
                                              displayDate,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                            // Text(
                                            //   _formatApiDate(
                                            //     payment["Date"]?.toString(),
                                            //   ),
                                            //   style: const TextStyle(
                                            //     color: Colors.black54,
                                            //     fontSize: 12,
                                            //   ),
                                            // ),
                                            // Amount
                                            Text(
                                              "₹${r["Amount"]}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green,
                                                fontSize: 16,
                                              ),
                                            ),

                                            IconButton(
                                              icon: const Icon(
                                                Icons.print_rounded,
                                                size: 20,
                                                color: Color(0xFF1E3A8A),
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints:
                                                  const BoxConstraints(),
                                              onPressed: () =>
                                                  _printReceipt(r["id"]),
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
      // ... bottomNavigationBar is unchanged
      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddQuickReceiptPage(),
                  ),
                ).then((value) {
                  if (value == true) {
                    _fetchReceipts(); // refresh list
                  }
                });
              },
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
                      'Add Quick Receipt',
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

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,

      onTap: () async {
        // Your existing date picker logic...
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
      // To center-align the content (text inside the field)
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),

        border: const OutlineInputBorder(),
        isDense: true,

        contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        // Add an icon to clearly indicate it's a date field (optional, but attractive)
        suffixIcon: const Icon(Icons.calendar_today, size: 16),
        // Reduce padding around the icon (optional)
        suffixIconConstraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
      ),
    );
  }
}
