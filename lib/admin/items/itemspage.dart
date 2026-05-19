import 'package:billcare/api/api_service.dart'; // Assumed dependency
import 'package:billcare/admin/items/add.dart';
import 'package:billcare/admin/items/category.dart';
import 'package:flutter/material.dart';

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
  late TabController _tabController;

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
    try {
      final fetchedItems = await ApiService.fetchItemList();

      if (mounted) {
        setState(() {
          items = fetchedItems;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching items: $e");
    }
  }

  Future<void> loadCategories() async {
    try {
      final fetchedCategories = await ApiService.fetchCategoryList();

      if (mounted) {
        setState(() {
          categories = fetchedCategories;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching categories: $e");

      if (mounted) {
        setState(() {
          categories = [];
        });
      }
    }
  }

  Future<void> _addCategory(String name) async {
    setState(() {
      isCategoryProcessing = true;
    });

    try {
      await ApiService.storeCategory(name);
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

    try {
      await ApiService.updateCategory(
        categoryToUpdate['id'], // ✅ only id
        newName,
      );

      await loadCategories();

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("❌ Error updating category: $e");
    } finally {
      if (mounted) {
        setState(() {
          isCategoryProcessing = false;
        });
      }
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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
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

                    const SizedBox(height: 12),

                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: "Category Name",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    isCategoryProcessing
                        ? CircularProgressIndicator(color: primaryColor)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                final categoryName = controller.text.trim();

                                if (categoryName.isNotEmpty) {
                                  setModalState(() {
                                    setState(() {
                                      isCategoryProcessing = true;
                                    });
                                  });

                                  if (isEditing) {
                                    await _updateCategory(
                                      category,
                                      categoryName,
                                    );
                                  } else {
                                    await _addCategory(categoryName);
                                  }

                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                isEditing ? "Update" : "Create",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Main Build Method for ItemScreen ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          'Items',
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
            ),
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white24)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'ITEMS'),
                Tab(text: 'CATEGORIES'),
              ],
            ),
          ),
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
                      final cardColor = cardColors[index % cardColors.length];
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
                              builder: (_) =>
                                  AddItemPage(itemId: item["id"].toString()),
                            ),
                          );
                          if (result == true) {
                            await widget.onRefresh();
                          }
                        },
                        child: Card(
                          elevation: 2,
                          color: cardColor,

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

                                    _buildCompactInfo(
                                      title: 'Stock',
                                      value: '$stock',
                                      color:
                                          (double.tryParse(stock.toString()) ??
                                                  0) >
                                              0
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
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
