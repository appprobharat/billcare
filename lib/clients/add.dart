
import 'dart:io';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:collection/collection.dart';
import 'package:billcare/clients/model.dart';

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
  StateModel? _selectedState;
  String _businessType = 'Individual';
  final _aadharCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _vendorCodeCtrl = TextEditingController();
  BankModel? _selectedBank;
  final _ifscCtrl = TextEditingController();
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
    print("Fetching initial data...");
    setState(() => _isLoadingData = true);

  try {
    final results = await Future.wait([
      ApiService.getStates(),
      ApiService.getBank(),
    ]);
  

   
    

      _states = results[0] as List<StateModel>;
      _banks = results[1] as List<BankModel>;

      if (widget.clientId != null) {
        final clientDetails = await ApiService.getClientDetails(
          widget.clientId!,
        );
        if (clientDetails != null) _populateFields(clientDetails);
      }

      if (mounted) setState(() => _isLoadingData = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
      print("Error: $e");
    }
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
      _openingBalanceCtrl.text = data['OpeningBalance']?.toString() ?? '';

      _selectedState = _states.firstWhereOrNull(
        (s) => s.id.toString() == data['State'].toString(),
      );
      _selectedBank = _banks.firstWhereOrNull(
        (b) => b.id.toString() == data['Bank'].toString(),
      );

      _clientImageUrl = data['Image']?.toString();
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
                _toggleDropdown(label);
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
      });
    }
  }

  Future<void> _saveClient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingClient = true);

    Map<String, String> data = {
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
      "OpeningBalance": _openingBalanceCtrl.text.trim(),
      "Photo": _clientImage == null ? (_clientImageUrl ?? "") : "",
    };

    bool success;

    if (widget.clientId != null) {
      success = await ApiService.updateClient(
        widget.clientId!, // ✅ ONLY id
        data,
        _clientImage, // ✅ image
      );
    } else {
      success = await ApiService.storeClient(data, _clientImage);
    }

    if (!mounted) return;

    setState(() => _isSavingClient = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? "Client saved successfully" : "Failed to save client",
        ),
      ),
    );

    if (success) Navigator.pop(context, true);
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
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: "Name *", isDense: true),
          validator: (v) => v!.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _contactCtrl,
          decoration: const InputDecoration(
            labelText: "Contact No *",
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          maxLength: 10,
          validator: (v) => v!.length == 10 ? null : "10 digits required",
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _gstCtrl,
          decoration: const InputDecoration(labelText: "GST No", isDense: true),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressCtrl,
          decoration: const InputDecoration(
            labelText: "Address",
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        // Custom Dropdown for State
        CompositedTransformTarget(
          link: _stateLayerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown('state'),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: "Select State *",
                  labelStyle: const TextStyle(fontSize: 13),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down, size: 18),
                ),
                controller: TextEditingController(
                  text: _selectedState?.name ?? "",
                ),
                style: const TextStyle(fontSize: 13, height: 1.3),
                validator: (_) => _selectedState == null ? "Required" : null,
              ),
            ),
          ),
        ),
        if (_showStateList)
          CompositedTransformFollower(
            link: _stateLayerLink,
            offset: const Offset(0, 45), // 👈 adjust popup position vertically
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildOverlayDropdown<StateModel>(
                items: _states,
                label: 'state',
                itemLabel: (s) => s.name,
                onSelect: (s) => setState(() => _selectedState = s),
              ),
            ),
          ),
      ],
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
        TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(labelText: "Email", isDense: true),
        ),
        const SizedBox(height: 12),
        // Custom Bank dropdown
        CompositedTransformTarget(
          link: _bankLayerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown('bank'),
            child: AbsorbPointer(
              child: TextFormField(
                decoration: InputDecoration(
                  labelText: "Select Bank",
                  labelStyle: const TextStyle(fontSize: 13),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 10,
                  ),
                  suffixIcon: const Icon(Icons.arrow_drop_down, size: 18),
                ),
                controller: TextEditingController(
                  text: _selectedBank?.name ?? "",
                ),
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
            ),
          ),
        ),
        if (_showBankList)
          CompositedTransformFollower(
            link: _bankLayerLink,
            offset: const Offset(0, 45),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: _buildOverlayDropdown<BankModel>(
                items: _banks,
                label: 'bank',
                itemLabel: (b) => b.name,
                onSelect: (b) => setState(() => _selectedBank = b),
              ),
            ),
          ),

        const SizedBox(height: 12),
        TextFormField(
          controller: _ifscCtrl,
          decoration: const InputDecoration(
            labelText: "IFSC Code",
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: const Text("Pick Client Image"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.clientId != null ? "Edit Client" : "Add Client"),
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPrimaryFields(),
                    const SizedBox(height: 10),
                    ExpansionTile(
                      title: const Text("Add More Details"),
                      children: [_buildMoreDetailsFields()],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _isSavingClient ? null : _saveClient,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isSavingClient
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Save Client"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
