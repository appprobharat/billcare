import 'dart:convert';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/payment/add.dart';
import 'package:billcare/payment/payment_pdf.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


class ManagePaymentPage extends StatefulWidget {
  const ManagePaymentPage({super.key});

  @override
  State<ManagePaymentPage> createState() => _ManagePaymentPageState();
}

class _ManagePaymentPageState extends State<ManagePaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  String selectedType = "Supplier";
  final List<String> _types = ["Supplier", "Party", "Employee"];
  bool _isLoading = false;
  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    fromDateController.text = DateFormat(
      'dd-MM-yyyy',
    ).format(today.subtract(const Duration(days: 30)));
    toDateController.text = DateFormat('dd-MM-yyyy').format(today);
    _fetchPayments();
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

  Future<void> _fetchPayments() async {
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

    final url = Uri.parse("https://gst.billcare.in/api/payment/list");

    final body = {
      "from": DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(fromDateController.text)),
      "to": DateFormat(
        'yyyy-MM-dd',
      ).format(DateFormat('dd-MM-yyyy').parse(toDateController.text)),
      "type": selectedType,
    };

    print("📡 Fetching Payments: $body");

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

        // ✅ Sort by date (latest first)
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
          _payments = data.cast<Map<String, dynamic>>();
          _filteredPayments = List.from(_payments);
          _filterSearch(searchController.text);
          _isLoading = false;
        });
      } else {
        print("⚠️ Server returned status ${res.statusCode}");
        setState(() {
          _payments = [];
          _filteredPayments = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("❌ Error in _fetchPayments: $e");
      setState(() {
        _payments = [];
        _filteredPayments = [];
        _isLoading = false;
      });
    }
  }

  void _filterSearch(String query) {
    setState(() {
      if (_isLoading) return;

      if (query.isEmpty) {
        _filteredPayments = _payments;
      } else {
        _filteredPayments = _payments
            .where(
              (p) => p["Name"].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  Future<void> _navigateToAddPaymentPage({int? paymentId, String? type}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPaymentPage(
          isEdit: paymentId != null,
          paymentId: paymentId,
          type: type ?? selectedType,
        ),
      ),
    );
    if (result == true) {
      print("🔄 Refreshing payment list after save/update...");
      await _fetchPayments();
    }
  }

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
          horizontal: 10,
        ),
      ),
    );
  }

  Widget _buildTypeField() {
    return SizedBox(
      width: 120, // adjust as needed
      child: TextFormField(
        controller: TextEditingController(text: selectedType),
        readOnly: true,
        onTap: () async {
          final RenderBox fieldBox = context.findRenderObject() as RenderBox;
          final overlay =
              Overlay.of(context).context.findRenderObject() as RenderBox;
          final Offset fieldPosition = fieldBox.localToGlobal(Offset.zero);
          final position = RelativeRect.fromLTRB(
            fieldPosition.dx + fieldBox.size.width - 120,
            fieldPosition.dy - (_types.length * 30) - 4,
            overlay.size.width - (fieldPosition.dx + fieldBox.size.width),
            0,
          );

          final selected = await showMenu<String>(
            context: context,
            position: position,
            items: _types.map((t) {
              return PopupMenuItem<String>(
                value: t,
                height: 30,
                child: Text(t, style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          );

          if (selected != null) {
            setState(() => selectedType = selected);
          }
        },
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: "Type",
          hintStyle: const TextStyle(fontSize: 12),
          isDense: true,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 8,
          ),
          suffixIcon: const Icon(Icons.arrow_drop_down, size: 16),
          constraints: const BoxConstraints(
            minHeight: 32, // compact
            maxHeight: 38,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text("Manage Payments")),
      // Reduced overall padding
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 10.0,
          vertical: 8.0,
        ), // Smaller padding
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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

                  Expanded(flex: 4, child: _buildTypeField()),
                  const SizedBox(width: 5),
                  SizedBox(
                    width: 42,
                    height: 42,
                    child: ElevatedButton(
                      onPressed: _fetchPayments, // Search/Fetch action
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
              const SizedBox(height: 12),

              TextField(
                controller: searchController,
                onChanged: (query) {
                  _filterSearch(query);
                },
                decoration: InputDecoration(
                  labelText: "Search by Name",
                  labelStyle: const TextStyle(fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0), // ज्यादा गोलाई
                    borderSide: BorderSide.none, // कोई बॉर्डर नहीं
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: const BorderSide(
                      color: Color(0xFF1E3A8A),
                      width: 1.0,
                    ),
                  ),
                  // Compact content padding
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12.0,
                    horizontal: 20.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPayments.isEmpty
                    ? const Center(child: Text("No payments found"))
                    : ListView.builder(
                        itemCount: _filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = _filteredPayments[index];
                          final remarkText = payment["Remark"]?.toString();
                          final hasRemark =
                              remarkText != null && remarkText.isNotEmpty;
                          return GestureDetector(
                            onTap: () => _navigateToAddPaymentPage(
                              paymentId: payment["id"],
                              type:
                                  (payment["Type"]?.toString().isNotEmpty ??
                                      false)
                                  ? payment["Type"].toString()
                                  : selectedType,
                            ),
                            child: Card(
                              // 1. Card Margin को और कम किया: 4 से 2
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              elevation: 1,
                              child: Padding(
                                // 2. Card की अंदर की Padding को और कम किया: 10.0 से 6.0
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
                                                "Ref No: ${payment["Ref_No"]}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Color(0xFF1E3A8A),
                                                ),
                                              ),
                                              Text(
                                                "Name: ${payment["Name"]}",
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
                                                    "Contact: ${payment["ContactNo"]}",
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight
                                                          .w600, // थोड़ा कम बोल्ड
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
                                                              builder: (_) => PaymentPrintPage(
                                                                paymentId:
                                                                    payment['id'],
                                                                paymentType:
                                                                    payment['Type']
                                                                        ?.toString() ??
                                                                    selectedType,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.share,
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
                                                              builder: (_) => PaymentPrintPage(
                                                                paymentId:
                                                                    payment['id'],
                                                                paymentType:
                                                                    payment['Type']
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
                                                  payment["Date"]?.toString(),
                                                ),
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              // Amount
                                              Text(
                                                "₹${payment["Amount"]}",
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

      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GestureDetector(
              onTap: () => _navigateToAddPaymentPage(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0, // Increased padding
                  vertical: 10.0, // Increased padding
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: const [
                    // Subtle Shadow
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 22, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Payment',
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
