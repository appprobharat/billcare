import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);
  DateTime toDate = DateTime.now();

  DateTime fromDate = DateTime(
    DateTime.now().year,
    DateTime.now().month - 1,
    DateTime.now().day,
  );

  List<Map<String, dynamic>> transactions = [];

  bool isLoading = false;

  // Filters
  String selectedTransactionType = "All";
  String selectedEntityType = "All";

  @override
  void initState() {
    super.initState();

    fromDateController.text = DateFormat('dd-MM-yyyy').format(fromDate);

    toDateController.text = DateFormat('dd-MM-yyyy').format(toDate);

    fetchTransactions();
  }

  List<Map<String, dynamic>> get filteredTransactions {
    final from = normalize(fromDate);
    final to = normalize(toDate);

    return transactions.where((t) {
      // -------------------------
      // DATE FILTER
      // -------------------------
      final dateString = t["date"]?.toString();

      if (dateString == null || dateString.isEmpty) {
        return false;
      }

      DateTime transactionDate;

      try {
        transactionDate = DateFormat("dd-MM-yyyy").parse(dateString);
      } catch (_) {
        return false;
      }

      transactionDate = normalize(transactionDate);

      if (transactionDate.isBefore(from) || transactionDate.isAfter(to)) {
        return false;
      }

      // -------------------------
      // RECEIPT / PAYMENT FILTER
      // -------------------------
      if (selectedTransactionType != "All") {
        final transactionType = t["transaction_type"]?.toString() ?? "";

        if (transactionType.toLowerCase() !=
            selectedTransactionType.toLowerCase()) {
          return false;
        }
      }

      // -------------------------
      // PARTY / SUPPLIER / EMPLOYEE
      // -------------------------
      if (selectedEntityType != "All") {
        final entityType = t["type"]?.toString() ?? "";

        if (entityType.toLowerCase() != selectedEntityType.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Future<void> fetchTransactions() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.postRequest(
        endpoint: "/report/transactions",
        body: {
          "from_date": DateFormat("yyyy-MM-dd").format(fromDate),
          "to_date": DateFormat("yyyy-MM-dd").format(toDate),
        },
      );

      debugPrint("================================");
      debugPrint("📦 TRANSACTION REPORT API");
      debugPrint("📌 ENDPOINT: /report/transactions");
      debugPrint(
        "📤 BODY: {from_date: ${DateFormat("yyyy-MM-dd").format(fromDate)}, "
        "to_date: ${DateFormat("yyyy-MM-dd").format(toDate)}}",
      );
      debugPrint("📥 RESPONSE: $response");
      debugPrint("================================");

      if (response != null && response is Map && response["status"] == true) {
        final data = response["data"];

        if (data is Map && data["transactions"] is List) {
          final List<Map<String, dynamic>> parsedTransactions =
              (data["transactions"] as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();

          if (mounted) {
            setState(() {
              transactions = parsedTransactions;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              transactions = [];
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            transactions = [];
          });
        }

        _showMessage(
          response?["message"]?.toString() ?? "Unable to fetch transactions",
        );
      }
    } catch (e) {
      debugPrint("❌ TRANSACTION API ERROR: $e");

      if (mounted) {
        setState(() {
          transactions = [];
        });
      }

      _showMessage("Something went wrong. Please try again.");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> pickFromDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => fromDate = picked);
    }
  }

  Future<void> pickToDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() => toDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 54,
        title: const Text(
          "All Transactions",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                /// FIRST ROW (date + search)
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildDateField("From", fromDateController),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: _buildDateField("To", toDateController),
                    ),
                    const SizedBox(width: 6),
                    Expanded(flex: 1, child: _buildSearchButton()),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),
          _buildTransactionFilters(),
          const SizedBox(height: 5),

          /// --- LIST OF TRANSACTIONS ---
          Expanded(
            child: isLoading && transactions.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filteredTransactions.isEmpty
                ? const Center(child: Text("No transactions found"))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 15),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      return _transactionCard(
                        transaction: filteredTransactions[index],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () async {
        DateTime initialDate;

        try {
          initialDate = controller.text.isEmpty
              ? DateTime.now()
              : DateFormat('dd-MM-yyyy').parse(controller.text);
        } catch (e) {
          initialDate = DateTime.now();
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );

        if (picked != null) {
          setState(() {
            controller.text = DateFormat('dd-MM-yyyy').format(picked);

            if (label == "From") {
              fromDate = picked;
            } else {
              toDate = picked;
            }
          });
        }
      },
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: const OutlineInputBorder(),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
      ),
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      width: 48,
      height: 40,
      child: ElevatedButton(
        onPressed: isLoading
            ? null
            : () {
                FocusScope.of(context).unfocus();

                if (fromDate.isAfter(toDate)) {
                  _showMessage("From date cannot be greater than To date");
                  return;
                }

                fetchTransactions();
              },

        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          minimumSize: const Size(48, 48),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.search, size: 20),
      ),
    );
  }

  Widget _transactionCard({required Map<String, dynamic> transaction}) {
    final name = transaction["name"]?.toString() ?? "-";
    final entityType = transaction["type"]?.toString() ?? "-";
    final transactionType = transaction["transaction_type"]?.toString() ?? "-";

    final date = transaction["date"]?.toString() ?? "-";
    final amount = transaction["amount"]?.toString() ?? "0";
    final refNo = transaction["ref_no"]?.toString() ?? "-";
    final paymentMode = transaction["payment_mode"]?.toString() ?? "-";

    final remark = transaction["remark"]?.toString();

    final bool isReceipt = transactionType.toLowerCase() == "receipt";

    final bool isPayment = transactionType.toLowerCase() == "payment";

    final Color transactionColor = isReceipt
        ? Colors.green
        : isPayment
        ? Colors.red
        : AppColors.primary;

    final IconData transactionIcon = isReceipt
        ? Icons.south_west_rounded
        : isPayment
        ? Icons.north_east_rounded
        : Icons.swap_horiz_rounded;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: transactionColor.withOpacity(.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // =====================================
          // TRANSACTION ICON
          // =====================================
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: transactionColor.withOpacity(.09),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(transactionIcon, size: 19, color: transactionColor),
          ),

          const SizedBox(width: 9),

          // =====================================
          // DETAILS
          // =====================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // NAME + DATE
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    Text(
                      date,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: transactionColor.withOpacity(.10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: transactionColor.withOpacity(.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            transactionIcon,
                            size: 11,
                            color: transactionColor,
                          ),

                          const SizedBox(width: 3),

                          Text(
                            transactionType.toUpperCase(),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: transactionColor,
                              letterSpacing: .3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 5),

                    // PARTY / SUPPLIER / EMPLOYEE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        entityType,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    // PARTICULAR
                  ],
                ),

                const SizedBox(height: 4),

                // REF + PAYMENT MODE
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        "Ref: $refNo",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(.07),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        paymentMode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue,
                        ),
                      ),
                    ),

                    if (remark != null && remark.trim().isNotEmpty) ...[
                      const SizedBox(width: 5),

                      Flexible(
                        child: Text(
                          "• ${remark.trim()}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // =====================================
          // AMOUNT
          // =====================================
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹ $amount",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: transactionColor,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                isReceipt
                    ? "RECEIVED"
                    : isPayment
                    ? "PAID"
                    : "AMOUNT",
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  color: transactionColor.withOpacity(.75),
                  letterSpacing: .4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionFilters() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          _filterChip(
            label: "All",
            selected:
                selectedTransactionType == "All" && selectedEntityType == "All",
            onTap: () {
              setState(() {
                selectedTransactionType = "All";
                selectedEntityType = "All";
              });
            },
          ),

          _filterChip(
            label: "Receipt",
            icon: Icons.south_west_rounded,
            color: Colors.green,
            selected: selectedTransactionType == "Receipt",
            onTap: () {
              setState(() {
                selectedTransactionType = "Receipt";
                selectedEntityType = "All";
              });
            },
          ),

          _filterChip(
            label: "Payment",
            icon: Icons.north_east_rounded,
            color: Colors.red,
            selected: selectedTransactionType == "Payment",
            onTap: () {
              setState(() {
                selectedTransactionType = "Payment";
                selectedEntityType = "All";
              });
            },
          ),

          _filterChip(
            label: "Party",
            icon: Icons.person_outline,
            color: AppColors.primary,
            selected: selectedEntityType == "Party",
            onTap: () {
              setState(() {
                selectedEntityType = "Party";
                selectedTransactionType = "All";
              });
            },
          ),

          _filterChip(
            label: "Supplier",
            icon: Icons.storefront_outlined,
            color: Colors.orange,
            selected: selectedEntityType == "Supplier",
            onTap: () {
              setState(() {
                selectedEntityType = "Supplier";
                selectedTransactionType = "All";
              });
            },
          ),

          _filterChip(
            label: "Employee",
            icon: Icons.badge_outlined,
            color: Colors.purple,
            selected: selectedEntityType == "Employee",
            onTap: () {
              setState(() {
                selectedEntityType = "Employee";
                selectedTransactionType = "All";
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    Color? color,
  }) {
    final chipColor = color ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? chipColor : Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: selected ? chipColor : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: selected ? Colors.white : chipColor,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
