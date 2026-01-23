import 'package:flutter/material.dart';


class CategoriesTab extends StatefulWidget {
  final List<dynamic> categories;
  final Future<void> Function() onRefresh;
  final void Function({dynamic category})
  onEdit;

  const CategoriesTab({
    super.key,
    required this.categories,
    required this.onRefresh,
    required this.onEdit,
  });

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    final filteredCategories = widget.categories
        .where(
          (cat) => cat['Name'].toString().toLowerCase().contains(
            searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Column(
      children: [
        Padding(
          // Reduced outer padding from 8.0 to 6.0
          padding: const EdgeInsets.all(6.0),
          child: TextField(
            decoration: InputDecoration(
              isDense: true, // Make the text field more compact
              contentPadding: const EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 8,
              ),
              hintText: 'Search Category',
              hintStyle: const TextStyle(
                fontSize: 13,
              ), // Reduced hint text size from 14
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.grey,
                size: 18, // Reduced icon size from 20
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  10,
                ), // Reduced border radius
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: const TextStyle(
              fontSize: 13,
            ), // Reduced input text size from 14
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        ),
        Container(
          color: Colors.grey.shade100,
          // Reduced vertical padding
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 6, // Reduced from 8
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Category Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ), // Reduced font size
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: filteredCategories.isEmpty
                ? const Center(
                    child: Text(
                      "No categories found",
                      style: TextStyle(fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    // Added padding at the bottom so FAB doesn't hide content
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      return Card(
                        elevation: 1, // Reduced elevation
                        // Reduced vertical margin
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8, // Reduced from 12
                          vertical: 4, // Reduced from 6
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            8,
                          ), // Reduced border radius
                        ),
                        child: ListTile(
                          // Reduced vertical padding for height reduction
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 2, // Reduced from 4
                          ),
                          leading: Icon(
                            Icons.folder,
                            color: primaryColor,
                            size: 20,
                          ), // Reduced icon size
                          title: Text(
                            category['Name'] ?? 'N/A',
                            style: const TextStyle(
                              fontSize: 14, // Reduced from 16
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: Colors.grey,
                              size: 18,
                            ), // Reduced icon size
                            onPressed: () {
                              // Call the callback function from ItemScreen for editing
                              widget.onEdit(category: category);
                            },
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
