import 'package:billcare/SalesManFolder/orders/salesman_order.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:billcare/api/api_service.dart';

class SalesOrderHistoryPage extends StatefulWidget {
  const SalesOrderHistoryPage({super.key});

  @override
  State<SalesOrderHistoryPage> createState() => _SalesOrderHistoryPageState();
}

class _SalesOrderHistoryPageState extends State<SalesOrderHistoryPage> {
  DateTime? fromDate;
  DateTime? toDate;

  String selectedStatus = "all";

  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    toDate = today;
    fromDate = today.subtract(const Duration(days: 30));

    fetchOrders();
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
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

      await fetchOrders();
    }
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
    });

    final response = await ApiService.postRequest(
      endpoint: "/saleman/sale/list",

      body: {
        "status": selectedStatus.toLowerCase(),

        "search": _searchController.text,

        "from_date": DateFormat("yyyy-MM-dd").format(fromDate!),

        "to_date": DateFormat("yyyy-MM-dd").format(toDate!),
      },
    );

    if (response != null && response["status"] == true) {
      setState(() {
        orders = List<Map<String, dynamic>>.from(
          (response["data"] as List).map((e) => Map<String, dynamic>.from(e)),
        );

        applyFilter();
      });
    } else {
      setState(() {
        orders = [];
        filteredOrders = [];
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      filteredOrders = List.from(orders);
    } else {
      filteredOrders = orders.where((order) {
        final invoice = (order["invoice_no"] ?? "").toString().toLowerCase();

        bool invoiceMatch = invoice.contains(query);

        bool itemMatch = false;

        if (order["items"] != null && order["items"] is List) {
          itemMatch = (order["items"] as List).any((item) {
            final itemName = (item["item_name"] ?? "").toString().toLowerCase();

            return itemName.contains(query);
          });
        }

        return invoiceMatch || itemMatch;
      }).toList();
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesOrderPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔹 Date Filter
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: _dateBox(
                    title: DateFormat("dd MMM yyyy").format(fromDate!),
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateBox(
                    title: DateFormat("dd MMM yyyy").format(toDate!),
                    onTap: () => _pickDate(false),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 30,

            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              children: [
                _statusChip("all"),
                _statusChip("pending"),
                _statusChip("approved"),
                _statusChip("rejected"),
              ],
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                ? const Center(child: Text("No Orders Found"))
                : ListView.builder(
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final item = filteredOrders[index];
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
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          item["invoice_no"] ?? "",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(width: 6),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              item["status"]
                                                      .toString()
                                                      .toLowerCase() ==
                                                  "approved"
                                              ? Colors.green.withOpacity(0.12)
                                              : item["status"]
                                                        .toString()
                                                        .toLowerCase() ==
                                                    "pending"
                                              ? Colors.orange.withOpacity(0.12)
                                              : Colors.red.withOpacity(0.12),

                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          item["status"] ?? "",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                item["status"]
                                                        .toString()
                                                        .toLowerCase() ==
                                                    "approved"
                                                ? Colors.green
                                                : item["status"]
                                                          .toString()
                                                          .toLowerCase() ==
                                                      "pending"
                                                ? Colors.orange
                                                : Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  DateFormat(
                                    "dd/MM/yy",
                                  ).format(DateTime.parse(item["date"])),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                (item["status"].toString().toLowerCase() ==
                                            "pending" ||
                                        item["status"]
                                                .toString()
                                                .toLowerCase() ==
                                            "rejected")
                                    ? InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => SalesOrderPage(
                                                isEdit: true,
                                                saleId: item["id"],
                                              ),
                                            ),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.only(left: 8),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            size: 18,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(),
                              ],
                            ),

                            const SizedBox(height: 8),

                            Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.transparent),

                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,

                                childrenPadding: EdgeInsets.zero,

                                leading: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                                ),

                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        "Items (${item["items"]?.length ?? 0})",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    Text(
                                      "₹${item["amount"]}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.green,
                                      ),
                                    ),

                                    const SizedBox(width: 6),
                                  ],
                                ),

                                children: [
                                  const SizedBox(height: 5),

                                  ...((item["items"] ?? []) as List).map((
                                    product,
                                  ) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),

                                      padding: const EdgeInsets.all(10),

                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,

                                        borderRadius: BorderRadius.circular(12),

                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),

                                      child: Row(
                                        children: [
                                          /// ITEM NAME
                                          Expanded(
                                            flex: 4,
                                            child: Text(
                                              product["item_name"] ?? "",

                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),

                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),

                                          /// QTY
                                          Expanded(
                                            child: Text(
                                              "x${product["qty"]}",

                                              textAlign: TextAlign.center,

                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),

                                          /// RATE
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              "₹${product["rate"]}",

                                              textAlign: TextAlign.right,

                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 8),

                                          /// TOTAL
                                          Text(
                                            "₹${product["amount"]}",

                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
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

  Widget _dateBox({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        height: 36,

        padding: const EdgeInsets.symmetric(horizontal: 10),

        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),

        child: Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 15,
              color: Colors.grey.shade700,
            ),

            Expanded(
              child: Text(
                title,

                textAlign: TextAlign.center,

                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    final bool isSelected = selectedStatus == status;

    Color color;

    switch (status) {
      case "approved":
        color = Colors.green;
        break;

      case "rejected":
        color = Colors.red;
        break;

      case "pending":
        color = Colors.orange;
        break;

      default:
        color = Colors.blue;
    }

    IconData icon;

    switch (status) {
      case "approved":
        icon = Icons.check_circle;
        break;

      case "rejected":
        icon = Icons.cancel;
        break;

      case "pending":
        icon = Icons.access_time_filled;
        break;

      default:
        icon = Icons.list_alt;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () async {
          selectedStatus = status;

          setState(() {});

          await fetchOrders();
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),

          height: 30,

          padding: const EdgeInsets.symmetric(horizontal: 10),

          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.08),

            borderRadius: BorderRadius.circular(20),

            border: Border.all(
              color: isSelected ? color : color.withOpacity(0.20),

              width: 0.8,
            ),
          ),

          child: Row(
            mainAxisSize: MainAxisSize.min,

            children: [
              Icon(icon, size: 11, color: isSelected ? Colors.white : color),

              const SizedBox(width: 4),

              Text(
                status[0].toUpperCase() + status.substring(1),

                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,

                  color: isSelected ? Colors.white : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
