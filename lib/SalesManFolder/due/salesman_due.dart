import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';

class SalesDuePaymentPage extends StatefulWidget {
  const SalesDuePaymentPage({super.key});

  @override
  State<SalesDuePaymentPage> createState() => _SalesDuePaymentPageState();
}

class _SalesDuePaymentPageState extends State<SalesDuePaymentPage> {
  bool isLoading = true;

  List<Map<String, dynamic>> dues = [];

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
        endpoint: "/saleman/due/history",
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

  double get totalOutstanding {
    double sum = 0;

    for (var d in dues) {
      sum += double.tryParse(d["due_amount"].toString()) ?? 0;
    }

    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Due Payments"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : dues.isEmpty
          ? const Center(child: Text("No Due Found"))
          : Column(
              children: [
                // 🔴 TOP SUMMARY CARD
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xffFF6B6B), Color(0xffFF4D4D)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Total Outstanding",
                              style: TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "₹${totalOutstanding.toStringAsFixed(0)}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: dues.length,
                    itemBuilder: (_, i) {
                      final item = dues[i];
                      return _dueCard(item);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _dueCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withOpacity(0.25)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          // 🔹 ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1)),
            child: Icon(Icons.receipt_long, color: Colors.orange),
          ),

          const SizedBox(width: 12),

          // 🔹 DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"] ?? "",

                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${item["contact_no"] ?? ""} • ${item["type"] ?? ""}",

                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Text(
                  "₹${item["due_amount"]}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // 🔹 STATUS
          Column(
            children: [
              Text(
                "DUE",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Icon(Icons.arrow_forward_ios, size: 14),
            ],
          ),
        ],
      ),
    );
  }
}
