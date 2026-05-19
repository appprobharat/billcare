import 'package:flutter/material.dart';

class LowStockPage extends StatefulWidget {
  const LowStockPage({super.key});

  @override
  State<LowStockPage> createState() => _LowStockPageState();
}

class _LowStockPageState extends State<LowStockPage> {
  String selectedCategory = "All";

  List<String> categories = ["All", "Electronics", "Grocery", "Clothing"];

  List<Map<String, dynamic>> items = [
    {"cat": "Electronics", "name": "Mouse", "qty": 2},
    {"cat": "Electronics", "name": "Keyboard", "qty": 5},
    {"cat": "Grocery", "name": "Rice", "qty": 1},
    {"cat": "Clothing", "name": "T-Shirt", "qty": 3},
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
      appBar: AppBar(title: const Text("Low Stock Summary"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Container(
              height: 36, // 👈 fixed small height
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 16, color: Colors.grey),

                  const SizedBox(width: 6),

                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                        style: const TextStyle(
                          fontSize: 12, // 👈 chhota text
                          color: Colors.black,
                        ),
                        items: categories.map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text(
                              e,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => selectedCategory = val!);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// 🔽 TABLE HEADER
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey.shade200,
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Align(alignment: Alignment.center, child: Text("Sr")),
                ),
                Expanded(flex: 3, child: Text("Category")),
                Expanded(flex: 3, child: Text("Item")),
                Expanded(flex: 2, child: Text("Qty")),
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
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.black12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.center,
                          child: Text("${index + 1}"),
                        ),
                      ),
                      Expanded(flex: 3, child: Text(item["cat"])),
                      Expanded(flex: 3, child: Text(item["name"])),

                      /// 🔴 LOW STOCK HIGHLIGHT
                      Expanded(
                        flex: 2,
                        child: Text(
                          "${item["qty"]}",
                          style: TextStyle(
                            color: item["qty"] <= 3 ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
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
}
