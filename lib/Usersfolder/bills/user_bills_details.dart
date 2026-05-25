import 'package:billcare/SalesManFolder/bills/bills_pdf.dart';
import 'package:flutter/material.dart';
import 'package:billcare/api/api_service.dart';

class UserBillDetailsPage extends StatefulWidget {
  final int saleId;

  const UserBillDetailsPage({super.key, required this.saleId});

  @override
  State<UserBillDetailsPage> createState() => _UserBillDetailsPageState();
}

class _UserBillDetailsPageState extends State<UserBillDetailsPage> {
  Map<String, dynamic>? billData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBillDetails();
  }

  Future<void> fetchBillDetails() async {
    setState(() => isLoading = true);

    final response = await ApiService.postRequest(
      endpoint: "/client/bill/details",
      body: {"sale_id": widget.saleId.toString()},
    );

    if (response != null) {
      setState(() {
        billData = response;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        title: const Text("Bill Details"),
        elevation: 0,
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : billData == null
          ? const Center(child: Text("No Data Found"))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    /// 🔥 INVOICE CARD
                    Container(
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// TOP
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "INVOICE",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  "#${billData!["invoice_no"]}",
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          _infoRow(
                            "Client Name",
                            billData!["client_name"].toString(),
                          ),

                          _infoRow(
                            "Contact",
                            billData!["contact_no"].toString(),
                          ),

                          _infoRow("Date", billData!["date"].toString()),

                          const SizedBox(height: 18),

                          const Divider(),

                          const SizedBox(height: 12),

                      
                          const Text(
                            "Items",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          /// ITEMS LIST
                          ListView.builder(
                            itemCount: (billData!["items"] as List).length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final item = billData!["items"][index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),

                                padding: const EdgeInsets.all(12),

                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item["item_name"].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("Qty : ${item["qty"]}"),

                                        Text("Rate : ₹${item["rate"]}"),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("GST : ${item["gst"]}%"),

                                        Text(
                                          "GST Amt : ₹${item["gst_amount"]}",
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 4),

                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        "₹${item["amount"]}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 18),

                          const Divider(),

                          /// TOTAL
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Total Amount",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                "₹${billData!["total_amount"]}",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final path =
                                  await BillPdfService.generateAndSavePdf(
                                    billData: billData!,
                                  );

                              if (path.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.green,

                                    behavior: SnackBarBehavior.floating,

                                    content: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                        ),

                                        SizedBox(width: 10),

                                        Expanded(
                                          child: Text(
                                            "PDF Downloaded Successfully",
                                          ),
                                        ),
                                      ],
                                    ),

                                    action: SnackBarAction(
                                      label: "PREVIEW",

                                      textColor: Colors.white,

                                      onPressed: () async {
                                        await BillPdfService.printDocument(
                                          billData: billData!,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.download),

                            label: const Text("Download PDF"),

                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await BillPdfService.printDocument(
                                billData: billData!,
                              );
                            },

                            icon: const Icon(Icons.share),

                            label: const Text("Share PDF"),

                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
