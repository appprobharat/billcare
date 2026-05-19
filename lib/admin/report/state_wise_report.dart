import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StateWiseReportPage extends StatefulWidget {
  const StateWiseReportPage({super.key});

  @override
  State<StateWiseReportPage> createState() => _StateWiseReportPageState();
}

class _StateWiseReportPageState extends State<StateWiseReportPage> {
  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();
  List<dynamic> data = [];
  bool isLoading = false;
  String sortKey = "state";
  bool isAscending = true;
  @override
  void initState() {
    super.initState();
    fetchReport();
  }

  Future<void> fetchReport() async {
    setState(() => isLoading = true);

    final res = await ApiService.postRequest(
      endpoint: "/report/state",
      isJson: true,

      body: {
        "from_date": DateFormat("yyyy-MM-dd").format(fromDate),
        "to_date": DateFormat("yyyy-MM-dd").format(toDate),
      },
    );
    debugPrint("======== API FILTER ========");

    debugPrint("FROM DATE => ${DateFormat("yyyy-MM-dd").format(fromDate)}");

    debugPrint("TO DATE => ${DateFormat("yyyy-MM-dd").format(toDate)}");

    debugPrint(
      "BODY => {"
      "\"from\":\"${DateFormat("yyyy-MM-dd").format(fromDate)}\", "
      "\"to\":\"${DateFormat("yyyy-MM-dd").format(toDate)}\""
      "}",
    );
    if (res != null && res is List) {
      data = res;
    }

    setState(() => isLoading = false);
  }

  void sortData(String key) {
    if (sortKey == key) {
      isAscending = !isAscending;
    } else {
      sortKey = key;
      isAscending = true;
    }

    data.sort((a, b) {
      dynamic aVal = a[key];
      dynamic bVal = b[key];

      /// STRING SORT
      if (key == "state") {
        return isAscending
            ? aVal.toString().compareTo(bVal.toString())
            : bVal.toString().compareTo(aVal.toString());
      }

      /// NUMBER SORT
      double aNum = double.tryParse(aVal.toString()) ?? 0;

      double bNum = double.tryParse(bVal.toString()) ?? 0;

      return isAscending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
    });

    setState(() {});
  }

  Future<void> pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
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
        fetchReport();
      });
    }
  }

  int get totalSales =>
      data.fold(0, (sum, e) => sum + (e["no_of_sales"] as int));

  int get totalSaleVal =>
      data.fold(0, (sum, e) => sum + (e["sale_value"] as int));

  int get totalPurchase =>
      data.fold(0, (sum, e) => sum + (e["no_of_purchase"] as int));

  int get totalPurVal =>
      data.fold(0, (sum, e) => sum + (e["purchase_value"] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("State Wise Report")),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            /// 🔽 DATE FILTER
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: _dateBox("From", fromDate, () => pickDate(true)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _dateBox("To", toDate, () => pickDate(false)),
                  ),
                ],
              ),
            ),

            /// 🔽 HEADER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  Expanded(flex: 2, child: _sortableHeader("State", "state")),

                  Expanded(
                    flex: 3,
                    child: _sortableHeader("Sales", "no_of_sales"),
                  ),

                  Expanded(
                    flex: 2,
                    child: _sortableHeader("Sale ₹", "sale_value"),
                  ),

                  Expanded(
                    flex: 2,
                    child: _sortableHeader("Pur", "no_of_purchase"),
                  ),

                  Expanded(
                    flex: 2,
                    child: _sortableHeader("Pur ₹", "purchase_value"),
                  ),
                ],
              ),
            ),

            /// 🔽 LIST
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        final d = data[i];
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 6,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.black12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Text(d["state"])),

                              Expanded(
                                flex: 1,
                                child: Text(
                                  "${d["no_of_sales"]}",
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2, // 👈 reduced
                                child: Text(
                                  "${d["sale_value"]}",
                                  textAlign: TextAlign.right,
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${d["sale_value"]}",
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  "${d["purchase_value"]}",
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            /// 🔥 TOTAL ROW
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                color: Colors.grey.shade300,
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text("TOTAL")),

                    Expanded(
                      flex: 2,
                      child: Text("$totalSales", textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("$totalSaleVal", textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("$totalPurchase", textAlign: TextAlign.right),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text("$totalPurVal", textAlign: TextAlign.right),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔽 DATE BOX (compact)
  Widget _dateBox(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 14),
            const SizedBox(width: 6),
            Text(
              "${label}: ${DateFormat("dd/MM/yyyy").format(date)}",
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortableHeader(String title, String keyName) {
    bool isActive = sortKey == keyName;

    return InkWell(
      onTap: () => sortData(keyName),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),

          const SizedBox(width: 2),

          Icon(
            isActive
                ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 13,
          ),
        ],
      ),
    );
  }
}
