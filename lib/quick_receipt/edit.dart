import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class EditQuickReceiptPage extends StatefulWidget {
  final Map<String, dynamic> receipt;

  const EditQuickReceiptPage({super.key, required this.receipt});

  @override
  State<EditQuickReceiptPage> createState() => _EditQuickReceiptPageState();
}

class _EditQuickReceiptPageState extends State<EditQuickReceiptPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late TextEditingController _chequeController;
  late TextEditingController _remarkController;

  // State to manage the loading status
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.receipt["Name"]?.toString() ?? "",
    );
    _amountController = TextEditingController(
      text: widget.receipt["Amount"]?.toString() ?? "",
    );
    _chequeController = TextEditingController(
      text: widget.receipt["ChequeNo"]?.toString() ?? "",
    );
    _remarkController = TextEditingController(
      text: widget.receipt["Remark"]?.toString() ?? "",
    );
  }

  Future<void> _updateReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    // Start loading and rebuild the UI
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("authToken") ?? "";

      final url = Uri.parse("https://gst.billcare.in/api/quick/receipt/update");
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
        body: {
          "ReceiptId": widget.receipt["id"].toString(),
          "Name": _nameController.text,
          "Amount": _amountController.text,
          "ChequeNo": _chequeController.text,
          "Remark": _remarkController.text,
        },
      );

      if (response.statusCode == 200) {
        // Success: pop the screen and return true
        Navigator.pop(context, true);
      } else {
        // Failure: show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update failed: ${response.body}")),
        );
      }
    } catch (e) {
      // Handle network or other exceptions
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred: $e")),
      );
    } finally {
      // Stop loading and rebuild the UI, always runs regardless of success/failure
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Quick Receipt")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Client Name",
                  isDense: true,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  isDense: true,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _chequeController,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: "Cheque No (optional)",
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _remarkController,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: "Remark (optional)",
                ),
              ),
              const SizedBox(height: 30),
              // Updated ElevatedButton to handle loading state
              ElevatedButton(
                // Disable button if loading
                onPressed: _isLoading ? null : _updateReceipt,
                child: _isLoading
                    ? const SizedBox(
                        height: 20, // Define size for the indicator
                        width: 20,
                        child: CircularProgressIndicator(
                          // Set color to contrast with button background (e.g., white)
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Update Receipt"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
