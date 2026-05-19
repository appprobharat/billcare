import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditCategoryBottomSheet extends StatefulWidget {
  final String initialName;
  final String initialType;
  final int categoryId;

  const EditCategoryBottomSheet({
    super.key,
    required this.initialName,
    required this.initialType,
    required this.categoryId,
  });

  @override
  State<EditCategoryBottomSheet> createState() =>
      _EditCategoryBottomSheetState();
}

class _EditCategoryBottomSheetState extends State<EditCategoryBottomSheet> {
  late TextEditingController nameCtrl;
  String? selectedType;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.initialName);
    selectedType = widget.initialType;
  }

  Future<void> updateCategory() async {
    if (nameCtrl.text.trim().isEmpty || selectedType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter all fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final token = await AuthStorage.getToken();

      if (token == null || token.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please login again.")),
        );
        Navigator.pop(context);
        return;
      }

      if (token.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse(
        "${ApiService.baseUrl}/inc_exp/category/update",
      );
      print("📤 Sending to backend:");
      print({
        "CategoryId": widget.categoryId.toString(),
        "Type": selectedType!,
        "Category": nameCtrl.text.trim(),
      });
      print(
        "📤 Headers: {Authorization: Bearer $token, Accept: application/json}",
      );

      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {
          "CategoryId": widget.categoryId.toString(),
          "Type": selectedType!,
          "Category": nameCtrl.text.trim(),
        },
      );

      print("🔵 Update Status: ${response.statusCode}");
      print("🔵 Update Body: ${response.body}");

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category updated successfully")),
        );
        Navigator.pop(context, {
          "categoryName": nameCtrl.text.trim(),
          "type": selectedType,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: ${response.body}")),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Update Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
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
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Edit Category",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Category Name",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField(
                    value: selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Type",
                    ),
                    items: ["Income", "Expenses"]
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => selectedType = value),
                  ),

                  const SizedBox(height: 20),

                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: updateCategory,
                            child: const Text("Save Changes"),
                          ),
                        ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
