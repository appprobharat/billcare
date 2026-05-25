import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';

class ReportDuePage extends StatefulWidget {
  const ReportDuePage({super.key});

  @override
  State<ReportDuePage> createState() => _ReportDuePageState();
}

class _ReportDuePageState extends State<ReportDuePage> {
  List dueList = [];
  bool isLoading = true;
  String sortKey = "closing_balance";
  bool isAscending = true;
  final TextEditingController searchController = TextEditingController();

  List filteredDueList = [];

  @override
  void initState() {
    super.initState();
    fetchDueReport();
  }

  Future<void> fetchDueReport() async {
    setState(() => isLoading = true);

    final res = await ApiService.postRequest(
      endpoint: "/report/due",
      isJson: true,
    );
    if (res != null && res is List) {
      dueList = res.where((item) {
        double due = double.tryParse(item['closing_balance'].toString()) ?? 0;

        return due != 0;
      }).toList();

      filteredDueList = List.from(dueList);
    }

    setState(() => isLoading = false);
  }

  void sortDueList(String key) {
    if (sortKey == key) {
      isAscending = !isAscending;
    } else {
      sortKey = key;
      isAscending = true;
    }

    dueList.sort((a, b) {
      dynamic aVal = a[key];
      dynamic bVal = b[key];

      /// STRING SORT
      if (key == "name") {
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

  void filterDueList(String query) {
    if (query.isEmpty) {
      filteredDueList = List.from(dueList);
    } else {
      filteredDueList = dueList.where((item) {
        final name = item['name']?.toString().toLowerCase() ?? "";

        return name.contains(query.toLowerCase());
      }).toList();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Due Reports"),
        elevation: 0,
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: TextField(
                    controller: searchController,
                    onChanged: filterDueList,
                    decoration: InputDecoration(
                      hintText: "Search by name",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 12,
                  ),
                  color: Colors.white,
                  child: Row(
                    children: [
                      /// CUSTOMER
                      Expanded(
                        flex: 4,
                        child: _sortableHeader("Customer", "name"),
                      ),

                      /// OPEN
                      Expanded(
                        flex: 2,
                        child: _sortableHeader("Open", "opening_balance"),
                      ),

                      /// CR
                      Expanded(
                        flex: 2,
                        child: _sortableHeader("Cr", "total_credit"),
                      ),

                      /// DR
                      Expanded(
                        flex: 2,
                        child: _sortableHeader("Dr", "total_debit"),
                      ),

                      /// DUE
                      Expanded(
                        flex: 2,
                        child: _sortableHeader("Due", "closing_balance"),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                Expanded(
                  child: ListView.builder(
                    itemCount: filteredDueList.length,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    itemBuilder: (context, index) {
                      final item = filteredDueList[index];

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
                              Expanded(
                                flex: 1,
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name']?.toString() ?? "",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      item['contact_no']?.toString() ?? "",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  "₹${item['opening_balance']}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  "₹${item['total_credit']}",
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  "₹${item['total_debit']}",
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              Expanded(
                                flex: 2,
                                child: Text(
                                  "₹${item['closing_balance']}",
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

  Widget _sortableHeader(String title, String keyName) {
    bool isActive = sortKey == keyName;

    return InkWell(
      onTap: () => sortDueList(keyName),
      child: Row(
        children: [
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),

          const SizedBox(width: 2),

          Icon(
            isActive
                ? (isAscending ? Icons.arrow_upward : Icons.arrow_downward)
                : Icons.unfold_more,
            size: 14,
          ),
        ],
      ),
    );
  }
}
