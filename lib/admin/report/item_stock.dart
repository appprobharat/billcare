import 'package:flutter/material.dart';
import 'package:billcare/api/api_service.dart';

class ItemStockPage extends StatefulWidget {
  const ItemStockPage({super.key});

  @override
  State<ItemStockPage> createState() => _ItemStockPageState();
}

class _ItemStockPageState extends State<ItemStockPage> {
  List<Map<String, dynamic>> items = [];

  bool isLoading = false;

  final TextEditingController searchController = TextEditingController();
  String selectedSort = "Item Name A-Z";

  @override
  void initState() {
    super.initState();
    fetchStockReport();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // STOCK API
  // ==========================================

  Future<void> fetchStockReport() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint("========================================");
      debugPrint("📦 STOCK REPORT");
      debugPrint("📌 ENDPOINT: /report/stock");
      debugPrint("📤 BODY: {category_id: 0}");

      final response = await ApiService.postRequest(
        endpoint: "/report/stock",
        body: {"category_id": "0"},
      );

      debugPrint("📥 RESPONSE: $response");
      debugPrint("========================================");

      if (response is Map &&
          (response["status"] == "success" || response["status"] == true)) {
        final data = response["data"];

        if (data is List) {
          final loadedItems = data
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();

          if (mounted) {
            setState(() {
              items = loadedItems;
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
          response is Map
              ? response["message"]?.toString() ?? "Unable to fetch stock"
              : "Unable to fetch stock",
        );
      }
    } catch (e) {
      debugPrint("❌ STOCK API ERROR: $e");

      if (mounted) {
        setState(() {
          items = [];
        });
      }

      _showMessage("Something went wrong while loading stock");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // FILTER
  // ==========================================

  List<Map<String, dynamic>> get filteredItems {
    final query = searchController.text.trim().toLowerCase();

    List<Map<String, dynamic>> result = items.where((item) {
      final itemName = item["item_name"]?.toString().toLowerCase() ?? "";

      final category = item["category_name"]?.toString().toLowerCase() ?? "";

      return query.isEmpty ||
          itemName.contains(query) ||
          category.contains(query);
    }).toList();

    // =========================
    // SORTING
    // =========================
    switch (selectedSort) {
      case "Item Name A-Z":
        result.sort((a, b) {
          final nameA = a["item_name"]?.toString().toLowerCase() ?? "";
          final nameB = b["item_name"]?.toString().toLowerCase() ?? "";

          return nameA.compareTo(nameB);
        });
        break;

      case "Item Name Z-A":
        result.sort((a, b) {
          final nameA = a["item_name"]?.toString().toLowerCase() ?? "";
          final nameB = b["item_name"]?.toString().toLowerCase() ?? "";

          return nameB.compareTo(nameA);
        });
        break;

      case "Stock Low → High":
        result.sort((a, b) {
          return _stockValue(a["stock"]).compareTo(_stockValue(b["stock"]));
        });
        break;

      case "Stock High → Low":
        result.sort((a, b) {
          return _stockValue(b["stock"]).compareTo(_stockValue(a["stock"]));
        });
        break;

      case "Low Stock First":
        result.sort((a, b) {
          final stockA = _stockValue(a["stock"]);
          final stockB = _stockValue(b["stock"]);

          final lowA = stockA <= 0;
          final lowB = stockB <= 0;

          if (lowA && !lowB) return -1;
          if (!lowA && lowB) return 1;

          return stockA.compareTo(stockB);
        });
        break;
    }

    return result;
  }
  // ==========================================
  // STOCK VALUE
  // ==========================================

  double _stockValue(dynamic value) {
    return double.tryParse(value?.toString() ?? "0") ?? 0;
  }

  String _formatStock(dynamic value) {
    final stock = _stockValue(value).abs();

    if (stock == stock.roundToDouble()) {
      return stock.toInt().toString();
    }

    return stock.toStringAsFixed(2);
  }

  // ==========================================
  // MESSAGE
  // ==========================================

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

  // ==========================================
  // COUNTS
  // ==========================================

  int get lowStockCount {
    return items.where((item) {
      return _stockValue(item["stock"]) <= 0;
    }).length;
  }

  int get availableStockCount {
    return items.where((item) {
      return _stockValue(item["stock"]) > 0;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final displayItems = filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 52,
        title: const Text(
          "Item Stock",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(9),
              onTap: isLoading ? null : fetchStockReport,
              child: Container(
                height: 34,
                width: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
              ),
            ),
          ),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // ==================================
            // SEARCH + SUMMARY
            // ==================================
            Container(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
              color: Colors.white,
              child: Column(
                children: [
                  // SEARCH
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xffF7F8FA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) {
                        setState(() {});
                      },
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: "Search item or category...",
                        hintStyle: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 19,
                          color: AppColors.primary,
                        ),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded, size: 17),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 7),

                  Row(
                    children: [
                      Icon(
                        Icons.sort_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),

                      const SizedBox(width: 5),

                      Text(
                        "Sort:",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(width: 6),

                      Expanded(
                        child: Container(
                          height: 32,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xffF7F8FA),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedSort,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 17,
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "Item Name A-Z",
                                  child: Text("Item Name A-Z"),
                                ),
                                DropdownMenuItem(
                                  value: "Item Name Z-A",
                                  child: Text("Item Name Z-A"),
                                ),
                                DropdownMenuItem(
                                  value: "Stock Low → High",
                                  child: Text("Stock Low → High"),
                                ),
                                DropdownMenuItem(
                                  value: "Stock High → Low",
                                  child: Text("Stock High → Low"),
                                ),
                                DropdownMenuItem(
                                  value: "Low Stock First",
                                  child: Text("Low Stock First"),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;

                                setState(() {
                                  selectedSort = value;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 7),
                  // SUMMARY
                  Row(
                    children: [
                      Expanded(
                        child: _summaryBox(
                          title: "Total Items",
                          value: items.length.toString(),
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 7),

                      Expanded(
                        child: _summaryBox(
                          title: "Available",
                          value: availableStockCount.toString(),
                          icon: Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(width: 7),

                      Expanded(
                        child: _summaryBox(
                          title: "Low Stock",
                          value: lowStockCount.toString(),
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ==================================
            // LIST
            // ==================================
            Expanded(
              child: isLoading && items.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : displayItems.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(10, 9, 10, 12),
                      itemCount: displayItems.length,
                      itemBuilder: (context, index) {
                        return _stockCard(displayItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SUMMARY BOX
  // ==========================================

  Widget _summaryBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(.055),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),

          const SizedBox(width: 6),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 7.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
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

  // ==========================================
  // STOCK CARD
  // ==========================================

  Widget _stockCard(Map<String, dynamic> item) {
    final itemName = item["item_name"]?.toString() ?? "-";

    final category = item["category_name"]?.toString() ?? "-";

    final rawStock = item["stock"];

    final stock = _stockValue(rawStock);

    final bool isLowStock = stock <= 0;

    final Color stockColor = isLowStock ? Colors.red : Colors.green;

    final IconData stockIcon = isLowStock
        ? Icons.warning_amber_rounded
        : Icons.check_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLowStock
              ? Colors.red.withOpacity(.12)
              : Colors.grey.shade200,
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
          // ITEM ICON
          Container(
            height: 38,
            width: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isLowStock
                  ? Colors.red.withOpacity(.08)
                  : AppColors.primary.withOpacity(.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 19,
              color: isLowStock ? Colors.red : AppColors.primary,
            ),
          ),

          const SizedBox(width: 9),

          // ITEM DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 10,
                      color: Colors.grey.shade500,
                    ),

                    const SizedBox(width: 3),

                    Expanded(
                      child: Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // STOCK
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: stockColor.withOpacity(.07),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(stockIcon, size: 11, color: stockColor),

                    const SizedBox(width: 3),

                    Text(
                      _formatStock(rawStock),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 1),

                Text(
                  isLowStock ? "LOW STOCK" : "AVAILABLE",
                  style: TextStyle(
                    fontSize: 6.5,
                    fontWeight: FontWeight.w800,
                    color: stockColor.withOpacity(.75),
                    letterSpacing: .3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 55,
              width: 55,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 26,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "No items found",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),

            const SizedBox(height: 3),

            Text(
              searchController.text.isNotEmpty
                  ? "Try another search"
                  : "No stock data available",
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
