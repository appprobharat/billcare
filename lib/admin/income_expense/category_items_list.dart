import 'dart:convert';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/admin/income_expense/add_items.dart';
import 'package:billcare/admin/income_expense/edit_items.dart';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class CategoryItemsListPage extends StatefulWidget {
  const CategoryItemsListPage({super.key});

  @override
  State<CategoryItemsListPage> createState() => _CategoryItemsListPageState();
}

class _CategoryItemsListPageState extends State<CategoryItemsListPage> {
  final TextEditingController searchCtrl = TextEditingController();

  List<Map<String, dynamic>> itemList = [];
  List<Map<String, dynamic>> filteredItems = [];
  bool _isLoading = true;
  final List<Color> cardColors = [
    Colors.blue.shade50,
    Colors.green.shade50,
    Colors.orange.shade50,
    Colors.purple.shade50,
    Colors.teal.shade50,
    Colors.red.shade50,
    Colors.indigo.shade50,
  ];
  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please login again.")),
        );
        Navigator.pop(context);
        return;
      }

      final url = Uri.parse("${ApiService.baseUrl}/inc_exp/item/list");

      // POST request with empty body
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
        body: jsonEncode({}), // API expects POST with empty body
      );

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        itemList = data.map<Map<String, dynamic>>((e) {
          return {
            "id": e["id"],
            "name": e["ItemName"],
            "unit": e["Unit"],
            "price": e["Price"],
            "type": e["Type"],
          };
        }).toList();

        setState(() {
          filteredItems = List.from(itemList);
        });
      } else {
        print("Failed to fetch items. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data → $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    String q = searchCtrl.text.toLowerCase();
    setState(() {
      filteredItems = itemList.where((item) {
        return item["name"].toLowerCase().contains(q) ||
            item["unit"].toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,

        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Inc/Exp Items",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  builder: (context) => const AddItemBottomSheet(),
                );

                if (result != null && result == true) {
                  fetchItems();
                }
              },
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xffFF6A00), Color(0xffEE0979)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepOrange.withOpacity(.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Total Items",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${filteredItems.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          "Items",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            // Search Box
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: searchCtrl,
                onChanged: (_) => _applyFilter(),
                decoration: InputDecoration(
                  hintText: "Search Items...",
                  prefixIcon: Icon(Icons.search, color: Colors.orange),
                  suffixIcon: Icon(Icons.tune, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredItems.isEmpty
                  ? const Center(child: Text("No Items Found"))
                  : ListView.builder(
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 15,
                                offset: Offset(0, 8),
                              ),
                            ],
                            border: Border.all(color: Colors.grey.shade200),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: Colors.orange.shade50,
                                      child: const Icon(
                                        Icons.inventory_2_rounded,
                                        color: Colors.deepOrange,
                                        size: 18,
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Text(
                                        item["name"],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 6),

                                    _buildChip(
                                      item["unit"],
                                      Colors.grey.shade100,
                                      Colors.grey.shade700,
                                    ),

                                    const SizedBox(width: 6),

                                    _buildChip(
                                      item["type"],
                                      item["type"] == "Income"
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      item["type"] == "Income"
                                          ? Colors.green
                                          : Colors.red,
                                    ),

                                    const SizedBox(width: 8),

                                    Text(
                                      "₹${item["price"]}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.deepOrange,
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    InkWell(
                                      onTap: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(25),
                                            ),
                                          ),
                                          builder: (_) => EditItemBottomSheet(
                                            itemId: item["id"].toString(),
                                            initialType: (item["type"] ?? "")
                                                .toString(),
                                            initialName: (item["name"] ?? "")
                                                .toString(),
                                            initialPrice: (item["price"] ?? "")
                                                .toString(),
                                            initialUnit: (item["unit"] ?? "")
                                                .toString(),
                                          ),
                                        ).then((updated) {
                                          if (updated == true) {
                                            fetchItems(); // <-- Your reload function
                                          }
                                        });
                                      },

                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit_rounded,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text, Color bg, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
