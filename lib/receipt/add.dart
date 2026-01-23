import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AddReceiptPage extends StatefulWidget {
  final bool isEdit;
  final int? receiptId;
  final String? type;

  const AddReceiptPage({
    super.key,
    this.isEdit = false,
    this.receiptId,
    this.type,
  });

  @override
  State<AddReceiptPage> createState() => _AddReceiptPageState();
}

class _AddReceiptPageState extends State<AddReceiptPage> {
  // --- Constants and Controllers ---
  static const String _baseUrl = "https://gst.billcare.in/api";

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _dateController = TextEditingController();
  late final TextEditingController _paidAmountController =
      TextEditingController();
  late final TextEditingController _notesController = TextEditingController();
  late final TextEditingController _clientController = TextEditingController();
  late final TextEditingController _beforeController = TextEditingController();
  late final TextEditingController _afterController = TextEditingController();

  final List<String> _receiptTypes = ['Party', 'Supplier', 'Employee'];
  final List<String> _receiptModes = [
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

  // --- State Variables ---
  String? _selectedReceiptType;
  String? _selectedReceiptMode;
  int? _selectedClientId;
  bool isLoading = false;
  List<Map<String, dynamic>> _clients = [];
  double _amountBeforeReceipt = 0.0;
  double _amountAfterReceipt = 0.0;

  // --- Helper to safely manage loading state ---
  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd-MM-yyyy').format(DateTime.now());
    _selectedReceiptType = widget.type ?? "Party";

    // Initial client fetch for all modes
    if (_selectedReceiptType != null) {
      // Don't await here, let it run in the background
      _fetchClients(_selectedReceiptType!);
    }

    if (widget.isEdit && widget.receiptId != null) {
      _fetchReceiptDetails(widget.receiptId!, _selectedReceiptType!);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _paidAmountController.dispose();
    _notesController.dispose();
    _clientController.dispose();
    _beforeController.dispose();
    _afterController.dispose();
    super.dispose();
  }

  // --- Network Methods ---

  /// Retrieves the authentication token from SharedPreferences.
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("authToken");
    return token;
  }

  /// Fetches the list of clients based on the selected receipt type.
  Future<void> _fetchClients(String type) async {
    // Clear existing clients to ensure only the new type's clients are available
    if (mounted) {
      setState(() {
        _clients = [];
      });
    }

    _setLoading(true);

    final token = await _getToken();
    final url = Uri.parse("$_baseUrl/get_name");

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: {"Type": type},
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);

        setState(() {
          _clients = data.cast<Map<String, dynamic>>();
        });

        if (widget.isEdit && _selectedClientId != null) {
          final match = _clients.firstWhere(
            (c) => c["id"] == _selectedClientId,
            orElse: () => <String, dynamic>{},
          );
          if (match.isNotEmpty && _clientController.text.isEmpty) {
            _clientController.text = match["Name"];
          }
        }
      } else {
        print("❌ Failed to fetch clients: ${res.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error in _fetchClients: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _getBalance(String type, int id) async {
    final token = await _getToken();
    final url = Uri.parse("$_baseUrl/get_balance");

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: {"Type": type, "id": id.toString()},
      );

      if (res.statusCode == 200) {
        final balance = double.tryParse(res.body) ?? 0.0;
        setState(() {
          _amountBeforeReceipt = balance;

          // CRITICAL FOR ADD MODE: Auto-fill logic
          // Set the "Before Receipt" field
          _beforeController.text = balance.toStringAsFixed(2);

          // Calculate and set the "After Receipt" field
          _updateAfterReceipt();
        });
      }
    } catch (e) {
      print("⚠️ Error in _getBalance: $e");
    }
  }

  /// Fetches details for an existing receipt in Edit mode.
  Future<void> _fetchReceiptDetails(int id, String type) async {
    _setLoading(true); // Start loading when fetching details
    final token = await _getToken();
    final url = Uri.parse("$_baseUrl/receipt/edit");

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: {"ReceiptId": id.toString(), "type": type},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        final inputDate = DateTime.tryParse(data["Date"]);
        final formattedDate = inputDate != null
            ? DateFormat('dd-MM-yyyy').format(inputDate)
            : data["Date"];

        setState(() {
          _selectedReceiptType = data["Type"];
          _selectedClientId = data["NameId"];
          _clientController.text = data["Name"] ?? '';
          _dateController.text = formattedDate;
          _paidAmountController.text = data["Amount"]?.toString() ?? '';
          _beforeController.text = data["BeforePay"]?.toString() ?? '';
          _afterController.text = data["AfterPay"]?.toString() ?? '';
          _selectedReceiptMode = data["Payment_Mode"]?.toString().trim();
          _notesController.text = data["Remark"] ?? '';

          _amountBeforeReceipt =
              double.tryParse(data["BeforePay"].toString()) ?? 0.0;
          _amountAfterReceipt =
              double.tryParse(data["AfterPay"].toString()) ?? 0.0;
        });

        // Ensure clients are fetched and updated with the initial values
        await _fetchClients(type);
      } else {
        print("❌ Failed to fetch receipt details: ${res.statusCode}");
      }
    } catch (e) {
      print("⚠️ Error in _fetchReceiptDetails: $e");
    } finally {
      _setLoading(false); // Stop loading when done
    }
  }

  /// Saves or updates the receipt.
  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate() || _selectedClientId == null) {
      // Show a message if client is not selected
      if (_selectedClientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a valid client.")),
        );
      }
      return;
    }

    _setLoading(true);

    final token = await _getToken();

    // Safely parse and format the date
    DateTime? parsedDate;
    try {
      parsedDate = DateFormat('dd-MM-yyyy').parse(_dateController.text);
    } catch (_) {
      // Fallback in case of parsing error, though unlikely with date picker
      parsedDate = DateTime.now();
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

    final body = {
      "Type": _selectedReceiptType ?? "Party",
      "id": _selectedClientId.toString(),
      "Date": formattedDate,
      "Amount": _paidAmountController.text,
      // Pass the actual amount values for the API
      "BeforePay": _amountBeforeReceipt.toStringAsFixed(2),
      "AfterPay": _amountAfterReceipt.toStringAsFixed(2),
      "PaymentMode": _selectedReceiptMode ?? "",
      "Remark": _notesController.text,
    };

    late Uri url;
    String successMessage;

    if (widget.isEdit && widget.receiptId != null) {
      body["ReceiptId"] = widget.receiptId.toString();
      url = Uri.parse("$_baseUrl/receipt/update");
      successMessage = "✅ Receipt updated successfully";
    } else {
      url = Uri.parse("$_baseUrl/receipt/store");
      successMessage = "✅ Receipt saved successfully";
    }

    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: body,
      );

      if (res.statusCode == 200) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));
        Navigator.pop(context, true);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Error: ${res.body}")));
      }
    } catch (e) {
      print("⚠️ Error in _saveReceipt: $e");
    } finally {
      _setLoading(false);
    }
  }

  /// Calculates and updates the 'After Receipt' field.
  void _updateAfterReceipt() {
    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;
    setState(() {
      // Logic for balance calculation:
      if (_selectedReceiptType == "Employee") {
        // Employee: Balance increases (Receipt is payment *to* employee, increasing their balance/loan/advance from company's perspective)
        _amountAfterReceipt = _amountBeforeReceipt + paid;
      } else {
        // Party/Supplier: Balance decreases (Receipt is payment *received* from/to them)
        _amountAfterReceipt = _amountBeforeReceipt - paid;
      }
      _afterController.text = _amountAfterReceipt.toStringAsFixed(2);
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Edit Receipt" : "Add Receipt"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Row: Date + Receipt Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextFormField(  
                          controller: _dateController,
                          labelText: "Date*",
                          readOnly: true,
                          // Date picker enabled for all modes
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDate:
                                  DateFormat(
                                    'dd-MM-yyyy',
                                  ).tryParse(_dateController.text) ??
                                  DateTime.now(),
                            );
                            if (picked != null) {
                              _dateController.text = DateFormat(
                                'dd-MM-yyyy',
                              ).format(picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        // Disable Receipt Type in Edit Mode
                        child: widget.isEdit
                            ? _buildTextFormField(
                                controller: TextEditingController(
                                  text: _selectedReceiptType,
                                ),
                                labelText: "Receipt Type",
                                readOnly:
                                    true, // Disables the dropdown in edit mode
                              )
                            : DropdownButtonFormField<String>(
                                value: _selectedReceiptType,
                                decoration: _commonInputDecoration(
                                  "Receipt Type*",
                                  null,
                                ),
                                items: _receiptTypes
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val == null ||
                                      val == _selectedReceiptType) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedReceiptType = val;

                                    // CLEAR ALL CLIENT-SPECIFIC FIELDS
                                    _selectedClientId = null;
                                    _clientController.clear();
                                    _amountBeforeReceipt = 0.0;
                                    _amountAfterReceipt = 0.0;
                                    _beforeController.clear();
                                    _afterController.clear();
                                    _paidAmountController
                                        .clear(); // Clear paid amount too for a fresh start in add mode
                                  });

                                  // REQUIREMENT 1: Fetch client list when receipt type changes
                                  _fetchClients(val);
                                },
                              ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Client Autocomplete (Text Field with Dropdown functionality)
                  Autocomplete<Map<String, dynamic>>(
                    optionsBuilder: (TextEditingValue value) {
                      final input = value.text.toLowerCase();
                      if (input.isEmpty) {
                        return _clients; // Show all clients on empty input
                      }
                      return _clients.where((client) {
                        final name = client["Name"].toString().toLowerCase();
                        return name.contains(input);
                      });
                    },
                    displayStringForOption: (option) => option["Name"],
                    onSelected: (opt) {
                      _clientController.text = opt["Name"];
                      _selectedClientId = opt["id"];
                      // REQUIREMENT 2: Automatically fetch balance on client select
                      _getBalance(_selectedReceiptType!, _selectedClientId!);
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onFieldSubmitted) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (controller.text != _clientController.text) {
                              controller.text = _clientController.text;
                            }
                          });

                          return TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration:
                                _commonInputDecoration(
                                  "Name*",
                                  IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      controller.clear();
                                      _clientController.clear();
                                      _selectedClientId = null;
                                      focusNode.unfocus();
                                      setState(() {
                                        _amountBeforeReceipt = 0.0;
                                        _amountAfterReceipt = 0.0;
                                        _beforeController.clear();
                                        _afterController.clear();
                                      });
                                    },
                                  ),
                                ).copyWith(
                                  hintText: widget.isEdit
                                      ? "Search Client"
                                      : "Select or search client",
                                ),
                            onTap: () {
                              // Show dropdown on click (tap)
                              if (_selectedReceiptType != null &&
                                  _clients.isEmpty) {
                                // Fetch clients if they haven't been loaded yet
                                _fetchClients(_selectedReceiptType!);
                              }

                              focusNode.requestFocus();

                              // Ensure cursor is at the end
                              controller.selection = TextSelection.fromPosition(
                                TextPosition(offset: controller.text.length),
                              );
                            },
                            validator: (val) => _selectedClientId == null
                                ? "Please select a client"
                                : null,
                          );
                        },
                    optionsViewBuilder: (context, onSelected, options) {
                      return Align(
                        alignment: Alignment.topLeft,
                        child: Material(
                          elevation: 4,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 220,
                              maxWidth: double.infinity,
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final opt = options.elementAt(index);
                                return ListTile(
                                  dense: true,
                                  title: Text(opt["Name"]),
                                  subtitle: Text(
                                    opt["ContactNo"]?.toString() ?? '',
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

                  const SizedBox(height: 12),

                  // Amount Before + Paid Amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _beforeController,
                          labelText: "Before Receipt",
                          readOnly: true, // Should be read-only
                          hintText:
                              "₹${_amountBeforeReceipt.toStringAsFixed(2)}",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextFormField(
                          controller: _paidAmountController,
                          labelText: "Paid Amount*",
                          keyboardType: TextInputType.number,
                          onChanged: (val) =>
                              _updateAfterReceipt(), // Updates 'After' field dynamically
                          validator: (val) => val == null || val.isEmpty
                              ? "Enter amount"
                              : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Amount After + Receipt Mode
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTextFormField(
                          controller: _afterController,
                          labelText: "After Receipt",
                          readOnly: true, // Should be read-only
                          hintText:
                              "₹${_amountAfterReceipt.toStringAsFixed(2)}",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedReceiptMode,
                          decoration: _commonInputDecoration(
                            "Receipt Mode*",
                            null,
                          ),
                          items: _receiptModes
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedReceiptMode = val),
                          validator: (val) =>
                              val == null ? "Select mode" : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Notes
                  _buildTextFormField(
                    controller: _notesController,
                    labelText: "Notes",
                    maxLines: 3,
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : _saveReceipt,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.isEdit ? "Update Receipt" : "Save Receipt",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
