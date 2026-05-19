import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';

class SalesBillPage extends StatefulWidget {
  const SalesBillPage({super.key});

  @override
  State<SalesBillPage> createState() => _SalesBillPageState();
}

class _SalesBillPageState extends State<SalesBillPage> {
  List<Map<String, dynamic>> bills = [];

  bool isLoading = true;
  @override
  void initState() {
    super.initState();

    fetchBills();
  }

  Future<void> fetchBills() async {
    setState(() {
      isLoading = true;
    });

    final response = await ApiService.postRequest(endpoint: "/salesman/bills");


    if (response != null) {
      if (response is List) {
        bills = List<Map<String, dynamic>>.from(
          response.map((e) => Map<String, dynamic>.from(e)),
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Bills"), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bills.isEmpty
          ? const Center(child: Text("No Bills Found"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bills.length,
              itemBuilder: (_, i) {
                final bill = bills[i];
                return _billCard(context, bill);
              },
            ),
    );
  }

  Widget _billCard(BuildContext context, Map<String, dynamic> bill) {
    final isPaid = bill["status"] == "paid";

    return GestureDetector(
      onTap: () {
        // 👉 future: open bill details page
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          children: [
            // 🔹 STATUS ICON
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPaid
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPaid ? Icons.check_circle : Icons.pending,
                color: isPaid ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(width: 12),

            // 🔹 BILL DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Invoice: ${bill["invoice_no"]}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Date: ${bill["date"]}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹${(double.tryParse(bill["amount"].toString()) ?? 0).toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 STATUS TEXT
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isPaid ? "PAID" : "PENDING",
                  style: TextStyle(
                    color: isPaid ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
