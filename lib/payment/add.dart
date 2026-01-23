import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddPaymentPage extends StatefulWidget {
  final bool isEdit;
  final int? paymentId;
  final String? type;

  const AddPaymentPage({
    super.key,
    this.isEdit = false,
    this.paymentId,
    this.type,
  });

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  TextEditingController clientController =
      TextEditingController(); // Stores the SELECTED client name
  final TextEditingController _beforeController = TextEditingController();
  final TextEditingController _afterController = TextEditingController();

  String? selectedPaymentType;

  String? selectedPaymentMode;
  int? selectedClientId;

  double _amountBeforePayment = 0.0;
  double _amountAfterPayment = 0.0;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isClientLoading = false;
  final List<String> _paymentTypes = ['Supplier', 'Employee', 'Party'];
  final List<String> _paymentModes = [
    'CASH',
    'NEFT',
    'IMPS',
    'RTGS',
    'PAYTM',
    'UPI',
    'IDFC',
    'CHEQUE',
    'CARD',
    'DEMAND DRAFT (DD)',
    'OTHER',
  ];

  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());

    print(
      "📝 AddPaymentPage opened | isEdit=${widget.isEdit}, "
      "paymentId=${widget.paymentId}, "
      "selectedType=${widget.type}",
    );

    if (widget.isEdit && widget.paymentId != null && widget.type != null) {
      selectedPaymentType = widget.type;
      _fetchPaymentDetails(widget.paymentId!, widget.type!);
    } else {
      // Add Mode: Default 'Supplier' सेट करें और क्लाइंट्स लोड करें
      selectedPaymentType = "Supplier";
      _fetchClients("Supplier");
    }
  }

  /// 🔹 Get token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("authToken");
    print("🔑 Token Loaded: $token");
    return token;
  }

  Future<void> _fetchClients(String type) async {
    if (!_isLoading) {
      setState(() {
        _isClientLoading = true;
        _clients = []; // Clients को क्लियर करें
      });
    }

    final token = await _getToken();
    final url = Uri.parse("https://gst.billcare.in/api/get_name");

    print("📡 Fetching clients for Type=$type");

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: {"Type": type},
      );

      print("📩 Status: ${res.statusCode}");

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        setState(() {
          _clients = data.cast<Map<String, dynamic>>();
          print("✅ Clients Loaded: ${_clients.length} clients");

          if (widget.isEdit && selectedClientId != null) {
            final match = _clients.firstWhere(
              (c) => c["id"] == selectedClientId,
              orElse: () => <String, dynamic>{},
            );
            if (match.isNotEmpty) {
              clientController.text = match["Name"];
              print(
                "✨ Matched Client (Edit Mode) & Controller Set: ${match["Name"]}",
              );
            }
          }
        });
      } else {
        print("❌ Failed to fetch clients: ${res.body}");
      }
    } catch (e) {
      print("⚠️ Error in _fetchClients: $e");
    } finally {
      setState(() {
        _isClientLoading = false;
      });
    }
  }

  Future<void> _getBalance(String type, int id) async {
    final token = await _getToken();
    final url = Uri.parse("https://gst.billcare.in/api/get_balance");

    print("📡 Fetching Balance for Type=$type, id=$id");

    setState(() {
      _beforeController.text = "Loading...";
      _afterController.text = "Loading...";
    });

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: {"Type": type, "id": id.toString()},
      );

      print("📩 Balance Response: ${res.body}");

      if (res.statusCode == 200) {
        final balance = double.tryParse(res.body) ?? 0.0;
        setState(() {
          _amountBeforePayment = balance;
          // Edit mode में, अगर AfterPay पहले से सेट नहीं है तो Calculate करें
          if (!widget.isEdit) {
            _amountAfterPayment = balance;
          }
          _beforeController.text = balance.toStringAsFixed(2);

          // Paid amount के आधार पर after amount को recalculate करें
          final paid = double.tryParse(paidAmountController.text) ?? 0.0;
          if (paid > 0.0) {
            _calculateAfterPayment(paid);
          } else {
            _afterController.text = _amountAfterPayment.toStringAsFixed(2);
          }
        });
        print(
          "💰 Balance Set: Before=$_amountBeforePayment, After=$_amountAfterPayment",
        );
      }
    } catch (e) {
      print("⚠️ Error in _getBalance: $e");
    }
  }

  void _calculateAfterPayment(double paid) {
    setState(() {
      if (selectedPaymentType == "Employee") {
        // Employee: paid amount balance से घटता है (Salary/Advance)
        _amountAfterPayment = _amountBeforePayment - paid;
      } else {
        // Supplier/Party: paid amount balance में जुड़ता है (Payment/Receipt)
        _amountAfterPayment = _amountBeforePayment + paid;
      }
      _afterController.text = _amountAfterPayment.toStringAsFixed(2);
    });
    print("💰 Calculated: Paid=$paid | After=$_amountAfterPayment");
  }

  Future<void> _fetchPaymentDetails(int id, String type) async {
    final token = await _getToken();
    final url = Uri.parse("https://gst.billcare.in/api/payment/edit");

    setState(() {
      _isLoading = true; // 💡 Loader शुरू
    });

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: {"PaymentId": id.toString(), "type": type},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print("📩 Payment List Response: ${res.body}");

        setState(() {
          selectedPaymentType = data["Type"];
          selectedClientId = data["NameId"];

          dateController.text = (() {
            try {
              final parsed = DateTime.tryParse(data["Date"]);
              if (parsed != null) {
                return DateFormat('dd-MM-yyyy').format(parsed);
              }
            } catch (_) {}
            return data["Date"];
          })();

          paidAmountController.text = data["Amount"].toString();
          _beforeController.text = data["BeforePay"].toString();
          _afterController.text = data["AfterPay"].toString();
          selectedPaymentMode = data["Payment_Mode"]?.toString().trim();
          notesController.text = data["Remark"];

          _amountBeforePayment =
              double.tryParse(data["BeforePay"].toString()) ?? 0.0;
          _amountAfterPayment =
              double.tryParse(data["AfterPay"].toString()) ?? 0.0;
        });

        // clients लोड करेंगे। अब selectedClientId सेट है, _fetchClients
        // clientController.text को सेट कर देगा।
        await _fetchClients(type);
      } else {
        print("❌ Failed to fetch payment details: ${res.body}");
      }
    } catch (e) {
      print("⚠️ Error in _fetchPaymentDetails: $e");
    } finally {
      setState(() {
        _isLoading = false; // 💡 Loader बंद
      });
    }
  }

  Future<void> _savePayment() async {
    // ✨ FIX 1: अगर पहले से सेविंग चल रही है, तो तुरंत रिटर्न करें
    if (_isSaving) {
      return;
    }

    if (!_formKey.currentState!.validate() || selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all required fields and select a valid client from the list.",
          ),
        ),
      );
      return;
    }

    // ✨ FIX 2: सेविंग शुरू करें
    setState(() {
      _isSaving = true;
    });

    final token = await _getToken();
    final inputDate = (() {
      try {
        return DateFormat('dd-MM-yyyy').parse(dateController.text);
      } catch (_) {
        return DateTime.now();
      }
    })();
    final formattedDate = DateFormat('yyyy-MM-dd').format(inputDate);
    final body = {
      "Type": selectedPaymentType ?? "Party",
      "id": selectedClientId.toString(),
      "Date": formattedDate,
      "Amount": paidAmountController.text,
      "BeforePay": _amountBeforePayment.toString(),
      "AfterPay": _amountAfterPayment.toString(),
      "PaymentMode": selectedPaymentMode ?? "",
      "Remark": notesController.text,
    };

    late Uri url;

    if (widget.isEdit && widget.paymentId != null) {
      body["PaymentId"] = widget.paymentId.toString();
      url = Uri.parse("https://gst.billcare.in/api/payment/update");
    } else {
      url = Uri.parse("https://gst.billcare.in/api/payment/store");
    }

    print("📡 Sending Payment Data: $body");

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: body, // ✅ form-data
      );

      print("📩 Payment Status: ${res.statusCode}");
      print("📩 Response: ${res.body}");

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit
                  ? "✅ Payment updated successfully"
                  : "✅ Payment saved successfully",
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Error: ${jsonDecode(res.body)['message'] ?? 'Failed to save payment'}",
            ),
          ),
        );
      }
    } catch (e) {
      print("⚠️ Error in _savePayment: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Network Error: $e")));
    } finally {
      // ✨ FIX 3: सेविंग खत्म करें, चाहे success हो या fail
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 🔹 UI Part
  @override
  Widget build(BuildContext context) {
    // 💡 Common InputDecoration for Compact Design
    const compactDecoration = InputDecoration(
      isDense: true, // Height kam karne ke liye
      contentPadding: EdgeInsets.fromLTRB(12, 12, 12, 12), // Padding kam
      border: OutlineInputBorder(),
    );

    // ✨ FIX 4: Payment Type बदलने पर Autocomplete को रीसेट करने के लिए Key
    final clientAutocompleteKey = ValueKey(selectedPaymentType);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.isEdit ? "Edit Payment" : "Add Payment"),
      ),
      body: _isLoading && widget.isEdit
          ? const Center(child: CircularProgressIndicator())
          : _isLoading && !widget.isEdit && _clients.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(
                      12,
                    ), // Global Padding reduced (16 -> 12)
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Row: Date + Payment Type
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: dateController,
                                  readOnly: true,
                                  decoration: compactDecoration.copyWith(
                                    labelText: "Date*",
                                  ),
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now(),
                                      initialDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      dateController.text = DateFormat(
                                        'dd-MM-yyyy',
                                      ).format(picked);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Spacing reduced (12 -> 8)
                              Expanded(
                                child: widget.isEdit
                                    ? _buildTextFormField(
                                        controller: TextEditingController(
                                          text: selectedPaymentType,
                                        ),
                                        labelText: "Receipt Type",
                                        readOnly:
                                            true, // Disables the dropdown in edit mode
                                      )
                                    : DropdownButtonFormField<String>(
                                        // 💡 Edit mode में Dropdown को disable/Read-only करें
                                        isExpanded: true,
                                        value: selectedPaymentType,
                                        decoration: compactDecoration.copyWith(
                                          labelText: "Payment Type*",
                                        ),
                                        items: _paymentTypes
                                            .map(
                                              (e) => DropdownMenuItem(
                                                value: e,
                                                child: Text(e),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: widget.isEdit
                                            ? null
                                            : (val) {
                                                setState(() {
                                                  selectedPaymentType = val;
                                                  // क्लाइंट से सम्बंधित सभी फील्ड्स रीसेट
                                                  clientController.clear();
                                                  selectedClientId = null;
                                                  _beforeController.clear();
                                                  _afterController.clear();
                                                  _amountBeforePayment = 0.0;
                                                  _amountAfterPayment = 0.0;
                                                  paidAmountController.clear();
                                                });

                                                _fetchClients(val!);
                                              },

                                        hint:
                                            widget.isEdit &&
                                                selectedPaymentType != null
                                            ? Text(selectedPaymentType!)
                                            : null,
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ), // Spacing reduced (16 -> 12)
                          // Client Autocomplete
                          Autocomplete<Map<String, dynamic>>(
                            key:
                                clientAutocompleteKey, // 💡 Key added for state reset
                            optionsBuilder: (TextEditingValue value) {
                              // ✅ FIX: Textfield खाली होने पर सारे Clients दिखाओ (Dropdown Functionality)
                              if (value.text.isEmpty) {
                                return _clients.cast<Map<String, dynamic>>();
                              }

                              // Typing करने पर, फ़िल्टर करके दिखाओ
                              final input = value.text.toLowerCase();
                              return _clients.where((client) {
                                final name = client["Name"]
                                    .toString()
                                    .toLowerCase();
                                final contact = client["ContactNo"]
                                    .toString()
                                    .toLowerCase();
                                return name.contains(input) ||
                                    contact.contains(input);
                              }).cast<Map<String, dynamic>>();
                            },
                            displayStringForOption: (option) => option["Name"],
                            onSelected: (opt) {
                              // Client select hone par
                              setState(() {
                                clientController.text = opt["Name"];
                                selectedClientId = opt["id"];
                              });

                              print("✅ Client Selected: $opt");

                              if (selectedPaymentType != null &&
                                  selectedClientId != null) {
                                _getBalance(
                                  selectedPaymentType!,
                                  selectedClientId!,
                                );
                              }
                              // Focus हटा दें ताकि dropdown बंद हो जाए
                              FocusManager.instance.primaryFocus?.unfocus();
                            },
                            fieldViewBuilder:
                                (
                                  context,
                                  textEditingController,
                                  focusNode,
                                  onFieldSubmitted,
                                ) {
                                  // 💡 Edit Mode में `clientController.text` को Autocomplete के
                                  // इंटरनल `textEditingController` से सिंक करें
                                  if (clientController.text.isNotEmpty &&
                                      textEditingController.text !=
                                          clientController.text) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (mounted) {
                                            textEditingController.text =
                                                clientController.text;
                                            // कर्सर को अंत में रखें
                                            textEditingController.selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset:
                                                        textEditingController
                                                            .text
                                                            .length,
                                                  ),
                                                );
                                          }
                                        });
                                  }

                                  return TextFormField(
                                    // Autocomplete के इंटरनल controller का उपयोग करें
                                    controller: textEditingController,
                                    focusNode: focusNode,

                                    decoration: compactDecoration.copyWith(
                                      labelText: "Name*",

                                      suffixIcon: widget.isEdit
                                          ? null
                                          : IconButton(
                                              icon: const Icon(
                                                Icons.clear,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                textEditingController.clear();
                                                setState(() {
                                                  clientController.clear();
                                                  selectedClientId = null;
                                                  _beforeController.clear();
                                                  _afterController.clear();
                                                  _amountBeforePayment = 0.0;
                                                  _amountAfterPayment = 0.0;
                                                  paidAmountController.clear();
                                                });
                                                focusNode.unfocus();
                                              },
                                            ),
                                    ),

                                    onTap: () {
                                      if (!focusNode.hasFocus) {
                                        focusNode.requestFocus();
                                      }
                                    },

                                    onChanged: (val) {
                                      clientController.text = val;

                                      if (selectedClientId != null) {
                                        setState(() {
                                          selectedClientId = null;
                                          _beforeController.clear();
                                          _afterController.clear();
                                          _amountBeforePayment = 0.0;
                                          _amountAfterPayment = 0.0;
                                          paidAmountController.clear();
                                        });
                                      }
                                    },
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return "Please select client";
                                      }

                                      final selected = _clients.firstWhere(
                                        (c) =>
                                            c["Name"] ==
                                            clientController
                                                .text, // SELECTED clientController का उपयोग करें
                                        orElse: () => <String, dynamic>{},
                                      );
                                      if (selected.isEmpty ||
                                          selectedClientId == null) {
                                        return "Please select a valid client from the list";
                                      }
                                      return null;
                                    },
                                  );
                                },
                            optionsViewBuilder: (context, onSelected, options) {
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxHeight: 200,
                                      maxWidth: 400,
                                    ),
                                    child: ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      itemCount: options.length,
                                      itemBuilder: (context, index) {
                                        final opt = options.elementAt(index);
                                        return ListTile(
                                          visualDensity: VisualDensity
                                              .compact, // Compact list tile
                                          title: Text(
                                            opt["Name"],
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          subtitle: Text(
                                            opt["ContactNo"].toString(),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          onTap: () => onSelected(opt),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(
                            height: 12,
                          ), // Spacing reduced (16 -> 12)
                          // Amount Before + Paid Amount
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _beforeController,
                                  readOnly: true,
                                  decoration: compactDecoration.copyWith(
                                    labelText: "Before Payment",
                                    hintText:
                                        "₹${_amountBeforePayment.toStringAsFixed(2)}",
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Spacing reduced (12 -> 8)
                              Expanded(
                                child: TextFormField(
                                  controller: paidAmountController,
                                  keyboardType: TextInputType.number,
                                  decoration: compactDecoration.copyWith(
                                    labelText: "Paid Amount*",
                                  ),
                                  onChanged: (val) {
                                    final paid = double.tryParse(val) ?? 0.0;
                                    // 💡 FIX 1: Paid Amount चेंज होने पर 'After Payment' अपडेट होता है
                                    _calculateAfterPayment(paid);
                                  },
                                  validator: (val) =>
                                      val == null ||
                                          val.isEmpty ||
                                          (double.tryParse(val) ?? 0.0) <= 0
                                      ? "Enter amount > 0"
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ), // Spacing reduced (16 -> 12)
                          // Amount After + Payment Mode
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _afterController,
                                  readOnly: true,
                                  decoration: compactDecoration.copyWith(
                                    labelText: "After Payment",
                                    hintText:
                                        "₹${_amountAfterPayment.toStringAsFixed(2)}",
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ), // Spacing reduced (12 -> 8)
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: selectedPaymentMode,
                                  decoration: compactDecoration.copyWith(
                                    labelText: "Payment Mode*",
                                  ),
                                  items: _paymentModes
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => selectedPaymentMode = val),
                                  validator: (val) =>
                                      val == null ? "Select mode" : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ), // Spacing reduced (16 -> 12)
                          // Notes
                          TextFormField(
                            controller: notesController,
                            maxLines: 3,
                            decoration: compactDecoration.copyWith(
                              labelText: "Notes",
                              contentPadding: const EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                12,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ), // Spacing reduced (24 -> 16)
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              // ✨ FIX: Button को _isSaving के आधार पर disable करें
                              onPressed: _isSaving ? null : _savePayment,
                              icon: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(
                                _isSaving
                                    ? "Saving..." // ✨ FIX: Saving के दौरान टेक्स्ट बदलें
                                    : widget.isEdit
                                    ? "Update Payment"
                                    : "Save Payment",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isClientLoading)
                  const Opacity(
                    opacity: 0.8,
                    child: ModalBarrier(
                      dismissible: false,
                      color: Colors.black12,
                    ),
                  ),
                if (_isClientLoading)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }

  InputDecoration _commonInputDecoration(String labelText, Widget? suffixIcon) {
    return InputDecoration(
      labelText: labelText,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      border: const OutlineInputBorder(),
      suffixIcon: suffixIcon,
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onTap,
    String hintText = '',
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      maxLines: maxLines,
      decoration: _commonInputDecoration(
        labelText,
        suffixIcon,
      ).copyWith(hintText: hintText),
      validator: validator,
      onChanged: onChanged,
      onTap: onTap,
    );
  }
}
