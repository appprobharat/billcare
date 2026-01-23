import 'package:flutter/material.dart';

class Item {
  final String name;
  final String? category;
  final String? salesPrice;
  final String? tax;

  Item({required this.name, this.category, this.salesPrice, this.tax});
}

class ItemListPage extends StatelessWidget {
  final List<Item> items;

  const ItemListPage({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Items List')),
      body: ListView.builder(
        itemCount: items.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📦 Name: ${item.name}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "📂 Category: ${item.category ?? 'N/A'}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        "💰 Sales Price: ₹${item.salesPrice ?? '0'}",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        "💳 Tax: ${item.tax ?? '0'}%",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
