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
            // Search Box
            TextField(
              controller: searchCtrl,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                labelText: "Search by Name/Unit",
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
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
                        final cardColor = cardColors[index % cardColors.length];
                        final item = filteredItems[index];
                        return Card(
                          elevation: 4,
                          color: cardColor,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item["name"],
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item["type"] == "Income"
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item["type"],
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: item["type"] == "Income"
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Unit: ${item["unit"]}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "₹ ${item["price"]}",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                          top: Radius.circular(
                                                            25,
                                                          ),
                                                        ),
                                                  ),
                                              builder: (_) =>
                                                  EditItemBottomSheet(
                                                    itemId: item["id"]
                                                        .toString(),
                                                    initialType:
                                                        (item["type"] ?? "")
                                                            .toString(),
                                                    initialName:
                                                        (item["name"] ?? "")
                                                            .toString(),
                                                    initialPrice:
                                                        (item["price"] ?? "")
                                                            .toString(),
                                                    initialUnit:
                                                        (item["unit"] ?? "")
                                                            .toString(),
                                                  ),
                                            ).then((updated) {
                                              if (updated == true) {
                                                fetchItems(); // <-- Your reload function
                                              }
                                            });
                                          },

                                          child: const Icon(
                                            Icons.edit,
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
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
      ),
    );
  }
}
