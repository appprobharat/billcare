import 'package:billcare/api/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class AddQuickReceiptPage extends StatefulWidget {
  const AddQuickReceiptPage({super.key});

  @override
  State<AddQuickReceiptPage> createState() => _AddQuickReceiptPageState();
}

class _AddQuickReceiptPageState extends State<AddQuickReceiptPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController chequeController = TextEditingController();
  final TextEditingController remarkController = TextEditingController();

  bool _isSaving = false;

 Future<String?> _getToken() async {
  final token = await AuthStorage.getToken();

  if (token == null || token.isEmpty) {
    if (!mounted) return null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Session expired. Please login again."),
      ),
    );

    Navigator.pop(context);
    return null;
  }

  return token;
}


  Future<void> _saveQuickReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final token = await _getToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication token not found.")),
      );
      setState(() => _isSaving = false);
      return;
    }

    final body = {
      "Name": nameController.text.trim(),
      "Amount": amountController.text.trim(),
      if (chequeController.text.isNotEmpty)
        "ChequeNo": chequeController.text.trim(),
      if (remarkController.text.isNotEmpty)
        "Remark": remarkController.text.trim(),
    };

    final url = Uri.parse("https://gst.billcare.in/api/quick/receipt/store");

    try {
      final res = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: body,
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Quick Receipt saved successfully.")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed: ${res.body}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Quick Receipt")),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Client Name
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: "Name*",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.trim().isEmpty ? "Enter name" : null,
                ),
                const SizedBox(height: 16),

                // Amount
                TextFormField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: "Amount*",
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Enter amount";
                    }
                    if (double.tryParse(val.trim()) == null) {
                      return "Enter valid number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Cheque No (optional)
                TextFormField(
                  controller: chequeController,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: "Cheque No (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Remark (optional)
                TextFormField(
                  controller: remarkController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: "Remark (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveQuickReceipt,
                    icon: const Icon(Icons.save),
                    label: Text(_isSaving ? "Saving..." : "Save "),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
