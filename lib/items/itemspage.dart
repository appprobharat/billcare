import 'package:billcare/api/api_service.dart'; // Assumed dependency
import 'package:billcare/items/add.dart';
import 'package:billcare/items/category.dart';
import 'package:billcare/items/edit.dart'; // Assumed dependency
import 'package:billcare/screens/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Assumed dependency

class ItemScreen extends StatefulWidget {
  const ItemScreen({super.key});

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> items = [];

  List<dynamic> categories = [];
  bool isLoading = true;
  bool isCategoryProcessing = false;
  late TabController _tabController; // TabController state added

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([loadItems(), loadCategories()]);
    setState(() {
      isLoading = false;
    });
  }

  Future<void> loadItems() async {
   final token = await AuthStorage.getToken() ?? "";


    try {
      final fetchedItems = await ApiService.fetchItemList(token);
      if (mounted) {
        setState(() {
          items = fetchedItems;
        });
      }
    } catch (e) {
      print("❌ Error fetching items: $e");
    }
  }

  Future<void> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("authToken") ?? "";

    try {
      final fetchedCategories = await ApiService.fetchCategoryList(token);
      if (mounted) {
        setState(() {
          categories = fetchedCategories;
        });
      }
    } catch (e) {
      print("❌ Error fetching categories: $e");
      // Fallback
      if (mounted) {
        setState(() {
          categories = [
            {'Name': 'Electronics', 'id': 'temp1'},
            {'Name': 'Groceries', 'id': 'temp2'},
          ];
        });
      }
    }
  }

  Future<void> _addCategory(String name) async {
    setState(() {
      isCategoryProcessing = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("authToken") ?? "";

    try {
      await ApiService.storeCategory(token, name);
      await loadCategories();
      // Close the dialog/bottom sheet after success
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("❌ Error adding category: $e");

      // Handle error message display if needed
    } finally {
      if (mounted) {
        setState(() {
          isCategoryProcessing = false;
        });
      }
    }
  }

  Future<void> _updateCategory(dynamic categoryToUpdate, String newName) async {
    setState(() {
      isCategoryProcessing = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("authToken") ?? "";

    try {
      await ApiService.updateCategory(token, categoryToUpdate['id'], newName);
      await loadCategories();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("❌ Error updating category: $e");
    } finally {
      setState(() {
        isCategoryProcessing = false;
      });
    }
  }

  void _showCategoryBottomSheet({dynamic category}) {
   
    if (isCategoryProcessing) {
      setState(() {
        isCategoryProcessing = false;
      });
    }
    final TextEditingController controller = TextEditingController(
      text: category?['Name'] ?? '',
    );
    final bool isEditing = category != null;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 15,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEditing ? "Edit Category" : "Add New Category",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: "Category Name",
                      labelStyle: TextStyle(fontSize: 14),
                      border: OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 15),
                  // 🚀 FIX: isCategoryProcessing का उपयोग करके लोडर या बटन दिखाएँ
                  isCategoryProcessing
                      ? Center(
                          child: CircularProgressIndicator(
                            color: isEditing ? primaryColor : primaryColor,
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () async {
                            final categoryName = controller.text.trim();
                            if (categoryName.isNotEmpty) {
                              setModalState(() {
                                setState(() {
                                  isCategoryProcessing = true;
                                });
                              });

                              // 2. API कॉल करें
                              if (isEditing) {
                                await _updateCategory(category, categoryName);
                              } else {
                                await _addCategory(categoryName);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEditing
                                ? primaryColor
                                : primaryColor,
                            minimumSize: const Size(double.infinity, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text(
                            isEditing ? "Update" : "Create",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- Main Build Method for ItemScreen ---
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    String buttonText;
    if (_tabController.index == 0) {
      buttonText = 'Add Item';
    } else {
      buttonText = 'Add Category';
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 1,
        backgroundColor: primaryColor,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'Items',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
          ), // Slightly reduced title font size
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ), // Reduced tab font size
          indicatorColor: Colors.white,
          indicatorWeight: 3, // Reduced indicator weight
          tabs: const [
            Tab(text: 'ITEMS'),
            Tab(text: 'CATEGORIES'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                ProductTab(items: items, onRefresh: loadItems),
                CategoriesTab(
                  categories: categories,
                  onEdit: _showCategoryBottomSheet,
                  onRefresh: loadCategories,
                ),
              ],
            ),

      // build method के अंदर
      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),

            child: GestureDetector(
              onTap: () async {
                if (_tabController.index == 0) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddItemPage(),
                    ),
                  );
                  if (result == true) {
                    await loadItems();
                  }
                } else {
                  _showCategoryBottomSheet();
                }
              },

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      buttonText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ProductTab (Compact Design) ---

class ProductTab extends StatefulWidget {
  final List<dynamic> items;
  final Future<void> Function() onRefresh;
  const ProductTab({super.key, required this.items, required this.onRefresh});

  @override
  State<ProductTab> createState() => _ProductTabState();
}

class _ProductTabState extends State<ProductTab> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredItems = [];

  @override
  void initState() {
    super.initState();
    filteredItems = widget.items;
    searchController.addListener(_filterItems);
  }

  @override
  void didUpdateWidget(covariant ProductTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      filteredItems = widget.items;
      _filterItems(); // Re-filter when items are updated
    }
  }

  void _filterItems() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredItems = widget.items.where((item) {
        final name = (item['Name'] ?? '').toString().toLowerCase();
        final category = (item['Category'] ?? '').toString().toLowerCase();
        return name.contains(query) || category.contains(query);
      }).toList();
    });
  }

  // Helper function to convert string to Title Case
  String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1).toLowerCase()
              : '',
        )
        .join(' ');
  }

  // New helper widget to build the compact horizontal info line
  Widget _buildCompactInfo({
    required String title,
    required String value,
    required Color color,
  }) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$title: ',
            style: const TextStyle(
              fontSize: 11, // Further reduced
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          TextSpan(
            text: value,
            style: TextStyle(
              fontSize: 12, // Further reduced
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 5,
              ),
              prefixIcon: const Icon(Icons.search, size: 18),
              hintText: 'Search Items by Name or Category',
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      "No items found",
                      style: TextStyle(fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      final itemName = item['Name'] ?? 'N/A';
                      final category = item['Category'] ?? 'N/A';
                      final stock = item['Stock'] ?? '0';

                      final salesPrice =
                          (double.tryParse(
                                    item['Price']?.toString() ?? '0.0',
                                  ) ??
                                  0.0)
                              .toStringAsFixed(2);
                      final purchasePrice =
                          (double.tryParse(
                                    item['PurchasePrice']?.toString() ?? '0.0',
                                  ) ??
                                  0.0)
                              .toStringAsFixed(2);

                      final gst = item['GST']?.toString() ?? '0';

                      return InkWell(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditItemPage(itemId: item['id']),
                            ),
                          );
                          if (result == true) {
                            await widget.onRefresh();
                          }
                        },
                        child: Card(
                          elevation: 1,

                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),

                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Name and Category on the first line
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${_toTitleCase(itemName)} ($category)',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.bottomRight,
                                        child: _buildCompactInfo(
                                          title: 'Stock',
                                          value: '$stock',
                                          color:
                                              (double.tryParse(
                                                        stock.toString(),
                                                      ) ??
                                                      0) >
                                                  0
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: _buildCompactInfo(
                                          title: 'Sale',
                                          value: '₹$salesPrice',
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: _buildCompactInfo(
                                          title: 'Purchase',
                                          value: '₹$purchasePrice',
                                          color: Colors.deepOrange.shade700,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: _buildCompactInfo(
                                          title: 'GST',
                                          value: gst,
                                          color: Colors.blueGrey.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
