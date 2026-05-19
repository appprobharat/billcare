import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/admin/income_expense/edit_category.dart';
import 'package:billcare/admin/income_expense/add_category.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final TextEditingController fromDateController = TextEditingController();
  final TextEditingController toDateController = TextEditingController();
  final TextEditingController searchCtrl = TextEditingController();
  List<Map<String, String>> categoryList = [];
  List<Map<String, String>> filteredList = [];
  bool isLoading = true;
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
    fetchCategories();
  }

  Future<void> fetchCategories() async {
    setState(() {
      isLoading = true; // ⭐ Show Loader
    });

    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again.")),
      );
      Navigator.pop(context);
      return;
    }

    if (token.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse("${ApiService.baseUrl}/inc_exp/category/list");

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      print("🔵 Fetch Status: ${response.statusCode}");
      print("🔵 Fetch Body: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> list = json.decode(response.body);

        categoryList.clear();
        for (var item in list) {
          categoryList.add({
            "type": item["Type"] ?? "",
            "categoryName": item["Category"] ?? "",
            "id": item["id"]?.toString() ?? "",
          });
        }

        setState(() {
          filteredList = List.from(categoryList);
          isLoading = false; // ⭐ Hide Loader
        });
      }
    } catch (e) {
      print("❌ Fetch Error: $e");
      setState(() => isLoading = false);
    }
  }

  void _applyFilter() {
    String query = searchCtrl.text.toLowerCase();

    setState(() {
      filteredList = categoryList.where((item) {
        return item["categoryName"]!.toLowerCase().contains(query) ||
            item["type"]!.toLowerCase().contains(query);
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
          "Inc/Exp Categories",
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
                  builder: (context) => const AddCategoryBottomSheet(),
                );

                if (result != null) {
                  fetchCategories();
                }
              },
            ),
          ),
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
                strokeWidth: 3,
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    // 🔍 Search Box
                    TextField(
                      controller: searchCtrl,
                      onChanged: (query) => _applyFilter(),
                      decoration: InputDecoration(
                        labelText: "Search by Name",
                        labelStyle: const TextStyle(fontSize: 14),
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E3A8A),
                            width: 1.0,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12.0,
                          horizontal: 20.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // LIST VIEW
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final cardColor = cardColors[index % cardColors.length];
                        final item = filteredList[index];

                        return Card(
                          elevation: 4,
                          color: cardColor,
                          margin: const EdgeInsets.only(bottom: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item["categoryName"]!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                // TYPE BADGE
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: item["type"] == "Income"
                                        ? Colors.green.shade100
                                        : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    item["type"]!,
                                    style: TextStyle(
                                      color: item["type"] == "Income"
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Edit Button
                                GestureDetector(
                                  onTap: () async {
                                    final result = await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(25),
                                        ),
                                      ),
                                      builder: (context) =>
                                          EditCategoryBottomSheet(
                                            initialName: item["categoryName"]!,
                                            initialType: item["type"]!,
                                            categoryId:
                                                int.tryParse(
                                                  item["id"] ?? "0",
                                                ) ??
                                                0,
                                          ),
                                    );
                                    print("🟩 Category Item: $item");

                                    if (result != null) {
                                      fetchCategories(); // Refresh list after update
                                    }
                                  },
                                  child: const Icon(
                                    Icons.edit,
                                    size: 22,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
