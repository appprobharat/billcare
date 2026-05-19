import 'package:flutter/material.dart';

class ItemStockReportPage extends StatefulWidget {
  const ItemStockReportPage({super.key});

  @override
  State<ItemStockReportPage> createState() => _ItemStockReportPageState();
}

class _ItemStockReportPageState extends State<ItemStockReportPage> {
  String selectedMonth = "May 2026";
  String selectedCategory = "All";

  List<String> months = ["May 2026", "April 2026"];
  List<String> categories = ["All", "Electronics", "Grocery"];

  List<Map<String, dynamic>> items = [
    {
      "cat": "Electronics",
      "name": "Mouse",
      "opening": 10,
      "purchase": 5,
      "sale": 8,
      "pReturn": 1,
      "sReturn": 0,
      "proIn": 2,
      "proOut": 1,
      "stock": 7,
    },
    {
      "cat": "Grocery",
      "name": "Rice",
      "opening": 20,
      "purchase": 10,
      "sale": 15,
      "pReturn": 0,
      "sReturn": 1,
      "proIn": 0,
      "proOut": 2,
      "stock": 14,
    },
  ];

  List<Map<String, dynamic>> get filteredItems {
    return items.where((e) {
      if (selectedCategory == "All") return true;
      return e["cat"] == selectedCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "ALL ITEM STOCK REPORT - ($selectedMonth)",
          style: TextStyle(fontSize: 15),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// 🔽 FILTER BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                /// Month
                Expanded(
                  child: _filterBox(
                    value: selectedMonth,
                    items: months,
                    onChanged: (v) => setState(() => selectedMonth = v),
                  ),
                ),

                const SizedBox(width: 6),

                /// Category
                Expanded(
                  child: _filterBox(
                    value: selectedCategory,
                    items: categories,
                    onChanged: (v) => setState(() => selectedCategory = v),
                  ),
                ),
              ],
            ),
          ),

          /// 🔽 LIST
          Expanded(
            child: ListView.builder(
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];

                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 3),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          /// NAME + CATEGORY
                          Expanded(
                            flex: 4,
                            child: Text(
                              "${index + 1}. ${item["name"]} (${item["cat"]})",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),

                          /// PURCHASE
                          _miniBox("Pur", item["purchase"]),

                          const SizedBox(width: 6),

                          /// SALE
                          _miniBox("Sale", item["sale"]),

                          const SizedBox(width: 6),

                          /// STOCK (highlight)
                          _miniBox(
                            "Stock",
                            item["stock"],
                            isHighlight: true,
                            isLow: item["stock"] <= 5,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                 
                      Divider(height: 1, color: Colors.grey.shade300),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _dataText("Opening", item["opening"]),
                          _dataText("Pur Ret", item["pReturn"]),
                          _dataText("Sale Ret", item["sReturn"]),
                          _dataText("Pro In", item["proIn"]),
                          _dataText("Pro Out", item["proOut"]),
                        ],
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

  Widget _miniBox(
    String label,
    dynamic value, {
    bool isHighlight = false,
    bool isLow = false,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 38), 
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), 
      decoration: BoxDecoration(
        color: isHighlight
            ? (isLow ? Colors.red.shade50 : Colors.green.shade50)
            : Colors.white,
        borderRadius: BorderRadius.circular(3), 
        border: Border.all(
          width: 0.8, 
          color: isHighlight
              ? (isLow ? Colors.red.shade200 : Colors.green.shade200)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8, 
              height: 1, 
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            "$value",
            style: TextStyle(
              fontSize: 11, 
              height: 1,
              fontWeight: FontWeight.w600,
              color: isHighlight
                  ? (isLow ? Colors.red : Colors.green)
                  : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔽 FILTER BOX
  Widget _filterBox({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: const TextStyle(fontSize: 12, color: Colors.black),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Widget _dataText(String label, dynamic value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          "$value",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
