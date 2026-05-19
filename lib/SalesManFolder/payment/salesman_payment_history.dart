import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SalesPaymentHistoryPage extends StatefulWidget {
  const SalesPaymentHistoryPage({super.key});

  @override
  State<SalesPaymentHistoryPage> createState() => _SalesPaymentHistoryPageState();
}

class _SalesPaymentHistoryPageState extends State<SalesPaymentHistoryPage> {
  DateTime? fromDate;
  DateTime? toDate;

  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> payments = [
    {
      "date": "2026-04-20",
      "amount": "₹500",
      "mode": "UPI",
      "txnId": "TXN12345",
      "status": "Success",
    },
    {
      "date": "2026-04-18",
      "amount": "₹1200",
      "mode": "Cash",
      "txnId": "TXN67890",
      "status": "Pending",
    },
    {
      "date": "2026-04-15",
      "amount": "₹800",
      "mode": "Bank",
      "txnId": "TXN54321",
      "status": "Failed",
    },
  ];
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    toDate = now;
    fromDate = now.subtract(const Duration(days: 30));
  }

  List<Map<String, dynamic>> get filteredPayments {
    return payments.where((item) {
      final itemDate = DateTime.parse(item["date"]);

      // 🔥 DATE FILTER
      if (fromDate != null && itemDate.isBefore(fromDate!)) return false;
      if (toDate != null && itemDate.isAfter(toDate!)) return false;

      // 🔥 SEARCH FILTER
      final query = _searchController.text.toLowerCase();

      if (query.isNotEmpty) {
        final txn = item["txnId"].toLowerCase();
        final mode = item["mode"].toLowerCase();
        final status = item["status"].toLowerCase();

        if (!txn.contains(query) &&
            !mode.contains(query) &&
            !status.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
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

  Color _getStatusColor(String status) {
    switch (status) {
      case "Success":
        return Colors.green;
      case "Pending":
        return Colors.orange;
      case "Failed":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Success":
        return Icons.check_circle;
      case "Pending":
        return Icons.access_time;
      case "Failed":
        return Icons.cancel;
      default:
        return Icons.help;
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
              ),
            ),
          ),
          const SizedBox(height: 10),

          // 🔹 Payment List
          Expanded(
            child: ListView.builder(
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
                      // 🔥 Title + Amount + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item["itemName"] ?? "Item",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          Text(
                            item["amount"],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 6),

                          Icon(
                            _getStatusIcon(item["status"]),
                            size: 16,
                            color: _getStatusColor(item["status"]),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 🔥 2 COLUMN DATA (MAIN CHANGE)
                      Row(
                        children: [
                          Expanded(
                            child: _miniInfo(
                              Icons.calendar_today,
                              item["date"],
                            ),
                          ),
                          Expanded(
                            child: _miniInfo(
                              Icons.account_balance_wallet,
                              item["mode"],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Row(
                        children: [
                          Expanded(
                            child: _miniInfo(Icons.receipt_long, item["txnId"]),
                          ),
                          Expanded(
                            child: _miniInfo(
                              Icons.info_outline,
                              item["status"],
                            ),
                          ),
                        ],
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

  Widget _miniInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppColors.primary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.black),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
