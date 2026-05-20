import 'dart:io';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class SalesManAddReceipt extends StatefulWidget {
  final bool isEdit;
  final int? receiptId;
  final String? type;

  const SalesManAddReceipt({
    super.key,
    this.isEdit = false,
    this.receiptId,
    this.type,
  });

  @override
  State<SalesManAddReceipt> createState() => _SalesManAddReceiptState();
}

class _SalesManAddReceiptState extends State<SalesManAddReceipt> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _dateController = TextEditingController();
  late final TextEditingController _paidAmountController =
      TextEditingController();
  late final TextEditingController _notesController = TextEditingController();
  late final TextEditingController _clientController = TextEditingController();
  late final TextEditingController _beforeController = TextEditingController();
  late final TextEditingController _afterController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  double _discount = 0.0;
  bool _isEditLoading = false;
  Key _autoCompleteKey = UniqueKey();
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
  File? _attachmentFile;
  final ImagePicker _picker = ImagePicker();

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

    if (widget.isEdit && widget.receiptId != null) {
      _isEditLoading = true;

      _fetchReceiptDetails(widget.receiptId!, _selectedReceiptType!);
    } else {
      if (_selectedReceiptType != null) {
        _fetchClients(_selectedReceiptType!);
      }
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

  // // --- Network Methods ---

  // /// Retrieves the authentication token from SharedPreferences.
  // Future<String?> _getToken() async {
  //   final token = await AuthStorage.getToken();

  //   if (token == null || token.isEmpty) {
  //     if (!mounted) return null;

  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Session expired. Please login again.")),
  //     );

  //     Navigator.pop(context);
  //     return null;
  //   }

  //   return token;
  // }

  Future<void> _pickAttachment() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _attachmentFile = File(image.path);
      });
    }
  }

  Future<void> _fetchClients(String type) async {
    if (mounted) {
      setState(() {
        _clients = [];
      });
    }

    try {
      final res = await ApiService.postRequest(
        endpoint: "/get_name",
        body: {"Type": type},
      );

      if (res != null) {
        final List<dynamic> data = res;

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
        debugPrint("❌ Failed to fetch clients");
      }
    } catch (e) {
      debugPrint("⚠️ Error in _fetchClients: $e");
    } finally {}
  }

  Future<void> _getBalance(String type, int id) async {
    try {
      final res = await ApiService.postRequest(
        endpoint: "/get_balance",
        body: {"Type": type, "id": id.toString()},
      );

      if (res != null) {
        final balance = double.tryParse(res.toString()) ?? 0.0;

        setState(() {
          _amountBeforeReceipt = balance;

          _beforeController.text = balance.toStringAsFixed(2);

          _updateAfterReceipt();
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error in _getBalance: $e");
    }
  }

  Future<void> _fetchReceiptDetails(int id, String type) async {
    _setLoading(true);

    try {
      final data = await ApiService.postRequest(
        endpoint: "/receipt/edit",
        body: {"ReceiptId": id.toString(), "type": type},
      );

      if (data != null) {
        final inputDate = DateTime.tryParse(data["Date"]);

        final formattedDate = inputDate != null
            ? DateFormat('dd-MM-yyyy').format(inputDate)
            : data["Date"];

        setState(() {
          _selectedReceiptType = data["Type"];
          _selectedClientId = int.tryParse(data["NameId"].toString());

          _clientController.text = data["Name"] ?? '';

          _dateController.text = formattedDate;

          _paidAmountController.text = data["Amount"]?.toString() ?? '';

          _beforeController.text = data["BeforePay"]?.toString() ?? '';

          _afterController.text = data["AfterPay"]?.toString() ?? '';

          _selectedReceiptMode = data["Payment_Mode"]?.toString().trim();

          _notesController.text = data["Remark"] ?? '';

          _discount =
              double.tryParse(data["Discount"]?.toString() ?? "0") ?? 0.0;

          _discountController.text = _discount.toStringAsFixed(2);

          _amountBeforeReceipt =
              double.tryParse(data["BeforePay"].toString()) ?? 0.0;

          _amountAfterReceipt =
              double.tryParse(data["AfterPay"].toString()) ?? 0.0;
        });

        await _fetchClients(type);
      } else {
        debugPrint("❌ Failed to fetch receipt details");
      }
    } catch (e) {
      debugPrint("⚠️ Error in _fetchReceiptDetails: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isEditLoading = false;
        });
      }
    }
  }

  Future<void> _saveReceipt() async {
    if (!_formKey.currentState!.validate() || _selectedClientId == null) {
      if (_selectedClientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a valid client.")),
        );
      }
      return;
    }

    _setLoading(true);

    try {
      // ✅ Date format
      DateTime parsedDate;

      try {
        parsedDate = DateFormat('dd-MM-yyyy').parse(_dateController.text);
      } catch (_) {
        parsedDate = DateTime.now();
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

      // ✅ Body
      final body = {
        "Type": _selectedReceiptType ?? "Party",
        "id": _selectedClientId.toString(),
        "Date": formattedDate,
        "Amount": _paidAmountController.text,
        "Discount": _discount.toString(),
        "BeforePay": _amountBeforeReceipt.toStringAsFixed(2),
        "AfterPay": _amountAfterReceipt.toStringAsFixed(2),
        "PaymentMode": _selectedReceiptMode ?? "",
        "Remark": _notesController.text,
      };

      String endpoint;
      String successMessage;

      // ✅ Edit / Add
      if (widget.isEdit && widget.receiptId != null) {
        body["ReceiptId"] = widget.receiptId.toString();

        endpoint = "/receipt/update";

        successMessage = "✅ Receipt updated successfully";
      } else {
        endpoint = "/receipt/store";

        successMessage = "✅ Receipt saved successfully";
      }

      // ✅ Multipart API Call
      final res = await ApiService.multipartRequest(
        endpoint: endpoint,

        fields: body,

        file: _attachmentFile,

        fileField: "Attachment",
      );

      // ✅ Success
      if (res != null) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));

        Navigator.pop(context, true);
      } else {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to save receipt")),
        );
      }
    } catch (e) {
      print("⚠️ Error in _saveReceipt: $e");

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      _setLoading(false);
    }
  }

  void _updateAfterReceipt() {
    final paid = double.tryParse(_paidAmountController.text) ?? 0.0;

    setState(() {
      if (_selectedReceiptType == "Employee") {
        _amountAfterReceipt = _amountBeforeReceipt + paid;
      } else {
        // ✅ Party/Supplier logic
        _amountAfterReceipt = _amountBeforeReceipt - paid - _discount;
      }

      _afterController.text = _amountAfterReceipt.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? "Edit Receipt" : "Add Receipt"),
        centerTitle: true,
      ),
      body: _isEditLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _compactField(
                                controller: _dateController,
                                label: "Date*",
                                readOnly: true,
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime.now(),
                                    initialDate: DateTime.now(),
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
                              child: OverlayDropdown(
                                label: "Receipt Type*",
                                value: _selectedReceiptType,

                                items: _receiptTypes,

                                onSelect: (val) async {
                                  // ✅ clear old selected data
                                  _clientController.clear();

                                  _selectedClientId = null;

                                  _beforeController.clear();

                                  _afterController.clear();

                                  _paidAmountController.clear();

                                  _discountController.clear();

                                  setState(() {
                                    _selectedReceiptType = val;

                                    // ✅ clear old list
                                    _clients = [];

                                    // ✅ rebuild autocomplete
                                    _autoCompleteKey = UniqueKey();

                                    _amountBeforeReceipt = 0.0;

                                    _amountAfterReceipt = 0.0;

                                    _discount = 0.0;
                                  });

                                  // ✅ fetch new clients according to type
                                  await _fetchClients(val);
                                },
                              ),
                            ),
                          ],
                        ),

                        Autocomplete<Map<String, dynamic>>(
                          key: _autoCompleteKey,
                          optionsBuilder: (TextEditingValue value) {
                            final input = value.text.toLowerCase();
                            if (input.isEmpty) {
                              return _clients; // Show all clients on empty input
                            }
                            return _clients.where((client) {
                              final name = client["Name"]
                                  .toString()
                                  .toLowerCase();
                              return name.contains(input);
                            });
                          },
                          displayStringForOption: (option) => option["Name"],
                          onSelected: (opt) {
                            _clientController.text = opt["Name"];
                            _selectedClientId = opt["id"];

                            // ✅ Discount auto-fill
                            _discount =
                                double.tryParse(
                                  opt["Discount"]?.toString() ?? "0",
                                ) ??
                                0.0;
                            _discountController.text = _discount
                                .toStringAsFixed(2);

                            _getBalance(
                              _selectedReceiptType!,
                              _selectedClientId!,
                            );
                          },
                          fieldViewBuilder:
                              (
                                context,
                                controller,
                                focusNode,
                                onFieldSubmitted,
                              ) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (controller.text !=
                                      _clientController.text) {
                                    controller.text = _clientController.text;
                                  }
                                });

                                return _compactField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  label: "Name*",
                                  hint: widget.isEdit
                                      ? "Search Client"
                                      : "Select or search client",
                                  suffixIcon: widget.isEdit
                                      ? null
                                      : IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
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
                                  onTap: () {
                                    if (_selectedReceiptType != null &&
                                        _clients.isEmpty) {
                                      _fetchClients(_selectedReceiptType!);
                                    }

                                    focusNode.requestFocus();

                                    controller.selection =
                                        TextSelection.fromPosition(
                                          TextPosition(
                                            offset: controller.text.length,
                                          ),
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
                        if (_selectedReceiptType == "Party" ||
                            _selectedReceiptType == "Supplier") ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _compactField(
                                  controller: _beforeController,
                                  label: "Before Payment",
                                  readOnly: true,
                                  hint:
                                      "₹${_amountBeforeReceipt.toStringAsFixed(2)}",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _compactField(
                                  controller: _paidAmountController,
                                  label: "Paid Amount*",
                                  hint: "Enter paid amount",

                                  // ✅ keyboard
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),

                                  // 🔥 IMPORTANT: input formatter add करो
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],

                                  onChanged: (val) {
                                    _updateAfterReceipt();
                                  },

                                  // ✅ validation
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return "Enter amount";
                                    }

                                    final amount = double.tryParse(val);
                                    if (amount == null) {
                                      return "Enter valid number";
                                    }

                                    if (amount <= 0) {
                                      return "Amount must be > 0";
                                    }

                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _compactField(
                                  onTap: () {
                                    if (_discountController.text == "0.00") {
                                      _discountController.clear();
                                    }
                                  },
                                  controller: _discountController,
                                  label: "Discount",
                                  hint: "Enter discount",

                                  // ✅ keyboard
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),

                                  // ✅ INPUT FORMATTER (main control 🔥)
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],

                                  // ✅ VALIDATOR
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return null;

                                    if (double.tryParse(val) == null) {
                                      return "Enter valid number";
                                    }

                                    if (double.parse(val) < 0) {
                                      return "Invalid discount";
                                    }

                                    return null;
                                  },

                                  onChanged: (val) {
                                    _discount = double.tryParse(val) ?? 0.0;
                                    _updateAfterReceipt();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _compactField(
                                  controller: _afterController,
                                  label: "After Receipt",
                                  readOnly: true,
                                  hint:
                                      "₹${_amountAfterReceipt.toStringAsFixed(2)}",
                                ),
                              ),
                            ],
                          ),

                          OverlayDropdown(
                            label: "Payment Mode*",
                            value: _selectedReceiptMode,
                            items: _receiptModes,
                            onSelect: (val) {
                              setState(() {
                                _selectedReceiptMode = val;
                              });
                            },
                          ),
                        ],
                        if (_selectedReceiptType == "Employee") ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _compactField(
                                  controller: _beforeController,
                                  label: "Before Payment",
                                  readOnly: true,
                                  hint:
                                      "₹${_amountBeforeReceipt.toStringAsFixed(2)}",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _compactField(
                                  controller: _paidAmountController,
                                  label: "Paid Amount*",
                                  hint: "Enter paid amount",

                                  // ✅ keyboard
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),

                                  // 🔥 main fix: only numeric allow
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}'),
                                    ),
                                  ],

                                  onChanged: (val) {
                                    _updateAfterReceipt();
                                  },

                                  // ✅ strong validation
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return "Enter amount";
                                    }

                                    final amount = double.tryParse(val);
                                    if (amount == null) {
                                      return "Enter valid number";
                                    }

                                    if (amount <= 0) {
                                      return "Amount must be > 0";
                                    }

                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Amount After + Receipt Mode
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _compactField(
                                  controller: _afterController,
                                  label: "After Receipt",
                                  readOnly: true,
                                  hint:
                                      "₹${_amountAfterReceipt.toStringAsFixed(2)}",
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OverlayDropdown(
                                  label: "Payment Mode*",
                                  value: _selectedReceiptMode,
                                  items: _receiptModes,
                                  onSelect: (val) {
                                    setState(() {
                                      _selectedReceiptMode = val;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                        _compactField(
                          controller: _notesController,
                          label: "Notes",
                          hint: "Enter notes",
                          maxLines: 3,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Attachment",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),

                            const SizedBox(height: 6),

                            InkWell(
                              onTap: _pickAttachment,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade50,
                                ),
                                child: _attachmentFile == null
                                    ? Row(
                                        children: const [
                                          Icon(Icons.image, size: 18),
                                          SizedBox(width: 8),
                                          Text(
                                            "Choose Image (Optional)",
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ],
                                      )
                                    : Stack(
                                        alignment: Alignment.topRight,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.file(
                                              _attachmentFile!,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),

                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _attachmentFile = null;
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),

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

  Widget _compactField({
    required TextEditingController controller,
    String? label,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
    bool readOnly = false,
    bool enabled = true,
    bool autofocus = false,
    String? hint,
    FocusNode? focusNode,
    VoidCallback? onTap,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],

        TextFormField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          readOnly: readOnly,
          enabled: enabled,
          autofocus: autofocus,
          onTap: onTap,
          inputFormatters: inputFormatters,

          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            counterText: "",
            suffixIcon: suffixIcon,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
