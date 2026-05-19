import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  State<PaymentHistoryPage> createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  DateTime? fromDate;
  DateTime? toDate;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> payments = [];
  bool isLoading = false;
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    toDate = now;
    fromDate = now.subtract(const Duration(days: 30));
    fetchPaymentHistory();
  }

  List<Map<String, dynamic>> get filteredPayments {
    return payments.where((item) {
      final itemDate = DateFormat("dd-MM-yyyy").parse(item["date"]);

      if (fromDate != null) {
        final from = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);

        if (itemDate.isBefore(from)) return false;
      }

      if (toDate != null) {
        final to = DateTime(
          toDate!.year,
          toDate!.month,
          toDate!.day,
          23,
          59,
          59,
        );

        if (itemDate.isAfter(to)) return false;
      }

      // 🔥 SEARCH FILTER
      final query = _searchController.text.toLowerCase();

      if (query.isNotEmpty) {
        final refNo = (item["ref_no"] ?? "").toString().toLowerCase();

        final mode = (item["mode"] ?? "").toString().toLowerCase();

        final remark = (item["remark"] ?? "").toString().toLowerCase();

        final amount = (item["amount"] ?? "").toString().toLowerCase();

        if (!refNo.contains(query) &&
            !mode.contains(query) &&
            !remark.contains(query) &&
            !amount.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  Future<void> fetchPaymentHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.postRequest(
        endpoint: "/client/payment/history",
      );

      debugPrint("📥 PAYMENT HISTORY RESPONSE: $response");

      if (response != null) {
        if (response is List) {
          payments = List<Map<String, dynamic>>.from(response);
        } else if (response is Map) {
          payments = [Map<String, dynamic>.from(response)];
        }

        setState(() {});
      }
    } catch (e) {
      debugPrint("❌ PAYMENT HISTORY ERROR: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    DateTime initialDate = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Payment History")),
      body: Column(
        children: [
          // 🔹 Date Filters
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: _dateBox(
                    title: fromDate == null
                        ? "From Date"
                        : DateFormat("dd MMM yyyy").format(fromDate!),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _dateBox(
                    title: toDate == null
                        ? "To Date"
                        : DateFormat("dd MMM yyyy").format(toDate!),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search txn / mode",
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25), // 🔥 pill shape
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 🔹 Payment List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredPayments.isEmpty
                ? const Center(child: Text("No Payment Found"))
                : ListView.builder(
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      final item = filteredPayments[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🔹 REF NO + DATE
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Ref No: ${item["ref_no"] ?? "-"}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),

                                Text(
                                  item["date"] ?? "-",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // 🔹 AMOUNT + MODE
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "₹${item["amount"] ?? 0}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),

                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    item["mode"] ?? "-",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // 🔹 DISCOUNT + PRINT
                            if ((item["discount"] ?? 0).toString() != "0")
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Discount: ₹${item["discount"]}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                    InkWell(
                                      onTap: () {
                                        debugPrint("🖨 PRINT ${item["id"]}");
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.print,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              "Print",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // 🔹 REMARK
                            if ((item["remark"] ?? "").toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "Remark: ${item["remark"]}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40, // 🔥 compact height
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 14, color: Colors.blue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
