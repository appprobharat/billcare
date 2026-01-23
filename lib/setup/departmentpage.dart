import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DepartmentPage extends StatefulWidget {
  const DepartmentPage({super.key});

  @override
  State<DepartmentPage> createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, String>> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  Future<void> _loadDepartments() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList('departments') ?? [];
    setState(() {
      _departments = storedList
          .map((item) => Map<String, String>.from(json.decode(item)))
          .toList();
    });
  }

  Future<void> _saveDepartments() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedList = _departments.map((item) => json.encode(item)).toList();
    await prefs.setStringList('departments', encodedList);
  }

  void _addDepartment() {
    final name = _departmentController.text.trim();
    final desc = _descriptionController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _departments.add({'name': name, 'description': desc});
      _departmentController.clear();
      _descriptionController.clear();
    });
    _saveDepartments();
  }

  void _deleteDepartment(int index) {
    setState(() {
      _departments.removeAt(index);
    });
    _saveDepartments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Department")),
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
                      "Enter Department",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        hintText: "Department name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: "Enter Description",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            _departmentController.clear();
                            _descriptionController.clear();
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addDepartment,
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
                child: _departments.isEmpty
                    ? const Center(child: Text("No departments added."))
                    : ListView.builder(
                        itemCount: _departments.length,
                        itemBuilder: (context, index) {
                          final dept = _departments[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                              ),

                              title: Text(
                                dept['name'] ?? "",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),

                              subtitle: Text(
                                dept['description'] ?? '',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 15,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () => _deleteDepartment(index),
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
