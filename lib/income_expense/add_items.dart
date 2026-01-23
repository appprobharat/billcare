import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billcare/api/api_service.dart';
import 'package:http/http.dart' as http;

class AddItemBottomSheet extends StatefulWidget {
  const AddItemBottomSheet({super.key});

  @override
  State<AddItemBottomSheet> createState() => _AddItemBottomSheetState();
}

class _AddItemBottomSheetState extends State<AddItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  String selectedType = "Income";
  String? selectedCategoryId;
  String? selectedUnitId;
  final TextEditingController itemNameCtrl = TextEditingController();
  final TextEditingController priceCtrl = TextEditingController();
  bool isLoading = false;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> units = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("authToken") ?? "";
    final fetchedUnits = await ApiService.getUnit(token);

    setState(() {
      units = fetchedUnits;
      isLoading = false;
    });
  }

  Future<void> storeItem() async {
    print("Storing item with:");
    print("Type: $selectedType");
    print("ItemName: ${itemNameCtrl.text.trim()}");
    print("Price: ${priceCtrl.text.trim()}");
    print("Selected UnitId: $selectedUnitId");

    if (selectedUnitId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a Unit")));
      return;
    }

    // Safely find the selected unit
    final unitObj = units.firstWhere(
      (u) => u["id"].toString() == selectedUnitId,
      orElse: () => {},
    );

    if (unitObj.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Invalid Unit selected")));
      return;
    }

    final unitName = unitObj["Unit"];
    print("Resolved Unit Name: $unitName");

    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("authToken") ?? "";

    try {
      final url = Uri.parse("https://gst.billcare.in/api/inc_exp/item/store");
      final body = {
        "Type": selectedType,
        "ItemName": itemNameCtrl.text.trim(),
        "Price": priceCtrl.text.trim(),
        "Unit": unitName,
      };

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item Added Successfully")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 25,
      ),
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Add New Item",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text("Type:  ", style: TextStyle(fontSize: 16)),

                      // Income Radio
                      Row(
                        children: [
                          Radio<String>(
                            value: "Income",
                            groupValue: selectedType,
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                              });
                            },
                          ),
                          const Text("Income"),
                        ],
                      ),

                      const SizedBox(width: 20),

                      // Expense Radio
                      Row(
                        children: [
                          Radio<String>(
                            value: "Expenses",
                            groupValue: selectedType,
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                              });
                            },
                          ),
                          const Text("Expense"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: itemNameCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter item name" : null,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Item Name",
                      labelStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter price" : null,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: "Price",
                      labelStyle: const TextStyle(fontSize: 13),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: units.isEmpty
                            ? const CircularProgressIndicator()
                            : DropdownButton<String>(
                                isExpanded: true,
                                value: selectedUnitId,
                                hint: const Text("Select Unit"),
                                items: units.map((u) {
                                  final id = u["id"]
                                      .toString(); // <-- use 'id' from API
                                  print(
                                    "Dropdown item: id=$id, unit=${u["Unit"]}",
                                  );
                                  return DropdownMenuItem<String>(
                                    value: id,
                                    child: Text(u["Unit"]),
                                  );
                                }).toList(),

                                onChanged: (value) {
                                  setState(() {
                                    selectedUnitId = value;
                                  });
                                },
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: isLoading ? null : storeItem,
                      child: const Text(
                        "Create",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
