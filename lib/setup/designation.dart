import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class Designation extends StatefulWidget {
  const Designation({super.key});

  @override
  State<Designation> createState() => _DesignationState();
}

class _DesignationState extends State<Designation> {
 final TextEditingController _designationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Map<String, String>> _designation = [];

  @override
  void initState() {
    super.initState();
    _loadDesignations();
  }

  Future<void> _loadDesignations() async {
    final prefs = await SharedPreferences.getInstance();
    final storedList = prefs.getStringList('designation') ?? [];
    setState(() {
      _designation = storedList
          .map((item) => Map<String, String>.from(json.decode(item)))
          .toList();
    });
  }

  Future<void> _saveDesignations() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedList = _designation.map((item) => json.encode(item)).toList();
    await prefs.setStringList('designation', encodedList);
  }

  void _addDesignation() {
    final name = _designationController.text.trim();
    final desc = _descriptionController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _designation.add({'name': name, 'description': desc});
      _designationController.clear();
      _descriptionController.clear();
    });
    _saveDesignations();
  }

  void _deleteDesignations(int index) {
    setState(() {
      _designation.removeAt(index);
    });
    _saveDesignations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Designation")),
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
                      "Enter Designation",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _designationController,
                      decoration: const InputDecoration(
                        hintText: "Designation name",
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
                            _designationController.clear();
                            _descriptionController.clear();
                          },
                          child: const Text("Cancel"),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _addDesignation,
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
                child: _designation.isEmpty
                    ? const Center(child: Text("No Designations added."))
                    : ListView.builder(
                        itemCount: _designation.length,
                        itemBuilder: (context, index) {
                          final dept = _designation[index];
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
                                onPressed: () => _deleteDesignations(index),
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

