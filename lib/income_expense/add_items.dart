import 'package:flutter/material.dart';
import 'package:billcare/api/api_service.dart';


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

  try {
    final fetchedUnits = await ApiService.getUnit();
    if (!mounted) return;

    setState(() {
      units = fetchedUnits.cast<Map<String, dynamic>>();
    });
  } catch (e) {
    debugPrint("❌ load units error: $e");
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}

Future<void> storeItem() async {
  if (!_formKey.currentState!.validate()) return;

  if (selectedUnitId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please select a Unit")),
    );
    return;
  }

  final unitObj = units.firstWhere(
    (u) => u["id"].toString() == selectedUnitId,
    orElse: () => {},
  );

  if (unitObj.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Invalid Unit selected")),
    );
    return;
  }

  final body = {
    "Type": selectedType,
    "ItemName": itemNameCtrl.text.trim(),
    "Price": priceCtrl.text.trim(),
    "Unit": unitObj["Unit"].toString(),
  };

  debugPrint("🚀 BottomSheet Item Payload: $body");

  setState(() => isLoading = true);

  try {
    final success = await ApiService.storeIncomeExpenseItem(body);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Item Added Successfully")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to add item")),
      );
    }
  } catch (e) {
    debugPrint("❌ storeItem error: $e");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Error while saving item")),
    );
  } finally {
    if (mounted) setState(() => isLoading = false);
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
