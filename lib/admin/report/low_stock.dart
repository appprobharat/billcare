import 'package:flutter/material.dart';
import 'package:billcare/api/api_service.dart';

class LowStockPage extends StatefulWidget {
  const LowStockPage({super.key});

  @override
  State<LowStockPage> createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  int selectedCategoryId = 0;
  String selectedCategory = "All";

  bool isAscending = true;
  bool isLoading = false;

  String searchText = "";

  List<Map<String, dynamic>> items = [];

  final List<Map<String, dynamic>> categories = [
    {"id": 0, "name": "All"},
  ];

  @override
  void initState() {
    super.initState();
    fetchStockReport();
  }

  /// ============================
  /// STOCK REPORT API
  /// ============================
  Future<void> fetchStockReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await ApiService.postRequest(
        endpoint: "/report/stock",
        body: {"category_id": selectedCategoryId.toString()},
      );
      debugPrint("================================");
      debugPrint("📦 STOCK REPORT API");
      debugPrint("📌 ENDPOINT: /report/stock");
      debugPrint("📤 BODY: {category_id: $selectedCategoryId}");
      debugPrint("📥 RESPONSE: $response");
      debugPrint("================================");

      if (response != null &&
          response is Map<String, dynamic> &&
          response["status"]?.toString().toLowerCase() == "success") {
        final data = response["data"];

        if (data is List) {
          final parsedItems = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => _stockValue(item["stock"]) <= 0)
              .toList();

          if (mounted) {
            setState(() {
              items = parsedItems;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              items = [];
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            items = [];
          });
        }

        _showMessage(
          response?["message"]?.toString() ?? "Unable to fetch stock report",
        );
      }
    } catch (e) {
      debugPrint("❌ STOCK REPORT ERROR: $e");

      if (mounted) {
        setState(() {
          items = [];
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

  /// ============================
  /// SEARCH + SORT
  /// ============================
  List<Map<String, dynamic>> get filteredItems {
    final query = searchText.trim().toLowerCase();

    final list = items.where((item) {
      if (query.isEmpty) return true;

      final itemName = item["item_name"]?.toString().toLowerCase() ?? "";

      final categoryName =
          item["category_name"]?.toString().toLowerCase() ?? "";

      return itemName.contains(query) || categoryName.contains(query);
    }).toList();

    list.sort((a, b) {
      final stockA = _stockValue(a["stock"]);
      final stockB = _stockValue(b["stock"]);

      return isAscending ? stockA.compareTo(stockB) : stockB.compareTo(stockA);
    });

    return list;
  }

  /// ============================
  /// STOCK VALUE
  /// ============================
  double _stockValue(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }

  /// ============================
  /// TOTAL STOCK
  /// ============================
  double get totalStock {
    return items.fold(0, (sum, item) => sum + _stockValue(item["stock"]));
  }

  /// Negative stock count
  int get negativeStockCount {
    return items.where((item) => _stockValue(item["stock"]) < 0).length;
  }

  /// Zero stock count
  int get zeroStockCount {
    return items.where((item) => _stockValue(item["stock"]) == 0).length;
  }

  /// ============================
  /// CATEGORY SELECT
  /// ============================
  void onCategoryChanged(Map<String, dynamic> category) {
    setState(() {
      selectedCategoryId = category["id"] ?? 0;
      selectedCategory = category["name"]?.toString() ?? "All";
    });

    fetchStockReport();
  }

  /// ============================
  /// MESSAGE
  /// ============================
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }


  String _formatStock(double value) {
    final displayValue = value.abs();

    if (displayValue == displayValue.roundToDouble()) {
      return displayValue.toInt().toString();
    }

    return displayValue.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      /// ============================
      /// APP BAR
      /// ============================
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 54,
        title: const Text(
          "Low Stock",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),

      body: Column(
        children: [
          /// ============================
          /// TOP PANEL
          /// ============================
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Column(
              children: [
                /// SUMMARY
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        icon: Icons.inventory_2_outlined,
                        title: "Items",
                        value: "${items.length}",
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: _summaryCard(
                        icon: Icons.warning_amber_rounded,
                        title: "Negative",
                        value: "$negativeStockCount",
                        color: Colors.red,
                      ),
                    ),

                    const SizedBox(width: 8),

                    Expanded(
                      child: _summaryCard(
                        icon: Icons.remove_circle_outline,
                        title: "Zero",
                        value: "$zeroStockCount",
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                /// SEARCH
                Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xffF7F8FA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 7),

                      Expanded(
                        child: TextField(
                          style: const TextStyle(fontSize: 12),
                          decoration: const InputDecoration(
                            hintText: "Search item or category...",
                            hintStyle: TextStyle(fontSize: 12),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchText = value;
                            });
                          },
                        ),
                      ),

                      if (searchText.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              searchText = "";
                            });
                          },
                          child: const Icon(Icons.close_rounded, size: 17),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                /// CATEGORY + SORT + REFRESH
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xffF7F8FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.category_outlined,
                              size: 16,
                              color: AppColors.primary,
                            ),

                            const SizedBox(width: 6),

                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: selectedCategoryId,
                                  isExpanded: true,
                                  isDense: true,
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    size: 17,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  items: categories.map((category) {
                                    return DropdownMenuItem<int>(
                                      value: category["id"],
                                      child: Text(
                                        category["name"].toString(),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value == null) return;

                                    final category = categories.firstWhere(
                                      (e) => e["id"] == value,
                                    );

                                    onCategoryChanged(category);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 7),

                    /// SORT
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xffF7F8FA),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          _sortButton(
                            icon: Icons.arrow_upward_rounded,
                            selected: isAscending,
                            onTap: () {
                              setState(() {
                                isAscending = true;
                              });
                            },
                          ),

                          _sortButton(
                            icon: Icons.arrow_downward_rounded,
                            selected: !isAscending,
                            onTap: () {
                              setState(() {
                                isAscending = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 7),

                    /// REFRESH
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: isLoading ? null : fetchStockReport,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(11),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.refresh_rounded,
                                size: 19,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// ============================
          /// LIST HEADER
          /// ============================
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 7),
            child: Row(
              children: [
                const Text(
                  "Stock Items",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),

                const SizedBox(width: 7),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "${list.length}",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                const Spacer(),

                Text(
                  isAscending ? "Lowest first" : "Highest first",
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          /// ============================
          /// LOADING
          /// ============================
          if (isLoading && items.isEmpty)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          /// ============================
          /// EMPTY
          /// ============================
          else if (list.isEmpty)
            Expanded(child: _emptyState())
          /// ============================
          /// LIST
          /// ============================
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 15),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  return _stockCard(item: list[index], index: index);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// ============================
  /// SUMMARY CARD
  /// ============================
  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(.06),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: color.withOpacity(.12)),
      ),
      child: Row(
        children: [
          Container(
            height: 31,
            width: 31,
            decoration: BoxDecoration(
              color: color.withOpacity(.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),

          const SizedBox(width: 6),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================
  /// SORT BUTTON
  /// ============================
  Widget _sortButton({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 31,
        width: 31,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? AppColors.primary : Colors.grey.shade500,
        ),
      ),
    );
  }

  /// ============================
  /// STOCK CARD
  /// ============================
  Widget _stockCard({required Map<String, dynamic> item, required int index}) {
    final double stock = _stockValue(item["stock"]);

    final bool negative = stock < 0;
    final bool zero = stock == 0;

    final Color statusColor = negative
        ? Colors.red
        : zero
        ? Colors.orange
        : Colors.green;

    final String statusText = negative
        ? "Negative"
        : zero
        ? "Out of Stock"
        : "Available";

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: negative ? Colors.red.withOpacity(.18) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          /// NUMBER
          Container(
            height: 34,
            width: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.07),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              "${index + 1}",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(width: 10),

          /// ITEM DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["item_name"]?.toString() ?? "-",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 5),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        item["category_name"]?.toString() ?? "-",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    Icon(
                      negative
                          ? Icons.trending_down_rounded
                          : zero
                          ? Icons.remove_circle_outline
                          : Icons.check_circle_outline,
                      size: 12,
                      color: statusColor,
                    ),

                    const SizedBox(width: 3),

                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 9,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 9),

          /// STOCK
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(.07),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Column(
              children: [
                Text(
                  _formatStock(stock),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                Text(
                  "STOCK",
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: statusColor.withOpacity(.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ============================
  /// EMPTY STATE
  /// ============================
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 30,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 11),

          const Text(
            "No stock records found",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 4),

          Text(
            "No items are available for this category.",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
