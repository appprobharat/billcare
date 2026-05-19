import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ApproveSalePage extends StatefulWidget {
  const ApproveSalePage({super.key});

  @override
  State<ApproveSalePage> createState() => _ApproveSalePageState();
}

class _ApproveSalePageState extends State<ApproveSalePage> {
  bool isLoading = true;

  List<dynamic> pendingOrders = [];
  DateTime? fromDate;
  DateTime? toDate;
  String selectedStatus = "pending";

  TextEditingController searchController = TextEditingController();

  List<dynamic> allOrders = [];
  List<dynamic> filteredOrders = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    toDate = today;
    fromDate = today.subtract(const Duration(days: 30));
    fetchPendingOrders();
  }

  void applyFilter() {
    final query = searchController.text.trim().toLowerCase();

    filteredOrders = allOrders.where((order) {
      final name = (order["client_name"] ?? "").toString().toLowerCase();

      final contact = (order["contact_no"] ?? "").toString().toLowerCase();

      final status = (order["status"] ?? "").toString().toLowerCase();

      final matchesSearch = name.contains(query) || contact.contains(query);

      final matchesStatus = selectedStatus == "all"
          ? true
          : status == selectedStatus;

      return matchesSearch && matchesStatus;
    }).toList();

    setState(() {});
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

      await fetchPendingOrders();
    }
  }

  Future<void> fetchPendingOrders() async {
    setState(() {
      isLoading = true;
    });

    final from = DateFormat("yyyy-MM-dd").format(fromDate!);

    final to = DateFormat("yyyy-MM-dd").format(toDate!);

    final body = {
      "status": selectedStatus == "all" ? "" : selectedStatus,

      "from": from,
      "to": to,
    };

    debugPrint("📤 REQUEST BODY: $body");

    final res = await ApiService.postRequest(
      endpoint: "/sale/requests",
      body: body,
    );

    debugPrint("📥 RESPONSE: $res");

    if (res != null && res["status"] == true && res["data"] != null) {
      allOrders = List<dynamic>.from(res["data"]);

      applyFilter();
    } else {
      allOrders = [];
      filteredOrders = [];
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> approveOrder(int requestId) async {
    final res = await ApiService.postRequest(
      endpoint: "/sale/approve",
      body: {"request_id": requestId.toString()},
    );

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order Approved Successfully"),
          backgroundColor: Colors.green,
        ),
      );

      fetchPendingOrders();
    }
  }

  Future<void> rejectOrder(int requestId, String reason) async {
    final res = await ApiService.postRequest(
      endpoint: "/sale/reject",
      body: {"request_id": requestId.toString(), "reason": reason},
    );

    if (res != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Order Rejected"),
          backgroundColor: Colors.red,
        ),
      );

      fetchPendingOrders();
    }
  }

  void showRejectDialog(int requestId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reject Order"),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "Enter rejection reason",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonController.text.trim().isEmpty) {
                  return;
                }

                Navigator.pop(context);

                rejectOrder(requestId, reasonController.text.trim());
              },
              child: const Text("Reject"),
            ),
          ],
        );
      },
    );
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        title: const Text("Approve Sales"),
        elevation: 0,
        centerTitle: true,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : filteredOrders.isEmpty
          ? const Center(
              child: Text(
                "No Pending Orders",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            )
          : Column(
              children: [
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

                Container(
                  height: 52,

                  decoration: BoxDecoration(
                    color: Colors.white,

                    borderRadius: BorderRadius.circular(14),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: TextField(
                    controller: searchController,

                    onChanged: (value) {
                      applyFilter();
                    },

                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),

                    decoration: InputDecoration(
                      hintText: "Search by customer or mobile",

                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),

                      prefixIcon: Container(
                        margin: const EdgeInsets.all(8),

                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),

                        child: const Icon(
                          Icons.search_rounded,
                          color: Colors.blue,
                          size: 22,
                        ),
                      ),

                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                                applyFilter();
                                setState(() {});
                              },

                              icon: const Icon(Icons.close_rounded, size: 20),
                            )
                          : null,

                      filled: true,
                      fillColor: Colors.white,

                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.blue.shade300,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),

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
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];

                      final status = order["status"]?.toString() ?? "pending";

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),

                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),

                            childrenPadding: const EdgeInsets.fromLTRB(
                              14,
                              0,
                              14,
                              14,
                            ),

                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),

                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(20),
                                      ),

                                      child: const Icon(
                                        Icons.person_outline,
                                        size: 15,
                                        color: Colors.blue,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: Text(
                                        order["client_name"] ?? "",

                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,

                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today_outlined,
                                          size: 11,
                                          color: Colors.grey.shade500,
                                        ),

                                        const SizedBox(width: 4),

                                        Text(
                                          order["date"] ?? "",

                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                Row(
                                  children: [
                                    Icon(
                                      Icons.call_outlined,
                                      size: 13,
                                      color: Colors.grey.shade500,
                                    ),

                                    const SizedBox(width: 4),

                                    Text(
                                      order["contact_no"].toString(),

                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),

                                    const Spacer(),

                                    Text(
                                      "₹${order["grand_total"]}",

                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),

                                      decoration: BoxDecoration(
                                        color: getStatusColor(
                                          status,
                                        ).withOpacity(0.12),

                                        borderRadius: BorderRadius.circular(30),
                                      ),

                                      child: Text(
                                        status.toUpperCase(),

                                        style: TextStyle(
                                          color: getStatusColor(status),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            children: [
                              const Divider(height: 20),

                              ...(order["items"] as List).map((product) {
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
                                        flex: 3,
                                        child: Text(
                                          product["item_name"] ?? "",

                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),

                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      /// RATE x QTY
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          "₹${product["rate"]} x ${product["qty"]}",

                                          textAlign: TextAlign.center,

                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ),

                                      /// GST
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "₹${product["gst_amount"]}",

                                          textAlign: TextAlign.center,

                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.orange.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),

                                      /// AMOUNT
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "₹${product["amount"]}",

                                          textAlign: TextAlign.right,

                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 12),

                              /// REJECT REASON
                              if (status == "rejected")
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),

                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        color: Colors.red,
                                        size: 18,
                                      ),

                                      const SizedBox(width: 8),

                                      Expanded(
                                        child: Text(
                                          order["rejection_reason"] ??
                                              "No reason",

                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              /// BUTTONS
                              if (status == "pending")
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 34,

                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            approveOrder(order["id"]);
                                          },

                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            size: 14,
                                          ),

                                          label: const Text(
                                            "Approve",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,

                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,

                                            padding: EdgeInsets.zero,

                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    Expanded(
                                      child: SizedBox(
                                        height: 34,

                                        child: ElevatedButton.icon(
                                          onPressed: () {
                                            showRejectDialog(order["id"]);
                                          },

                                          icon: const Icon(
                                            Icons.close,
                                            size: 14,
                                          ),

                                          label: const Text(
                                            "Reject",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),

                                          style: ElevatedButton.styleFrom(
                                            elevation: 0,

                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,

                                            padding: EdgeInsets.zero,

                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                 
                              if (status == "approved")
                                Container(
                                  width: double.infinity,

                                  padding: const EdgeInsets.all(12),

                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.08),

                                    borderRadius: BorderRadius.circular(10),
                                  ),

                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,

                                    children: [
                                      Icon(
                                        Icons.lock_outline,
                                        color: Colors.green,
                                        size: 18,
                                      ),

                                      SizedBox(width: 8),

                                      Text(
                                        "Approved & Locked",

                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              /// REJECTED
                              if (status == "rejected")
                                SizedBox(
                                  width: double.infinity,

                                  child: ElevatedButton.icon(
                                    onPressed: () {},

                                    icon: const Icon(Icons.edit_outlined),

                                    label: const Text("Edit Order"),

                                    style: ElevatedButton.styleFrom(
                                      elevation: 0,

                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),

                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
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

          await fetchPendingOrders();
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
