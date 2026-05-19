import 'package:billcare/Usersfolder/orders/user_order.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:billcare/api/api_service.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
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
      endpoint: "/client/sale/list",

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
                  MaterialPageRoute(builder: (_) => const UserOrderPage()),
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

          // 🔹 Status Filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: ["all", "pending", "approved", "rejected"].map((
                status,
              ) {
                final isSelected = selectedStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        selectedStatus = status;
                      });

                      await fetchOrders();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 🔹 Search
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          //   child: Container(
          //     height: 48,
          //     decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(14),
          //       boxShadow: [
          //         BoxShadow(
          //           color: Colors.black.withOpacity(0.05),
          //           blurRadius: 8,
          //           offset: const Offset(0, 2),
          //         ),
          //       ],
          //     ),
          //     child: TextField(
          //       controller: _searchController,
          //       style: const TextStyle(
          //         fontSize: 14,
          //         fontWeight: FontWeight.w500,
          //       ),
          //       decoration: InputDecoration(
          //         hintText: "Search invoice or item...",
          //         hintStyle: TextStyle(
          //           color: Colors.grey.shade500,
          //           fontSize: 13,
          //         ),

          //         /// LEFT SEARCH ICON
          //         prefixIcon: Icon(
          //           Icons.search_rounded,
          //           size: 20,
          //           color: Colors.grey.shade700,
          //         ),

          //         /// CLEAR BUTTON
          //         suffixIcon: _searchController.text.isNotEmpty
          //             ? IconButton(
          //                 icon: const Icon(Icons.close_rounded, size: 18),
          //                 onPressed: () {
          //                   _searchController.clear();
          //                   applyFilter();
          //                   setState(() {});
          //                 },
          //               )
          //             : null,

          //         filled: true,
          //         fillColor: Colors.white,

          //         contentPadding: const EdgeInsets.symmetric(
          //           horizontal: 14,
          //           vertical: 0,
          //         ),

          //         enabledBorder: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(14),
          //           borderSide: BorderSide(color: Colors.grey.shade300),
          //         ),

          //         focusedBorder: OutlineInputBorder(
          //           borderRadius: BorderRadius.circular(14),
          //           borderSide: BorderSide(
          //             color: Colors.blue.shade400,
          //             width: 1.2,
          //           ),
          //         ),
          //       ),

          //       onChanged: (_) {
          //         setState(() {});
          //         applyFilter();
          //       },
          //     ),
          //   ),
          // ),

          // 🔹 List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
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
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        item["invoice_no"] ?? "",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                Text(
                                  "₹${item["amount"]}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: _mini(
                                    Icons.calendar_today,
                                    item["date"] ?? "",
                                  ),
                                ),

                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,

                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),

                                      decoration: BoxDecoration(
                                        color:
                                            item["status"]
                                                    .toString()
                                                    .toLowerCase() ==
                                                "pending"
                                            ? Colors.orange.withOpacity(0.12)
                                            : item["status"]
                                                      .toString()
                                                      .toLowerCase() ==
                                                  "approved"
                                            ? Colors.green.withOpacity(0.12)
                                            : Colors.red.withOpacity(0.12),

                                        borderRadius: BorderRadius.circular(20),
                                      ),

                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.circle,
                                            size: 8,

                                            color:
                                                item["status"]
                                                        .toString()
                                                        .toLowerCase() ==
                                                    "pending"
                                                ? Colors.orange
                                                : item["status"]
                                                          .toString()
                                                          .toLowerCase() ==
                                                      "approved"
                                                ? Colors.green
                                                : Colors.red,
                                          ),

                                          const SizedBox(width: 5),

                                          Text(
                                            item["status"] ?? "",

                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,

                                              color:
                                                  item["status"]
                                                          .toString()
                                                          .toLowerCase() ==
                                                      "pending"
                                                  ? Colors.orange
                                                  : item["status"]
                                                            .toString()
                                                            .toLowerCase() ==
                                                        "approved"
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                item["status"].toString().toLowerCase() ==
                                        "pending"
                                    ? IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => UserOrderPage(
                                                isEdit: true,
                                                saleId: item["id"],
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit_outlined),
                                      )
                                    : const Padding(
                                        padding: EdgeInsets.only(right: 10),
                                        child: Icon(
                                          Icons.lock_outline,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                      ),
                              ],
                            ),

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

                                title: Text(
                                  "Items (${item["items"]?.length ?? 0})",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                children: [
                                  const SizedBox(height: 5),

                                  ...(item["items"] as List).map((product) {
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

  Widget _mini(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _dateBox({required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(title, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
