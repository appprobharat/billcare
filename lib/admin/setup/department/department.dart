import 'package:billcare/api/api_service.dart';

import 'package:flutter/material.dart';

class DepartmentPage extends StatefulWidget {
  const DepartmentPage({super.key});

  @override
  State<DepartmentPage> createState() => _DepartmentPageState();
}

class _DepartmentPageState extends State<DepartmentPage> {
  List<Map<String, dynamic>> _departments = [];

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> saveDepartment({int? id}) async {
    setState(() => isLoading = true);

    final endpoint = id == null ? "/department/store" : "/department/update";

    final body = {
      if (id != null) "DepartmentId": id.toString(),
      "Name": _nameCtrl.text.trim(),
      "Description": _descCtrl.text.trim(),
    };

    print("📤 SAVE BODY => $body");

    final res = await ApiService.postRequest(endpoint: endpoint, body: body);

    print("📥 SAVE RESPONSE => $res");

    if (res != null) {
      await fetchDepartments();
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchDepartments() async {
    setState(() => isLoading = true);

    final data = await ApiService.postRequest(endpoint: "/department/list");

    print("📦 LIST RESPONSE => $data");

    if (data != null && data is List) {
      setState(() {
        _departments = List<Map<String, dynamic>>.from(data);
      });
    }

    setState(() => isLoading = false);
  }

  Future<void> toggleStatus(int id, int currentStatus) async {
    setState(() => isLoading = true);

    final newStatus = currentStatus == 1 ? 0 : 1;

    final body = {
      "DepartmentId": id.toString(),
      "Status": newStatus.toString(),
    };

    print("📤 STATUS BODY => $body");

    final res = await ApiService.postRequest(
      endpoint: "/department/status",
      body: body,
    );

    print("📥 STATUS RESPONSE => $res");

    if (res != null) {
      await fetchDepartments();
    }

    setState(() => isLoading = false);
  }

  /// 🔹 Add / Edit Bottom Sheet
  void _openDepartmentSheet({int? index}) {
    /// ✅ ADD CASE → fields clear
    if (index == null) {
      _nameCtrl.clear();
      _descCtrl.clear();
    } else {
      /// ✅ EDIT CASE → fill data
      _nameCtrl.text = _departments[index]['Name'] ?? '';
      _descCtrl.text = _departments[index]['Description'] ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),

            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),

              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        index == null ? "Add Department" : "Edit Department",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// 🔹 Name
                      TextField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: "Department Name",
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// 🔹 Description
                      TextField(
                        controller: _descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: "Description",
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_nameCtrl.text.trim().isEmpty) return;

                            await saveDepartment(
                              id: index != null
                                  ? _departments[index]['id']
                                  : null,
                            );

                            _nameCtrl.clear();
                            _descCtrl.clear();
                            Navigator.pop(context);
                          },
                          child: Text(index == null ? "Add" : "Update"),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Departments"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openDepartmentSheet(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _departments.isEmpty
          ? const Center(child: Text("No Departments Found"))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _departments.length,
              itemBuilder: (context, index) {
                final desig = _departments[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.apartment, color: Colors.blue),
                      ),

                      const SizedBox(width: 10),

                      /// Text
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (desig['Name'] ?? "No Name"),

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              (desig['Description'] ?? "No Description"),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              (desig['Status'] ?? 0) == 1
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: desig['Status'] == 1
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onPressed: () {
                              toggleStatus(desig['id'], desig['Status']);
                            },
                          ),

                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _openDepartmentSheet(index: index),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
