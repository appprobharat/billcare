import 'package:flutter/material.dart';

class ReportDuePage extends StatelessWidget {
  const ReportDuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(title: const Text("Due Reports"), elevation: 0),

      body: Column(
        children: [
          // ------- HEADER -------
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            color: Colors.white,
            child: const Row(
              children: [
                Expanded(flex: 1, child: Text("S.No", style: _headerStyle)),
                Expanded(flex: 3, child: Text("Customer", style: _headerStyle)),
                Expanded(flex: 2, child: Text("Open", style: _headerStyle)),
                Expanded(flex: 2, child: Text("Cr", style: _headerStyle)),
                Expanded(flex: 2, child: Text("Dr", style: _headerStyle)),
                Expanded(flex: 2, child: Text("Due", style: _headerStyle)),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // ------- LIST -------
          Expanded(
            child: ListView.builder(
              itemCount: 17, // replace with API length
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  shadowColor: Colors.black12,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // S.No
                        Expanded(
                          flex: 1,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),

                        // NAME + CONTACT
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Customer Name ${index + 1}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                "9876543210",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Opening Balance
                        Expanded(
                          flex: 2,
                          child: Text(
                            "₹1500",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),

                        // CREDIT (Green)
                        Expanded(
                          flex: 2,
                          child: Text(
                            "₹500",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // DEBIT (Red)
                        Expanded(
                          flex: 2,
                          child: Text(
                            "₹200",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // DUE AMOUNT
                        Expanded(
                          flex: 2,
                          child: Text(
                            "₹1300",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------- HEADER STYLE --------
const TextStyle _headerStyle = TextStyle(
  fontWeight: FontWeight.bold,
  fontSize: 12,
);
