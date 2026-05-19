import 'dart:io';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';
import 'package:billcare/admin/clients/model.dart';

class AddClientPage extends StatefulWidget {
  final String? clientId;
  const AddClientPage({super.key, this.clientId});
  @override
  State<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingData = true;

  List<StateModel> _states = [];
  List<BankModel> _banks = [];

  String _type = 'Party';
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  StateModel? _selectedState;
  String _businessType = 'Individual';
  final _aadharCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _vendorCodeCtrl = TextEditingController();
  BankModel? _selectedBank;
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _netPaymentCtrl = TextEditingController();
  final _openingBalanceCtrl = TextEditingController();

  File? _clientImage;
  String? _clientImageUrl;
  bool _isSavingClient = false;

  bool _showStateList = false;
  bool _showBankList = false;

  final LayerLink _stateLayerLink = LayerLink();
  final LayerLink _bankLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _fetchInitialDataAndPopulate();
  }

  Future<void> _fetchInitialDataAndPopulate() async {
    setState(() => _isLoadingData = true);

    try {
      final stateRes = await ApiService.postRequest(
        endpoint: "/get_state",
        isJson: true,
      );

      final bankRes = await ApiService.postRequest(
        endpoint: "/get_bank",
        isJson: true,
      );
      if (stateRes is List) {
        _states = stateRes
            .map((e) => StateModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (bankRes is List) {
        _banks = bankRes
            .map((e) => BankModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (widget.clientId != null) {
        final clientDetails = await ApiService.postRequest(
          endpoint: "/client/edit",
          isJson: true,
          body: {"ClientId": widget.clientId},
        );

        if (clientDetails != null) {
          _populateFields(clientDetails);
        }
      }

      setState(() => _isLoadingData = false);

      setState(() => _isLoadingData = false);
    } catch (e) {
      setState(() => _isLoadingData = false);
      print("Error: $e");
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingClient = true);

    Map<String, dynamic> data = {
      "BusinessType": _businessType,
      "Type": _type,
      "Name": _nameCtrl.text.trim(),
      "ContactNo": _contactCtrl.text.trim(),
      "Email": _emailCtrl.text.trim(),
      "PanNo": _panCtrl.text.trim(),
      "AadharNo": _aadharCtrl.text.trim(),
      "GSTIN": _gstCtrl.text.trim(),
      "Address": _addressCtrl.text.trim(),
      "State": _selectedState?.id ?? "",
      "VendorCode": _vendorCodeCtrl.text.trim(),
      "Bank": _selectedBank?.id ?? "",
      "IFSC": _ifscCtrl.text.trim(),
      "AccNo": _accountNoCtrl.text.trim(),
      "NetPayment": _netPaymentCtrl.text.trim(),
      "Pincode": _pincodeCtrl.text.trim(),
      "OpeningBalance": _openingBalanceCtrl.text.trim(),
    };
    debugPrint("📤 SEND DATA: $data");
    debugPrint("📤 PINCODE VALUE: ${_pincodeCtrl.text}");
    String endpoint = widget.clientId != null
        ? "/client/update"
        : "/client/store";

    if (widget.clientId != null) {
      data["ClientId"] = widget.clientId;
    }
    final res = await ApiService.multipartRequest(
      endpoint: endpoint,
      fields: data,
      file: _clientImage,
      fileField: "Photo",
    );
    setState(() => _isSavingClient = false);

    bool success = res != null;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Client saved successfully" : "Failed to save client",
        ),
      ),
    );

    if (success) Navigator.pop(context, true);
  }

  void _populateFields(Map<String, dynamic> data) {
    setState(() {
      _type = data['Type']?.toString() ?? 'Party';
      _nameCtrl.text = data['Name']?.toString() ?? '';
      _contactCtrl.text = data['ContactNo']?.toString() ?? '';
      _gstCtrl.text = data['GSTIN']?.toString() ?? '';
      _addressCtrl.text = data['Address']?.toString() ?? '';
      _businessType = data['BusinessType']?.toString() ?? 'Individual';
      _aadharCtrl.text = data['AadharNo']?.toString() ?? '';
      _emailCtrl.text = data['Email']?.toString() ?? '';
      _panCtrl.text = data['PanNo']?.toString() ?? '';
      _vendorCodeCtrl.text = data['VendorCode']?.toString() ?? '';
      _ifscCtrl.text = data['IFSC']?.toString() ?? '';
      _accountNoCtrl.text = data['AccNo']?.toString() ?? '';
      _netPaymentCtrl.text = data['NetPayment']?.toString() ?? '';
      _pincodeCtrl.text = data['Pincode']?.toString() ?? '';
      _openingBalanceCtrl.text = data['OpeningBalance']?.toString() ?? '';

      _selectedState = _states.firstWhereOrNull(
        (s) => s.id == data['State'].toString(),
      );
      if (_selectedState != null) {
        _stateCtrl.text = _selectedState!.name;
      }

      // ✅ BANK FIX
      _selectedBank = _banks.firstWhereOrNull(
        (b) => b.id == data['Bank'].toString(),
      );
      if (_selectedBank != null) {
        _bankCtrl.text = _selectedBank!.name;
      }
if (data['Photo'] != null && data['Photo'].toString().isNotEmpty) {
  _clientImageUrl = data['Photo'].toString();
}
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _gstCtrl.dispose();
    _addressCtrl.dispose();
    _aadharCtrl.dispose();
    _emailCtrl.dispose();
    _panCtrl.dispose();
    _vendorCodeCtrl.dispose();
    _ifscCtrl.dispose();
    _accountNoCtrl.dispose();
    _netPaymentCtrl.dispose();
    _pincodeCtrl.dispose();
    _openingBalanceCtrl.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown(String type) {
    setState(() {
      if (type == 'state') {
        _showStateList = !_showStateList;
        _showBankList = false;
      } else {
        _showBankList = !_showBankList;
        _showStateList = false;
      }
    });
  }

  Widget _buildOverlayDropdown<T>({
    required List<T> items,
    required String label,
    required Function(T) onSelect,
    required String Function(T) itemLabel,
  }) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 180), // 👈 Compact height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: Colors.grey.shade200),
          itemBuilder: (_, i) {
            return InkWell(
              onTap: () {
                onSelect(items[i]);

                setState(() {
                  _showStateList = false;
                  _showBankList = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 10,
                ),
                child: Text(
                  itemLabel(items[i]),
                  style: const TextStyle(fontSize: 13, height: 1.2),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _clientImage = File(picked.path);
        _clientImageUrl = null;
        print("Full Image URL: $_clientImageUrl");
      });
    }
  }

  Widget _buildToggleButtons(
    String label1,
    String label2,
    String selected,
    Function(String) onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: ChoiceChip(
            label: Center(child: Text(label1)),
            selected: selected == label1,
            onSelected: (_) => onChanged(label1),
            selectedColor: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ChoiceChip(
            label: Center(child: Text(label2)),
            selected: selected == label2,
            onSelected: (_) => onChanged(label2),
            selectedColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryFields() {
    return Column(
      children: [
        _buildToggleButtons(
          "Party",
          "Supplier",
          _type,
          (v) => setState(() => _type = v),
        ),
        const SizedBox(height: 8),

        _compactField(
          controller: _nameCtrl,
          label: "Name *",
          hint: "Enter client name",
          validator: (v) {
            if (v == null || v.trim().isEmpty) return "Name is required";
            return null;
          },
        ),

        _compactField(
          controller: _contactCtrl,
          label: "Contact Number",
          hint: "Enter mobile number",
          keyboardType: TextInputType.number,
          maxLength: 10,

          inputFormatters: [FilteringTextInputFormatter.digitsOnly],

          validator: (v) {
            if (v != null && v.isNotEmpty && v.length != 10) {
              return "10 digits required";
            }
            return null;
          },
        ),
        _compactField(
          controller: _gstCtrl,
          label: "GST Number",
          hint: "Enter GST number",
          validator: (v) {
            if (v != null && v.contains(".")) return "Dot not allowed";
            return null;
          },
        ),
        _compactField(
          controller: _panCtrl,
          label: "PAN Number",
          hint: "ABCDE1234F",
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v != null && v.isNotEmpty) {
              if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(v)) {
                return "Invalid PAN";
              }
            }
            return null;
          },
        ),
        _compactField(
          controller: _aadharCtrl,
          label: "Aadhar Number",
          hint: "Enter Aadhar number",
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (v) {
            if (v != null && v.isNotEmpty) {
              if (!RegExp(r'^\d{12}$').hasMatch(v)) {
                return "Enter valid 12 digit Aadhar";
              }
            }
            return null;
          },
        ),
        _gradientLabel("Address Details", [
          Color(0xff43cea2),
          Color(0xff185a9d),
        ]),
        _compactField(
          controller: _addressCtrl,
          label: "Address",
          hint: "Enter address",
        ),
        Row(
          children: [
            Expanded(
              child: _compactField(
                controller: _pincodeCtrl,
                label: "Pincode",
                hint: "Enter Pincode",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 6,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                      return "Enter valid 6 digit pincode";
                    }
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _compactField(
                controller: _vendorCodeCtrl,
                label: "Vendor Code",
                hint: "Enter Vendor Code",
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    if (!RegExp(r'^\d+$').hasMatch(v)) {
                      return "Only numbers allowed";
                    }
                  }
                  return null;
                },
              ),
            ),
          ],
        ),

        // Custom Dropdown for State
        CompositedTransformTarget(
          link: _stateLayerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown('state'),
            child: AbsorbPointer(
              child: _compactField(
                controller: _stateCtrl,
                label: "State *",
                hint: "Select State",
                suffixIcon: const Icon(Icons.arrow_drop_down),
                validator: (_) => _selectedState == null ? "Required" : null,
              ),
            ),
          ),
        ),
        if (_showStateList)
          CompositedTransformFollower(
            link: _stateLayerLink,
            offset: const Offset(0, 65),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildOverlayDropdown<StateModel>(
                items: _states,
                label: 'state',
                itemLabel: (s) => s.name,
                onSelect: (s) {
                  setState(() {
                    _selectedState = s;
                    _stateCtrl.text = s.name;
                  });
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _gradientLabel(String title, List<Color> colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMoreDetailsFields() {
    return Column(
      children: [
        _buildToggleButtons(
          "Business",
          "Individual",
          _businessType,
          (v) => setState(() => _businessType = v),
        ),
        const SizedBox(height: 12),
        _compactField(
          controller: _emailCtrl,
          label: "Email",
          hint: "Enter email address",
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        _gradientLabel("Bank Details", [Color(0xff8E2DE2), Color(0xffC471ED)]),
        const SizedBox(height: 8),

        // Custom Bank dropdown
        CompositedTransformTarget(
          link: _bankLayerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown('bank'),
            child: AbsorbPointer(
              child: _compactField(
                controller: _bankCtrl,
                label: "Bank",
                hint: "Select Bank",
                suffixIcon: const Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
        ),
        if (_showBankList)
          CompositedTransformFollower(
            link: _bankLayerLink,
            offset: const Offset(0, 65),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildOverlayDropdown<BankModel>(
                items: _banks,
                label: 'bank',
                itemLabel: (b) => b.name,
                onSelect: (b) {
                  setState(() {
                    _selectedBank = b;
                    _bankCtrl.text = b.name;
                    _showBankList = false;
                  });
                },
              ),
            ),
          ),

        _compactField(
          controller: _accountNoCtrl,
          label: "Account No",
          hint: "Enter Account No",
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _compactField(
          controller: _ifscCtrl,
          label: "IFSC Code",
          hint: "Enter IFSC",
        ),
        Row(
          children: [
            Expanded(
              child: _compactField(
                controller: _netPaymentCtrl,
                label: "Net Payment",
                hint: "Net Payment Amount",
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _compactField(
                controller: _openingBalanceCtrl,
                label: "Opening Balance",
                hint: "Opening Amount",
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.clientId != null ? "Edit Client" : "Add Client",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,

        flexibleSpace: Container(
          decoration: const BoxDecoration(color: AppColors.primary),
        ),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(blurRadius: 8, color: Colors.black12),
                          ],
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 35,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: _clientImage != null
                                        ? FileImage(_clientImage!)
                                              as ImageProvider
                                        : (_clientImageUrl != null &&
                                                  _clientImageUrl!.isNotEmpty
                                              ? NetworkImage(_clientImageUrl!)
                                                    as ImageProvider
                                              : null),
                                    child:
                                        (_clientImage == null &&
                                            (_clientImageUrl == null ||
                                                _clientImageUrl!.isEmpty))
                                        ? const Icon(Icons.person, size: 35)
                                        : null,
                                  ),

                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.pink,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),

                            const Text(
                              "Client Information",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                      _buildSectionCard(
                        title: "Basic Details",
                        colors: const [Color(0xfff953c6), Color(0xffb91d73)],
                        child: _buildPrimaryFields(),
                      ),

                      const SizedBox(height: 8),

                      _buildSectionCard(
                        title: "More Details",
                        colors: const [Color(0xff8e2de2), Color(0xffc471ed)],
                        child: _buildMoreDetailsFields(),
                      ),

                      const SizedBox(height: 20),

                      /// Save Button
                      GestureDetector(
                        onTap: _isSavingClient ? null : _saveClient,
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [Color(0xfff953c6), Color(0xffb91d73)],
                            ),
                          ),
                          child: Center(
                            child: _isSavingClient
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Save Client",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _compactField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int? maxLength,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            counterText: "",
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

  Widget _buildSectionCard({
    required String title,
    required List<Color> colors,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }
}
