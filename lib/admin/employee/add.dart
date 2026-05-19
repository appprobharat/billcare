import 'dart:io';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/admin/clients/model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:collection/collection.dart';

class AddEmployeePage extends StatefulWidget {
  final String? clientId;
  const AddEmployeePage({super.key, this.clientId});
  @override
  State<AddEmployeePage> createState() => _AddEmployeePageState();
}

class _AddEmployeePageState extends State<AddEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoadingData = true;
  bool _isSavingEmployee = false;
  List<StateModel> _states = [];
  List<BankModel> _banks = [];

  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _relativeCtrl = TextEditingController();

  final _addressCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  StateModel? _selectedState;

  final _departmentctrl = TextEditingController();
  final _designation = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _eduactionctrl = TextEditingController();
  BankModel? _selectedBank;
  final _bankCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _accountNoCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _joiningDateCtrl = TextEditingController();
  final _openingBalanceCtrl = TextEditingController();
  final _leavingDateCtrl = TextEditingController();
  bool _showUserTypeList = false;
  File? _clientImage;
  String? _clientImageUrl;

  bool _showStateList = false;
  bool _showBankList = false;

  final LayerLink _stateLayerLink = LayerLink();
  final LayerLink _bankLayerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _designations = [];

  Map<String, dynamic>? _selectedDepartment;
  Map<String, dynamic>? _selectedDesignation;

  bool _showDepartmentList = false;
  bool _showDesignationList = false;

  final LayerLink _departmentLayerLink = LayerLink();
  final LayerLink _designationLayerLink = LayerLink();
  final _userTypeCtrl = TextEditingController();
  String? _selectedUserType;

  List<String> userTypes = ["Accountant", "General"];
  @override
  void initState() {
    super.initState();
    _fetchInitialDataAndPopulate();
    loadDepartments();
    loadDesignations();
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
      await loadDepartments();
      await loadDesignations();
      if (widget.clientId != null) {
        final res = await ApiService.postRequest(
          endpoint: "/employee/edit",
          body: {"EmployeeId": widget.clientId},
        );

        if (res != null) {
        _clientImageUrl =
    res['Image'] != null && res['Image'].toString().isNotEmpty
        ? "${ApiService.baseUrl.replaceAll('/api', '')}/storage/media/employee/${res['Image']}"
        : null;
          _nameCtrl.text = res['Name'] ?? "";
          _relativeCtrl.text = res['Relation'] ?? "";
          _contactCtrl.text = res['ContactNo'].toString();
          _emailCtrl.text = res['Email'] ?? "";

          _aadharCtrl.text = res['AadharNo'].toString();
          _panCtrl.text = res['PanNo'] ?? "";

          _addressCtrl.text = res['Address'] ?? "";
          _eduactionctrl.text = res['Education'] ?? "";

          _salaryCtrl.text = res['Salary'].toString();
          _experienceCtrl.text = res['Experience'] ?? "";

          _joiningDateCtrl.text = res['JoiningDate'] ?? "";
          _openingBalanceCtrl.text = res['OpeningBalance'].toString();

          _ifscCtrl.text = res['IFSC'] ?? "";
          _accountNoCtrl.text = res['AccNo'] ?? "";

          _userTypeCtrl.text = res['UserType'] ?? "";
          _selectedUserType = res['UserType'];
          _leavingDateCtrl.text = res['LeavingDate'] ?? "";
          // 🔥 IMPORTANT (Dropdown mapping)
          _selectedDepartment = _departments.firstWhere(
            (e) => e['id'] == res['Department'],
            orElse: () => {},
          );
          _departmentctrl.text = _selectedDepartment?['Name'] ?? "";

          _selectedDesignation = _designations.firstWhere(
            (e) => e['id'] == res['Designation'],
            orElse: () => {},
          );
          _designation.text = _selectedDesignation?['Name'] ?? "";

          _selectedState = _states.firstWhere((e) => e.id == res['State']);
          _stateCtrl.text = _selectedState?.name ?? "";

          _selectedBank = _banks.firstWhere((e) => e.id == res['Bank']);
          _bankCtrl.text = _selectedBank?.name ?? "";

          setState(() {});
        }
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

  Future<void> loadDepartments() async {
    final res = await ApiService.postRequest(endpoint: "/get_department");

    if (res != null) {
      _departments = List<Map<String, dynamic>>.from(res);
      setState(() {});
    }
  }

  Future<void> loadDesignations() async {
    final res = await ApiService.postRequest(endpoint: "/get_designation");

    if (res != null) {
      _designations = List<Map<String, dynamic>>.from(res);
      setState(() {});
    }
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSavingEmployee = true);
    String endpoint = widget.clientId == null
        ? "/employee/store"
        : "/employee/update";
    try {
      var request = await ApiService.multipartRequest(
        endpoint: endpoint,
        fields: {
          if (widget.clientId != null) "EmployeeId": widget.clientId!,

          "Name": _nameCtrl.text,
          "Relative": _relativeCtrl.text,
          "ContactNo": _contactCtrl.text,
          "Email": _emailCtrl.text,
          "PanNo": _panCtrl.text,
          "AadharNo": _aadharCtrl.text,
          "Department": _selectedDepartment?['id'].toString() ?? "",
          "Designation": _selectedDesignation?['id'].toString() ?? "",
          "UserType": _selectedUserType ?? "",
          "Salary": _salaryCtrl.text,
          "Experience": _experienceCtrl.text,
          "Address": _addressCtrl.text,
          "State": _selectedState?.id.toString() ?? "",
          "Education": _eduactionctrl.text,
          "JoiningDate": _joiningDateCtrl.text,
          "OpeningBalance": _openingBalanceCtrl.text,
          "Bank": _selectedBank?.id.toString() ?? "",
          "IFSC": _ifscCtrl.text,
          "AccNo": _accountNoCtrl.text,
          if (widget.clientId != null && _leavingDateCtrl.text.isNotEmpty)
            "LeavingDate": _leavingDateCtrl.text,
        },
        file: _clientImage,
        fileField: "Photo",
      );
      final res = await request;

      if (res != null && res['status'] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res['message'] ?? "Saved")));

        Navigator.pop(context, true);
      } else {
        throw "Save failed";
      }
    } catch (e) {
      print("❌ SAVE ERROR: $e");

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error saving employee")));
    } finally {
      setState(() => _isSavingEmployee = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();

    _addressCtrl.dispose();
    _aadharCtrl.dispose();
    _emailCtrl.dispose();
    _panCtrl.dispose();

    _ifscCtrl.dispose();
    _accountNoCtrl.dispose();

    _pincodeCtrl.dispose();
    if (widget.clientId == null) {
      _leavingDateCtrl.clear();
    }
    _overlayEntry?.remove();
    super.dispose();
  }

  void _toggleDropdown(String type) {
    setState(() {
      _showStateList = false;
      _showBankList = false;
      _showDepartmentList = false;
      _showDesignationList = false;

      if (type == 'state') _showStateList = true;
      if (type == 'bank') _showBankList = true;
      if (type == 'department') _showDepartmentList = true;
      if (type == 'designation') _showDesignationList = true;
      if (type == 'usertype') _showUserTypeList = true;
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

  Widget _buildPrimaryFields() {
    return Column(
      children: [
        _compactField(
          controller: _nameCtrl,
          label: "Name *",
          hint: "Enter employee name",
        ),
        _compactField(
          controller: _relativeCtrl,
          label: "Relative Name",
          hint: "Enter relative name",
        ),
        _compactField(
          controller: _contactCtrl,
          label: "Contact Number *",
          hint: "Enter mobile number",
          keyboardType: TextInputType.number,
          maxLength: 10,
          validator: (v) {
            if (v == null || v.isEmpty) return "Required";
            if (!RegExp(r'^[0-9]{10}$').hasMatch(v)) {
              return "Enter valid 10 digit number";
            }
            return null;
          },
        ),
        _compactField(
          controller: _emailCtrl,
          label: "Email",
          hint: "Enter email",
        ),

        // Department Dropdown
        CompositedTransformTarget(
          link: _departmentLayerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown('department'),
            child: AbsorbPointer(
              child: _compactField(
                controller: _departmentctrl,
                label: "Department *",
                hint: "Select Department",
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
        ),

        if (_showDepartmentList)
          CompositedTransformFollower(
            link: _departmentLayerLink,
            offset: Offset(0, 65),
            child: _buildOverlayDropdown<Map<String, dynamic>>(
              items: _departments,
              label: 'department',
              itemLabel: (d) => d['Name'],
              onSelect: (d) {
                setState(() {
                  _selectedDepartment = d;
                  _departmentctrl.text = d['Name'];
                  _showDepartmentList = false;
                });
              },
            ),
          ),
        // Designation Dropdown
        CompositedTransformTarget(
          link: _designationLayerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown('designation'),
            child: AbsorbPointer(
              child: _compactField(
                controller: _designation,
                label: "Designation *",
                hint: "Select Designation",
                suffixIcon: Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
        ),

        if (_showDesignationList)
          CompositedTransformFollower(
            link: _designationLayerLink,
            offset: Offset(0, 65),
            child: _buildOverlayDropdown<Map<String, dynamic>>(
              items: _designations,
              label: 'designation',
              itemLabel: (d) => d['Name'],
              onSelect: (d) {
                setState(() {
                  _selectedDesignation = d;
                  _designation.text = d['Name'];
                  _showDesignationList = false;
                });
              },
            ),
          ),
        CompositedTransformTarget(
          link: _designationLayerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown('usertype'),
            child: AbsorbPointer(
              child: _compactField(
                controller: _userTypeCtrl,
                label: "User Type *",
                hint: "Select User Type",
                suffixIcon: Icon(Icons.arrow_drop_down),
                validator: (_) =>
                    _selectedUserType == null ? "Select User Type" : null,
              ),
            ),
          ),
        ),
        if (_showUserTypeList)
          _buildOverlayDropdown<String>(
            items: userTypes,
            label: 'usertype',
            itemLabel: (u) => u,
            onSelect: (u) {
              setState(() {
                _selectedUserType = u;
                _userTypeCtrl.text = u;
                _showUserTypeList = false;
              });
            },
          ),
        _gradientLabel("Address Details", [
          Color(0xff43cea2),
          Color(0xff185a9d),
        ]),
        _compactField(
          controller: _addressCtrl,
          label: "Address *",
          hint: "Enter address",
        ),

        // Custom Dropdown for State
        CompositedTransformTarget(
          link: _stateLayerLink,
          child: GestureDetector(
            onTap: () => _toggleDropdown('state'),
            child: AbsorbPointer(
              child: _compactField(
                controller: _stateCtrl,
                label: "State*",
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
        Row(
          children: [
            Expanded(
              child: _compactField(
                controller: _experienceCtrl,
                label: "Experience",
                hint: "Enter Experience",
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _compactField(
                controller: _salaryCtrl,
                label: "Salary",
                hint: "Enter Salary",
                validator: (v) {
                  if (v == null || v.isEmpty) return null;
                  if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                    return "Only numbers allowed";
                  }
                  return null;
                },
              ),
            ),
          ],
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
        _compactField(
          controller: _aadharCtrl,
          label: "Aadhar Number",
          keyboardType: TextInputType.number,
          maxLength: 12,
          validator: (v) {
            if (v == null || v.isEmpty) return "Required";
            if (!RegExp(r'^[0-9]{12}$').hasMatch(v)) {
              return "Enter valid 12 digit Aadhar";
            }
            return null;
          },
        ),

        _compactField(
          controller: _panCtrl,
          label: "PAN Number",
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (v.length != 10) return "PAN must be 10 chars";
            return null;
          },
        ),
        _compactField(
          controller: _eduactionctrl,
          label: "Education",
          hint: "Education",
          keyboardType: TextInputType.emailAddress,
        ),
        Row(
          children: [
            Expanded(
              child: _compactField(
                controller: _joiningDateCtrl,
                label: "Joining Date",
                hint: "Select Date",
                suffixIcon: Icon(Icons.calendar_today, size: 18),
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );

                  if (picked != null) {
                    _joiningDateCtrl.text =
                        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                  }
                },
              ),
            ),

            SizedBox(width: 8),

            // 🔥 ONLY SHOW IN EDIT MODE
            if (widget.clientId != null)
              Expanded(
                child: _compactField(
                  controller: _leavingDateCtrl,
                  label: "Leaving Date",
                  hint: "Select Date",
                  suffixIcon: Icon(Icons.calendar_today, size: 18),
                  readOnly: true,
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (picked != null) {
                      _leavingDateCtrl.text =
                          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                    }
                  },
                ),
              ),
          ],
        ),

        _compactField(
          controller: _openingBalanceCtrl,
          label: "Opening Balance",
          keyboardType: TextInputType.number,
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
                validator: (_) => _selectedBank == null ? "Required" : null,
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
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
              return "Only numbers allowed";
            }
            return null;
          },
        ),
        _compactField(
          controller: _ifscCtrl,
          label: "IFSC Code",
          hint: "Enter IFSC",
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
          widget.clientId != null ? "Edit Employee" : "Add Employee",
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
                              "Employee Information",
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
                        onTap: _isSavingEmployee ? null : _saveEmployee,
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
                            child: _isSavingEmployee
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    widget.clientId != null
                                        ? "Update Employee"
                                        : "Save Employee",
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
    VoidCallback? onTap,
    bool readOnly = false,
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
          readOnly: readOnly,
          onTap: onTap,
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
