import 'package:billcare/SalesManFolder/bills/saleman_bills_details.dart';
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

    final response = await ApiService.postRequest(endpoint: "/saleman/bills");

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
    return GestureDetector(
      onTap: () {},

      child: Container(
        margin: const EdgeInsets.only(bottom: 8),

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(14),

          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 DETAILS
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🔹 ICON
                  Container(
                    padding: const EdgeInsets.all(8),

                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.12),

                      borderRadius: BorderRadius.circular(10),
                    ),

                    child: const Icon(
                      Icons.receipt_long,
                      color: Colors.orange,
                      size: 18,
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// 🔹 DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// 🔥 FIRST ROW
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                bill["client_name"]?.toString() ?? "",

                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,

                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            Text(
                              "INV ${bill["invoice_no"]}",

                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue,
                              ),
                            ),

                            const SizedBox(width: 6),

                            Text(
                              bill["date"]?.toString() ?? "",

                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        /// 🔥 SECOND ROW
                        Row(
                          children: [
                            Icon(
                              Icons.call_outlined,
                              size: 12,
                              color: Colors.grey.shade600,
                            ),

                            const SizedBox(width: 4),

                            Expanded(
                              child: Text(
                                bill["contact_no"]?.toString() ?? "",

                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),

                            Text(
                              "₹${bill["amount"] ?? "0"}",

                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// 🔥 ARROW
                  const SizedBox(width: 8),

                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SalemanBillDetailsPage(
                            saleId: int.parse(bill["sale_id"].toString()),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
