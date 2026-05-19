import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';

class UserDuePaymentPage extends StatefulWidget {
  const UserDuePaymentPage({super.key});

  @override
  State<UserDuePaymentPage> createState() => _UserDuePaymentPageState();
}

class _UserDuePaymentPageState extends State<UserDuePaymentPage> {
  List<Map<String, dynamic>> dues = [];

  bool isLoading = false;

  double get totalOutstanding {
    double sum = 0;

    for (var d in dues) {
      sum += double.tryParse(d["balance"].toString()) ?? 0;
    }

    return sum;
  }

  @override
  void initState() {
    super.initState();
    fetchDueHistory();
  }

  Future<void> fetchDueHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.postRequest(
        endpoint: "/client/due/history",
      );

      debugPrint("📥 DUE HISTORY RESPONSE: $response");

      if (response != null) {
        dues = List<Map<String, dynamic>>.from(response);

        setState(() {});
      }
    } catch (e) {
      debugPrint("❌ DUE HISTORY ERROR: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Due Payments")),
      body: SafeArea(
        child: Column(
          children: [
            // 🔴 TOP SUMMARY CARD
            Container(
              margin: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffFF6B6B), Color(0xffFF4D4D)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Total Due",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "₹${totalOutstanding.toStringAsFixed(0)}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 LIST
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dues.isEmpty
                  ? const Center(child: Text("No Due History Found"))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                      itemCount: dues.length,
                      itemBuilder: (_, i) {
                        final item = dues[i];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 2,
                                spreadRadius: 0,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 ROW 1
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniTile(
                                      "Type",
                                      item["type"] ?? "",
                                      valueColor: item["type"] == "Sale"
                                          ? Colors.red.shade700
                                          : Colors.green.shade700,
                                    ),
                                  ),

                                  Expanded(
                                    child: _miniTile(
                                      "Invoice No",
                                      item["invoice_no"] == ""
                                          ? "-"
                                          : item["invoice_no"],
                                    ),
                                  ),

                                  Expanded(
                                    child: _miniTile(
                                      "Date",
                                      item["date"] ?? "",
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // 🔹 ROW 2
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniTile(
                                      "Amount",
                                      "₹${item["amount"]}",
                                    ),
                                  ),

                                  Expanded(
                                    child: _miniTile(
                                      "Ref No",
                                      item["ref_no"] == ""
                                          ? "-"
                                          : item["ref_no"],
                                    ),
                                  ),

                                  Expanded(
                                    child: _miniTile(
                                      "Mode",
                                      (item["mode"] ?? "").toString().isEmpty
                                          ? "-"
                                          : item["mode"],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // 🔹 ROW 3
                              Row(
                                children: [
                                  Expanded(
                                    child: _miniTile(
                                      "Balance",
                                      "₹${item["balance"]}",
                                      valueColor: Colors.red.shade700,
                                    ),
                                  ),

                                  if ((item["remark"] ?? "")
                                      .toString()
                                      .isNotEmpty)
                                    Expanded(
                                      flex: 2,
                                      child: _miniTile(
                                        "Remark",
                                        item["remark"],
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
      ),
    );
  }

  Widget _miniTile(String title, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 2),

        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
