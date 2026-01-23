import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddCategoryBottomSheet extends StatefulWidget {
  const AddCategoryBottomSheet({super.key});

  @override
  State<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  final TextEditingController categoryCtrl = TextEditingController();
  String selectedType = "Income";
  bool isLoading = false;

  Future<void> storeCategory() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("authToken") ?? "";

      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Token not found. Please login again.")),
        );
        setState(() => isLoading = false);
        return;
      }

      final url = Uri.parse(
        "https://gst.billcare.in/api/inc_exp/category/store",
      );

      final String apiType = selectedType == "Income" ? "Income" : "Expenses";

      /// ⭐ FORM-DATA POST with token
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
        body: {"Type": apiType, "Category": categoryCtrl.text.trim()},
      );

      print("🔵 Status: ${response.statusCode}");
      print("🔵 Body: ${response.body}");

      setState(() => isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Category Added Successfully")),
        );

        Navigator.pop(context, {
          "type": apiType,
          "categoryName": categoryCtrl.text.trim(),
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed: ${response.body}")));
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("❌ Error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              "Add New Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

          TextField(
            controller: categoryCtrl,
            decoration: InputDecoration(
              labelText: "Category Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
              onPressed: isLoading
                  ? null
                  : () {
                      if (categoryCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enter category name")),
                        );
                        return;
                      }
                      storeCategory();
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Create",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
