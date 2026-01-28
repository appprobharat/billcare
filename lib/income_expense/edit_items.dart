import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';


class EditItemBottomSheet extends StatefulWidget {
  final String itemId;
  final String initialType;
  final String initialName;
  final String initialPrice;
  final String initialUnit;

  const EditItemBottomSheet({
    super.key,
    required this.itemId,
    required this.initialType,
    required this.initialName,
    required this.initialPrice,
    required this.initialUnit,
  });

  @override
  State<EditItemBottomSheet> createState() => _EditItemBottomSheetState();
}

class _EditItemBottomSheetState extends State<EditItemBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late String selectedType;
  late TextEditingController itemNameCtrl;
  late TextEditingController priceCtrl;
  String? selectedUnitId;

  bool isLoading = false;

  List<Map<String, dynamic>> units = [];

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType;
    itemNameCtrl = TextEditingController(text: widget.initialName);
    priceCtrl = TextEditingController(text: widget.initialPrice);
    _loadUnits();
  }

 Future<void> _loadUnits() async {
  setState(() => isLoading = true);

  try {
    final fetchedUnits = await ApiService.getUnit();
    if (!mounted) return;

    final match = fetchedUnits.firstWhere(
      (u) => u["Unit"] == widget.initialUnit,
      orElse: () => {},
    );

    setState(() {
      units = fetchedUnits.cast<Map<String, dynamic>>();
      selectedUnitId = match.isNotEmpty ? match["id"].toString() : null;
    });
  } catch (e) {
    debugPrint("❌ load units error: $e");
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}


 Future<void> updateItem() async {
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
    "ItemId": widget.itemId,
    "Type": selectedType,
    "ItemName": itemNameCtrl.text.trim(),
    "Price": priceCtrl.text.trim(),
    "Unit": unitObj["Unit"].toString(),
  };

  debugPrint("🚀 Edit BottomSheet Payload: $body");

  setState(() => isLoading = true);

  try {
    final success = await ApiService.updateIncomeExpenseItem(body);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Item Updated Successfully")),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to update item")),
      );
    }
  } catch (e) {
    debugPrint("❌ updateItem error: $e");
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("❌ Error while updating item")),
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
                children: [
                  const Text(
                    "Edit Item",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Type Radio Buttons
                  Row(
                    children: [
                      const Text("Type:  ", style: TextStyle(fontSize: 16)),

                      Row(
                        children: [
                          Radio<String>(
                            value: "Income",
                            groupValue: selectedType,
                            onChanged: (v) => setState(() => selectedType = v!),
                          ),
                          const Text("Income"),
                        ],
                      ),

                      const SizedBox(width: 20),

                      Row(
                        children: [
                          Radio<String>(
                            value: "Expenses",
                            groupValue: selectedType,
                            onChanged: (v) => setState(() => selectedType = v!),
                          ),
                          const Text("Expense"),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  // Item Name
                  TextFormField(
                    controller: itemNameCtrl,
                    style: const TextStyle(fontSize: 14),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter item name" : null,
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

                  // Price
                  TextFormField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 14),
                    validator: (v) =>
                        v == null || v.isEmpty ? "Enter price" : null,
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

                  // Unit Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedUnitId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: "Unit",
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
                    items: units.map((u) {
                      return DropdownMenuItem(
                        value: u["id"].toString(),
                        child: Text(u["Unit"]),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => selectedUnitId = val),
                  ),

                  const SizedBox(height: 20),

                  // Update Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : updateItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        "Update Item",
                        style: TextStyle(color: Colors.white),
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
