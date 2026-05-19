import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();

  final TextEditingController searchCtrl = TextEditingController();

  List<Map<String, dynamic>> dummyLedger = [
    {
      "type": "Receivable Begin",
      "date": "01 NOV, 25",
      "amount": "0.00",
      "balance": "0.00",
      "isCredit": true,
    },
    {
      "type": "Sale",
      "date": "25 NOV, 25 • Sale 2",
      "amount": "1,000.00",
      "balance": "1,000.00",
      "isCredit": true,
    },
    {
      "type": "Payment-in",
      "date": "25 NOV, 25 • PayIn 1",
      "amount": "500.00",
      "balance": "500.00",
      "isCredit": true,
    },
    {
      "type": "Sale Order",
      "date": "25 NOV, 25 • SO 1",
      "amount": "2,000.00",
      "balance": "2,000.00",
      "isCredit": true,
    },
    {
      "type": "Credit Note",
      "date": "25 NOV, 25 • CN 1",
      "amount": "20,000.00",
      "balance": "20,000.00",
      "isCredit": false,
    },
  ];
  String selectedFilter = "This Month";

  @override
  void initState() {
    super.initState();

    // BY DEFAULT LAST 1 MONTH DATE RANGE
    DateTime now = DateTime.now();
    fromDate = DateTime(now.year, now.month - 1, now.day);
    toDate = now;
  }

  Future pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) setState(() => fromDate = picked);
  }

  Future pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2050),
    );
    if (picked != null) setState(() => toDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Party Statement", style: TextStyle(fontSize: 17)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.account_balance)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.picture_as_pdf)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.grid_on)),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -------- Date Filter Row --------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // ---------------- Dropdown Filter -----------------
                Builder(
                  builder: (context) {
                    return InkWell(
                      onTap: () async {                  
                        final RenderBox button =
                            context.findRenderObject() as RenderBox;
                        final Offset position = button.localToGlobal(
                          Offset.zero,
                        );
                        final Size size = button.size;

                        // ⚡ Show menu exactly below the button
                        final selected = await showMenu(
                          context: context,
                          position: RelativeRect.fromLTRB(
                            position.dx, 
                            position.dy +
                                size.height, 
                            position.dx + size.width,
                            0,
                          ),
                          items: const [
                            PopupMenuItem(value: "Today", child: Text("Today")),
                            PopupMenuItem(
                              value: "Yesterday",
                              child: Text("Yesterday"),
                            ),
                            PopupMenuItem(
                              value: "This Month",
                              child: Text("This Month"),
                            ),
                            PopupMenuItem(
                              value: "Last Month",
                              child: Text("Last Month"),
                            ),
                          ],
                        );

                        if (selected != null) {
                          setState(() {
                            selectedFilter = selected;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Text(
                              selectedFilter,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.keyboard_arrow_down, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 30),

                // ---------------- FROM DATE ----------------
                InkWell(
                  onTap: pickFromDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat("dd/MM/yy").format(fromDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
                const Text("TO", style: TextStyle(fontSize: 12)),
                const SizedBox(width: 10),

                // ---------------- TO DATE ----------------
                InkWell(
                  onTap: pickToDate,
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat("dd/MM/yy").format(toDate),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // -------- Search -----------------
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            color: Colors.blue.shade50,
            child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Search Party",
                      ),
                    ),
                  ),
                  if (searchCtrl.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        searchCtrl.clear();
                        setState(() {});
                      },
                      child: const Icon(Icons.close),
                    ),
                ],
              ),
            ),
          ),

          // -------- Summary Cards ----------
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: summaryCard(
                    title: "Total Amount",
                    amount: "23,500.00",
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: summaryCard(
                    title: "Closing Balance",
                    amount: "19,500.00",
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // -------- Ledger List ------------
          Expanded(
            child: ListView.builder(
              itemCount: dummyLedger.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (_, i) {
                final item = dummyLedger[i];
                return ledgerTile(
                  type: item["type"],
                  date: item["date"],
                  amount: item["amount"],
                  balance: item["balance"],
                  isCredit: item["isCredit"],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget summaryCard({
    required String title,
    required String amount,
    required Color color,
  }) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10)),
          const SizedBox(height: 6),
          Text(
            "₹ $amount",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget ledgerTile({
    required String type,
    required String date,
    required String amount,
    required String balance,
    required bool isCredit,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TOP ROW
          Row(
            children: [
              Expanded(
                child: Text(
                  type,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),

              /// SMALL BADGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCredit
                      ? Colors.green.withOpacity(0.12)
                      : Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCredit ? "Credit" : "Debit",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          /// DATE
          Text(
            date,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),

          const SizedBox(height: 8),

          /// AMOUNT + BALANCE
          Row(
            children: [
              Text(
                "₹ $amount",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                "₹ $balance",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
