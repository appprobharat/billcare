import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/helper.dart';

class LedgerPage extends StatefulWidget {
  const LedgerPage({super.key});

  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  DateTime toDate = DateTime.now();

  DateTime fromDate = DateTime(
    DateTime.now().year,
    DateTime.now().month - 1,
    DateTime.now().day,
  );

  String selectedType = "Party";

  Map<String, dynamic>? selectedPerson;

  bool isLoading = false;

  Map<String, dynamic>? ledgerResponse;

  final List<String> reportTypes = ["Party", "Employee", "Supplier"];

  List<Map<String, dynamic>> persons = [];

  List<Map<String, dynamic>> get transactions {
    final data = ledgerResponse?["transactions"];

    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  @override
  void initState() {
    super.initState();

    selectedType = "Party";

    fetchNames("Party");
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
      });
    }
  }

  Future<void> fetchNames(String type) async {
    try {
      final response = await ApiService.postRequest(
        endpoint: "/get_name",
        body: {"Type": type},
      );

      if (response is List) {
        final loadedPersons = response
            .whereType<Map>()
            .map((e) {
              return <String, dynamic>{
                "id": e["id"],
                "name": e["Name"]?.toString() ?? "-",
                "contact": e["ContactNo"]?.toString() ?? "-",
              };
            })
            .where((e) => e["name"] != "-")
            .toList();

        if (mounted) {
          setState(() {
            persons = List<Map<String, dynamic>>.from(loadedPersons);
            selectedPerson = null;
          });
        }

        if (loadedPersons.isEmpty) {
          _showMessage("No $type found");
        }
      } else {
        if (mounted) {
          setState(() {
            persons = [];
            selectedPerson = null;
          });
        }

        _showMessage("Unable to fetch $type");
      }
    } catch (e) {
      debugPrint("❌ GET NAMES API ERROR: $e");

      if (mounted) {
        setState(() {
          persons = [];
          selectedPerson = null;
        });
      }

      _showMessage("Something went wrong while loading names");
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

  Future<void> fetchLedger() async {
    if (selectedPerson == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a name")));
      return;
    }

    if (fromDate.isAfter(toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("From date cannot be greater than To date"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.postRequest(
        endpoint: "/report/ledger",
        body: {
          "type": selectedType.toString(),
          "id": selectedPerson!["id"].toString(),
          "from_date": DateFormat("yyyy-MM-dd").format(fromDate),
          "to_date": DateFormat("yyyy-MM-dd").format(toDate),
        },
      );

      debugPrint("LEDGER API RESPONSE: $response");

      if (response != null &&
          response is Map<String, dynamic> &&
          response["status"] == true) {
        setState(() {
          ledgerResponse = response["data"];
        });
      } else {
        setState(() {
          ledgerResponse = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response?["message"]?.toString() ?? "Unable to fetch ledger",
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("LEDGER API ERROR: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final company = ledgerResponse?["company"] as Map<String, dynamic>?;
    final party = ledgerResponse?["party"] as Map<String, dynamic>?;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 52,
        title: const Text(
          "Ledger",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),

      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // FILTER PANEL
            // =========================
            Container(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(18),
                ),
              ),
              child: Column(
                children: [
                  // DATE
                  Row(
                    children: [
                      Expanded(
                        child: _dateBox("From", fromDate, () => pickDate(true)),
                      ),

                      const SizedBox(width: 7),

                      Expanded(
                        child: _dateBox("To", toDate, () => pickDate(false)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),

                  // TYPE + NAME
                  Row(
                    children: [
                      Expanded(
                        child: OverlayDropdown(
                          label: "",
                          value: selectedType,
                          items: reportTypes,
                          onSelect: (v) {
                            setState(() {
                              selectedType = v;
                              selectedPerson = null;
                              persons = [];
                              ledgerResponse = null;
                            });

                            fetchNames(v);
                          },
                        ),
                      ),

                      const SizedBox(width: 7),

                      Expanded(
                        flex: 2,
                        child: OverlayDropdown(
                          label: "",
                          value: selectedPerson?["name"] ?? "Select Name",
                          items: persons
                              .map((e) => e["name"].toString())
                              .toList(),
                          onSelect: (name) {
                            final person = persons.firstWhere(
                              (e) => e["name"].toString() == name,
                              orElse: () => {},
                            );

                            setState(() {
                              selectedPerson = person.isNotEmpty
                                  ? person
                                  : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // FETCH BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : fetchLedger,
                      icon: isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.sync_rounded, size: 17),
                      label: Text(
                        isLoading ? "Fetching..." : "Fetch Ledger",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =========================
            // LEDGER CONTENT
            // =========================
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.035),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ==========================================
                      // COMPANY HEADER
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          children: [
                            // =========================
                            // COMPANY NAME
                            // =========================
                            Row(
                              children: [
                                Container(
                                  height: 36,
                                  width: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(.08),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.business_rounded,
                                    size: 18,
                                    color: AppColors.primary,
                                  ),
                                ),

                                const SizedBox(width: 9),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        company?["name"]?.toString() ??
                                            "Company",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),

                                      const SizedBox(height: 2),

                                      Text(
                                        company?["address"]?.toString() ?? "-",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 9),

                            // =========================
                            // COMPANY DETAILS
                            // =========================
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffF7F8FA),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _infoItem(
                                      Icons.phone_outlined,
                                      company?["contact"]?.toString() ?? "-",
                                    ),
                                  ),

                                  // SPACE + DIVIDER
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Container(
                                      height: 18,
                                      width: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),

                                  Expanded(
                                    flex: 2,
                                    child: _infoItem(
                                      Icons.email_outlined,
                                      company?["email"]?.toString() ?? "-",
                                    ),
                                  ),

                                  // SPACE + DIVIDER
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Container(
                                      height: 18,
                                      width: 1,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),

                                  Expanded(
                                    flex: 2,
                                    child: _infoItem(
                                      Icons.verified_outlined,
                                      company?["gstin"]?.toString() ?? "-",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Divider(height: 1, color: Colors.grey.shade200),

                      // ==========================================
                      // PARTY INFO
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 9, 12, 8),
                        child: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(0xffF7F8FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 34,
                                width: 34,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(.09),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  (party?["name"]?.toString() ??
                                              selectedPerson?["name"]
                                                  ?.toString() ??
                                              "P")
                                          .trim()
                                          .isNotEmpty
                                      ? (party?["name"]?.toString() ??
                                                selectedPerson?["name"]
                                                    ?.toString() ??
                                                "P")[0]
                                            .toUpperCase()
                                      : "P",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      party?["name"]?.toString() ??
                                          selectedPerson?["name"]?.toString() ??
                                          "-",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "ID: ${party?["id"]?.toString() ?? selectedPerson?["id"]?.toString() ?? "-"}",
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(width: 8),

                              // IMPORTANT: constrained right side
                              SizedBox(
                                width: 105,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      party?["contact"]
                                                  ?.toString()
                                                  .trim()
                                                  .isNotEmpty ==
                                              true
                                          ? party!["contact"].toString()
                                          : "No contact",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),

                                    const SizedBox(height: 2),

                                    Text(
                                      party?["address"]?.toString() ?? "-",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ==========================================
                      // BALANCE SUMMARY
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: _balanceBox(
                                "Opening",
                                ledgerResponse?["opening_balance"],
                                Colors.orange,
                              ),
                            ),

                            const SizedBox(width: 8),

                            Expanded(
                              child: _balanceBox(
                                "Closing",
                                ledgerResponse?["closing_balance"],
                                AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ==========================================
                      // PERIOD
                      // ==========================================
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range_outlined,
                              size: 13,
                              color: Colors.grey.shade500,
                            ),

                            const SizedBox(width: 5),

                            Expanded(
                              child: Text(
                                "Period: ${ledgerResponse?["period"]?["from"] ?? DateFormat("dd-MM-yyyy").format(fromDate)}"
                                " - "
                                "${ledgerResponse?["period"]?["to"] ?? DateFormat("dd-MM-yyyy").format(toDate)}",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 6),

                      Divider(height: 1, color: Colors.grey.shade200),

                      // ==========================================
                      // TRANSACTIONS
                      // ==========================================
                      Expanded(
                        child: transactions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      height: 52,
                                      width: 52,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(
                                          .07,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.receipt_long_outlined,
                                        color: AppColors.primary,
                                        size: 25,
                                      ),
                                    ),

                                    const SizedBox(height: 9),

                                    const Text(
                                      "No transactions",
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(height: 3),

                                    Text(
                                      "No ledger entries found",
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  10,
                                  5,
                                ),
                                itemCount: transactions.length,
                                itemBuilder: (context, index) {
                                  return _ledgerTransactionCard(
                                    transactions[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 11, color: AppColors.primary),

        const SizedBox(width: 4),

        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _balanceBox(String title, dynamic value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.055),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),

          Text(
            "₹ ${_formatAmount(value)}",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(dynamic value) {
    final number = double.tryParse(value?.toString() ?? "0") ?? 0;

    return number.toStringAsFixed(2);
  }

  Widget _ledgerTransactionCard(Map<String, dynamic> item) {
    final particular = item["particular"]?.toString() ?? "-";

    final date = item["date"]?.toString() ?? "-";

    final refNo = item["ref_no"]?.toString().trim();

    final debitValue = double.tryParse(item["debit"]?.toString() ?? "0") ?? 0;

    final creditValue = double.tryParse(item["credit"]?.toString() ?? "0") ?? 0;

    final bool isDebit = debitValue > 0;

    final double amount = isDebit ? debitValue : creditValue;

    final Color amountColor = isDebit ? Colors.red : Colors.green;

    final String type = isDebit ? "DEBIT" : "CREDIT";

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: amountColor.withOpacity(.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =================================
          // SALE / RECEIPT + AMOUNT
          // =================================
          Row(
            children: [
              Expanded(
                child: Text(
                  particular,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                "₹ ${_formatAmount(amount)}",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // =================================
          // DATE + INVOICE + DEBIT/CREDIT
          // =================================
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 10,
                color: Colors.grey.shade500,
              ),

              const SizedBox(width: 4),

              Text(
                date,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
              ),

              if (refNo != null && refNo.isNotEmpty) ...[
                const SizedBox(width: 7),

                Text(
                  "•",
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade400),
                ),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    refNo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else
                const Spacer(),

              // DEBIT / CREDIT
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(.09),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: amountColor,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🔽 DATE BOX
  Widget _dateBox(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: const Color(0xffF7F8FA),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: AppColors.primary,
            ),

            const SizedBox(width: 6),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 7,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat("dd MMM yyyy").format(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
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
