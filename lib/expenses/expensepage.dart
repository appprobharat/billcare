import 'package:billcare/expenses/add.dart';
import 'package:flutter/material.dart';

class ExpensePage extends StatelessWidget {
  const ExpensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expense'),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
             
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.red,
            indicatorColor: Colors.red,
            unselectedLabelColor: Colors.white,
            tabs: [
              Tab(text: 'Categories'),
              Tab(text: 'Items'),
            ],
          ),
        ),
        body: const TabBarView(children: [CategoryListView(), ItemListView()]),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.red,
          icon: const Icon(Icons.add),
          label: const Text("Add Expenses"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AddExpensePage()),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}

class CategoryListView extends StatelessWidget {
  const CategoryListView({super.key});

  @override
  Widget build(BuildContext context) {
    final categoryData = [
      {'name': 'foods items', 'amount': 200.0},
      {'name': 'Manufacturing Expense', 'amount': 0.0},
      {'name': 'Petrol', 'amount': 120.0},
      {'name': 'Rent', 'amount': 13500.0},
      {'name': 'Salary', 'amount': 0.0},
      {'name': 'Tea', 'amount': 0.0},
      {'name': 'Transport', 'amount': 0.0},
    ];

    final total = categoryData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as double),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "Total: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: categoryData.length,
            itemBuilder: (context, index) {
              final item = categoryData[index];
              return ListTile(
                title: Text(item['name'].toString()),
                trailing: Text(
                  '₹ ${(item['amount'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ItemListView extends StatelessWidget {
  const ItemListView({super.key});

  @override
  Widget build(BuildContext context) {
    final itemData = [
      {'name': 'chips', 'amount': 200.0},
      {'name': 'Petrol', 'amount': 120.0},
      {'name': 'Rent', 'amount': 13500.0},
    ];

    final total = itemData.fold<double>(
      0,
      (sum, item) => sum + (item['amount'] as double),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text(
                "Total: ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹ ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: itemData.length,
            itemBuilder: (context, index) {
              final item = itemData[index];
              return ListTile(
                title: Text(item['name'].toString()),
                trailing: Text(
                  '₹ ${(item['amount'] as double).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
              );
            },
          ),
        ),
        // const Divider(height: 1),
      ],
    );
  }
}
