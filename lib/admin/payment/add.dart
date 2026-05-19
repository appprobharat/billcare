import 'package:billcare/api/api_service.dart';
import 'package:billcare/helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  File? _attachmentFile;

  final ImagePicker _picker = ImagePicker();

  Key _autoCompleteKey = UniqueKey();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController paidAmountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  TextEditingController clientController = TextEditingController();
  final TextEditingController _beforeController = TextEditingController();
  final TextEditingController _afterController = TextEditingController();
  final TextEditingController discountController = TextEditingController();
  double _discount = 0.0;
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
      selectedPaymentType = "Supplier";
      _fetchClients("Supplier");
    }
  }

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
    setState(() {
      _isClientLoading = true;
      _clients = [];
    });

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

        if (widget.isEdit && selectedClientId != null) {
          final match = _clients.firstWhere(
            (c) => c["id"] == selectedClientId,
            orElse: () => <String, dynamic>{},
          );

          if (match.isNotEmpty) {
            clientController.text = match["Name"];

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _autoCompleteKey = UniqueKey();
                });
              }
            });
          }
        }
      }
    } catch (e) {
      debugPrint("❌ _fetchClients Error: $e");
    } finally {
      setState(() {
        _isClientLoading = false;
      });
    }
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
          _amountBeforePayment = balance;

          _beforeController.text = balance.toStringAsFixed(2);

          _updateAfterPayment();
        });
      }
    } catch (e) {
      debugPrint("❌ _getBalance Error: $e");
    }
  }

  void _updateAfterPayment() {
    final paid = double.tryParse(paidAmountController.text) ?? 0.0;

    setState(() {
      if (selectedPaymentType == "Employee") {
        _amountAfterPayment = _amountBeforePayment - paid;
      } else {
        _amountAfterPayment = _amountBeforePayment + paid - _discount;
      }

      _afterController.text = _amountAfterPayment.toStringAsFixed(2);
    });
  }

  void _calculateAfterPayment(double paid) {
    setState(() {
      final after = _amountBeforePayment + paid - _discount;

      if (selectedPaymentType == "Employee") {
        _amountAfterPayment = _amountBeforePayment - paid;
      } else {
        _amountAfterPayment = after;
      }

      _afterController.text = _amountAfterPayment.toStringAsFixed(2);
    });
  }

  Future<void> _fetchPaymentDetails(int id, String type) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ApiService.postRequest(
        endpoint: "/payment/edit",

        body: {"PaymentId": id.toString(), "type": type},
      );

      if (data != null) {
        debugPrint("📩 Payment Details: $data");

        final inputDate = DateTime.tryParse(data["Date"]);

        final formattedDate = inputDate != null
            ? DateFormat('dd-MM-yyyy').format(inputDate)
            : data["Date"];

        setState(() {
          selectedPaymentType = data["Type"];

          selectedClientId = int.tryParse(data["NameId"].toString());

          dateController.text = formattedDate;

          paidAmountController.text = data["Amount"]?.toString() ?? '';

          _beforeController.text = data["BeforePay"]?.toString() ?? '';

          _afterController.text = data["AfterPay"]?.toString() ?? '';

          selectedPaymentMode = data["Payment_Mode"]?.toString().trim();

          notesController.text = data["Remark"]?.toString() ?? "";

          _discount =
              double.tryParse(data["Discount"]?.toString() ?? "0") ?? 0.0;

          discountController.text = _discount.toStringAsFixed(2);

          _amountBeforePayment =
              double.tryParse(data["BeforePay"].toString()) ?? 0.0;

          _amountAfterPayment =
              double.tryParse(data["AfterPay"].toString()) ?? 0.0;
        });

        // ✅ fetch clients according to type
        await _fetchClients(selectedPaymentType ?? type);

        final match = _clients.firstWhere(
          (c) => c["id"] == selectedClientId,
          orElse: () => <String, dynamic>{},
        );

        if (match.isNotEmpty) {
          setState(() {
            clientController.text = match["Name"];
          });
        }
      } else {
        debugPrint("❌ Failed to fetch payment details");
      }
    } catch (e) {
      debugPrint("⚠️ Error in _fetchPaymentDetails: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePayment() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate() || selectedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select valid client")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      DateTime parsedDate;

      try {
        parsedDate = DateFormat('dd-MM-yyyy').parse(dateController.text);
      } catch (_) {
        parsedDate = DateTime.now();
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(parsedDate);

      final body = {
        "Type": selectedPaymentType ?? "Party",

        "id": selectedClientId.toString(),

        "Date": formattedDate,

        "Discount": _discount.toString(),

        "Amount": paidAmountController.text,

        "BeforePay": _amountBeforePayment.toStringAsFixed(2),

        "AfterPay": _amountAfterPayment.toStringAsFixed(2),

        "PaymentMode": selectedPaymentMode ?? "",

        "Remark": notesController.text,
      };

      String endpoint;
      String successMessage;

      if (widget.isEdit && widget.paymentId != null) {
        body["PaymentId"] = widget.paymentId.toString();

        endpoint = "/payment/update";

        successMessage = "✅ Payment updated successfully";
      } else {
        endpoint = "/payment/store";

        successMessage = "✅ Payment saved successfully";
      }

      final res = await ApiService.multipartRequest(
        endpoint: endpoint,

        fields: body,

        file: _attachmentFile,

        fileField: "Attachment",
      );

      if (res != null) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(successMessage)));

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to save payment")),
        );
      }
    } catch (e) {
      debugPrint("❌ _savePayment Error: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 🔹 UI Part
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),

        title: Text(
          widget.isEdit ? "Edit Payment" : "Add Payment",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),

      body: _isLoading && widget.isEdit
          ? const Center(child: CircularProgressIndicator())
          : _isLoading && !widget.isEdit && _clients.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _compactField(
                                  controller: dateController,
                                  label: "Date*",
                                  hint: "Select date",
                                  readOnly: true,
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: widget.isEdit
                                    ? _compactField(
                                        controller: TextEditingController(
                                          text: selectedPaymentType,
                                        ),
                                        label: "Payment Type",
                                        readOnly: true,
                                      )
                                    : OverlayDropdown(
                                        label: "Payment Type*",
                                        value: selectedPaymentType,
                                        items: _paymentTypes, // 👈 direct list

                                        onSelect: (val) async {
                                          clientController.clear();

                                          selectedClientId = null;

                                          _beforeController.clear();

                                          _afterController.clear();

                                          paidAmountController.clear();

                                          discountController.clear();

                                          setState(() {
                                            selectedPaymentType = val;

                                            _clients = [];

                                            _autoCompleteKey = UniqueKey();

                                            _amountBeforePayment = 0.0;

                                            _amountAfterPayment = 0.0;

                                            _discount = 0.0;
                                          });

                                          await _fetchClients(val);
                                          setState(() {
                                            _autoCompleteKey = UniqueKey();
                                          });
                                        },
                                      ),
                              ),
                            ],
                          ),

                          Autocomplete<Map<String, dynamic>>(
                            key: _autoCompleteKey,
                            optionsBuilder: (TextEditingValue value) {
                              if (value.text.isEmpty) {
                                return _clients.cast<Map<String, dynamic>>();
                              }

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
                              setState(() {
                                clientController.text = opt["Name"];
                                selectedClientId = opt["id"];

                                // ✅ Discount fetch from client data
                                _discount =
                                    double.tryParse(
                                      opt["Discount"]?.toString() ?? "0",
                                    ) ??
                                    0.0;
                                discountController.text = _discount
                                    .toStringAsFixed(2);
                              });

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
                                  if (textEditingController.text !=
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

                                  return _compactField(
                                    controller: textEditingController,
                                    focusNode: focusNode,
                                    label: "Name*",
                                    hint: "Select Name",
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
                                            c["Name"] == clientController.text,
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

                          if (selectedPaymentType == "Employee") ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _compactField(
                                    controller: _beforeController,
                                    label: "Before Payment",
                                    readOnly: true,
                                    hint:
                                        "₹${_amountBeforePayment.toStringAsFixed(2)}",
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _compactField(
                                    controller: paidAmountController,
                                    label: "Paid Amount*",
                                    hint: "Enter paid amount",

                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),

                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],

                                    onChanged: (val) {
                                      final paid = double.tryParse(val) ?? 0.0;
                                      _calculateAfterPayment(paid);
                                    },

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
                              children: [
                                Expanded(
                                  child: _compactField(
                                    controller: _afterController,
                                    label: "After Payment",
                                    readOnly: true,
                                    hint:
                                        "₹${_amountAfterPayment.toStringAsFixed(2)}",
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OverlayDropdown(
                                    label: "Payment Mode*",
                                    value: selectedPaymentMode,
                                    items: _paymentModes,
                                    onSelect: (val) {
                                      setState(() {
                                        selectedPaymentMode = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (selectedPaymentType == "Supplier" ||
                              selectedPaymentType == "Party") ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _compactField(
                                    controller: _beforeController,
                                    label: "Before Payment",
                                    readOnly: true,
                                    hint:
                                        "₹${_amountBeforePayment.toStringAsFixed(2)}",
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _compactField(
                                    controller: paidAmountController,
                                    label: "Paid Amount*",
                                    hint: "Enter paid amount",

                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),

                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],

                                    onChanged: (val) {
                                      final paid = double.tryParse(val) ?? 0.0;
                                      _calculateAfterPayment(paid);
                                    },

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
                              children: [
                                Expanded(
                                  child: _compactField(
                                    controller: discountController,
                                    label: "Discount",
                                    hint: "Enter discount",

                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),

                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],

                                    // 🔥 FIX: click पर clear
                                    onTap: () {
                                      if (discountController.text.trim() ==
                                          "0.00") {
                                        discountController.clear();
                                      }
                                    },

                                    onChanged: (val) {
                                      _discount = double.tryParse(val) ?? 0.0;

                                      final paid =
                                          double.tryParse(
                                            paidAmountController.text,
                                          ) ??
                                          0.0;

                                      _calculateAfterPayment(paid);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _compactField(
                                    controller: _afterController,
                                    label: "After Payment",
                                    readOnly: true,
                                    hint:
                                        "₹${_amountAfterPayment.toStringAsFixed(2)}",
                                  ),
                                ),
                              ],
                            ),
                            OverlayDropdown(
                              label: "Payment Mode*",
                              value: selectedPaymentMode,
                              items: _paymentModes,
                              onSelect: (val) {
                                setState(() {
                                  selectedPaymentMode = val;
                                });
                              },
                            ),
                          ],

                          _compactField(
                            controller: notesController,
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
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
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
                                    ? "Saving..."
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
          inputFormatters: inputFormatters,
          onTap: onTap,

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
