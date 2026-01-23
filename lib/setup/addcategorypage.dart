import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddCategoryPage extends StatefulWidget {
  const AddCategoryPage({super.key});

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController _categoryController = TextEditingController();
  final List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList('categories') ?? [];
    setState(() {
      _categories.clear();
      _categories.addAll(storedList);
    });
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('categories', _categories);
  }

  void _addCategory(String newCategory) {
    if (newCategory.trim().isEmpty) return;
    setState(() {
      _categories.add(newCategory.trim());
    });
    _saveCategories();
    _categoryController.clear();
  }

  void _deleteCategory(int index) {
    setState(() {
      _categories.removeAt(index);
    });
    _saveCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Category")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Enter Category",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        hintText: "Category name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _categoryController.clear();
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _addCategory(_categoryController.text);
                          },
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _categories.isEmpty
                    ? const Center(child: Text("No categories added."))
                    : ListView.builder(
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: const Icon(
                                Icons.category,
                                color: Colors.blue,
                              ),
                              title: Text(
                                _categories[index],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteCategory(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
