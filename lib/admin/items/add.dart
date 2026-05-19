import 'dart:io';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const double kCompactSpacing = 8.0;
const double kHorizontalSpacing = 12.0;

class AddItemPage extends StatefulWidget {
  final String? itemId;

  const AddItemPage({super.key, this.itemId});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final nameCtrl = TextEditingController();
  final skuCtrl = TextEditingController();
  final hsnCtrl = TextEditingController();
  final salesPriceCtrl = TextEditingController();
  final purchasePriceCtrl = TextEditingController();
  final mrpCtrl = TextEditingController();
  final brandCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: "0");
  final partNoCtrl = TextEditingController();
  final dragNoCtrl = TextEditingController();
  final imagecontroller = TextEditingController();

  // New Controllers and FocusNodes for custom dropdown fields
  final categoryCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  final categoryFocus = FocusNode();
  final unitFocus = FocusNode();
  final gstCtrl = TextEditingController(); // नया Controller
  final gstFocus = FocusNode();
  // State Variables
  String? selectedType = "Goods";
  String? selectedCategoryId; // ID to send to API
  String? selectedUnit = "1"; // ID to send to API
  String? selectedGST = "0";
  bool isEditLoading = false;
  bool showMore = false;
  File? itemImage;
  List<Map<String, dynamic>> categoryList = [];
  List<Map<String, dynamic>> unitLists = [];

  // Loader States for better control
  bool isSaving = false;
  bool isCategoryLoading = false;
  bool isUnitLoading = false;

  // Key to get the position/size of the Category field
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _unitKey = GlobalKey();
  final GlobalKey _gstKey = GlobalKey();
  // Overlay Management
  OverlayEntry? _overlayEntry;

  final List<Map<String, dynamic>> taxes = [
    {"value": "0", "label": "0%"},
    {"value": "5", "label": "5%"},
    {"value": "12", "label": "12%"},
    {"value": "18", "label": "18%"},
    {"value": "28", "label": "28%"},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
    if (widget.itemId != null) {
      isEditLoading = true;
      loadItemData(widget.itemId!);
    }
    if (selectedGST == "0") {
      final defaultTax = taxes.firstWhere(
        (tax) => tax['value'] == "0",
        orElse: () => taxes.first,
      );
      gstCtrl.text = defaultTax['label'].toString();
    }

    categoryFocus.addListener(() {
      if (!categoryFocus.hasFocus) {
        _removeOverlay();
      }
    });
    unitFocus.addListener(() {
      if (!unitFocus.hasFocus) {
        _removeOverlay();
      }
    });
    gstFocus.addListener(() {
      if (!gstFocus.hasFocus) {
        _removeOverlay();
      }
    });
  }

  void _loadAllData() {
    loadCategories();
    loadunits();
  }

  Widget _buildHalfWidthField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Expanded(
      child: _compactField(
        controller: controller,
        label: label,
        hint: label,
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Future<void> loadItemData(String itemId) async {
    final data = await ApiService.fetchItemForEdit(itemId);

    if (data == null) {
      setState(() => isEditLoading = false);
      return;
    }

    setState(() {
      selectedType = data["Type"];

      nameCtrl.text = data["Name"] ?? "";
      skuCtrl.text = data["SKUCode"] ?? "";
      hsnCtrl.text = data["HSNCode"] ?? "";
      salesPriceCtrl.text = data["SalePrice"] ?? "";
      purchasePriceCtrl.text = data["PurchasePrice"] ?? "";
      mrpCtrl.text = data["MRP"] ?? "";
      brandCtrl.text = data["Brand"] ?? "";
      stockCtrl.text = data["Stock"] ?? "0";
      partNoCtrl.text = data["PartNo"] ?? "";
      dragNoCtrl.text = data["DrgNo"] ?? "";

      selectedCategoryId = data["CategoryId"]?.toString();
      selectedUnit = data["Unit"]?.toString();

      final category = categoryList.firstWhere(
        (c) => c["id"].toString() == selectedCategoryId,
        orElse: () => {},
      );

      categoryCtrl.text = category["Name"] ?? "";

      final unit = unitLists.firstWhere(
        (u) => u["id"].toString() == selectedUnit,
        orElse: () => {},
      );

      unitCtrl.text = unit["Unit"] ?? "";

      if (data["CGST"] != null) {
        double cgst = double.tryParse(data["CGST"].toString()) ?? 0;
        double sgst = double.tryParse(data["SGST"].toString()) ?? 0;
        selectedGST = (cgst + sgst).toString();
        gstCtrl.text = "$selectedGST%";
      }

      isEditLoading = false;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay({
    required GlobalKey key,
    required List<Map<String, dynamic>> list,
    required String labelKey,
    required String valueKey,
    required Function(String value, String label) onItemSelected,
  }) {
    // If an overlay is already showing, remove it
    if (_overlayEntry != null) {
      _removeOverlay();
      return; // Toggle off if tapped again
    }

    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy + size.height + 4.0,
        width: size.width,
        child: Material(
          elevation: 8.0,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final value = item[valueKey].toString();
                final label = item[labelKey].toString();
                return ListTile(
                  dense: true,

                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 0.0,
                  ),
                  title: Text(label, style: const TextStyle(fontSize: 14)),
                  visualDensity: const VisualDensity(vertical: -4),
                  onTap: () {
                    onItemSelected(value, label);
                    _removeOverlay();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildCustomDropdownField({
    required GlobalKey key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String labelText,
    required List<Map<String, dynamic>> list,
    required bool isLoading,
    required String labelKey,
    required String valueKey,
    required Function(String value, String label) onItemSelected,
  }) {
    return Expanded(
      key: key,
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              if (!isLoading) {
                focusNode.requestFocus();
                _showOverlay(
                  key: key,
                  list: list,
                  labelKey: labelKey,
                  valueKey: valueKey,
                  onItemSelected: onItemSelected,
                );
              }
            },
            child: AbsorbPointer(
              child: _compactField(
                controller: controller,
                label: labelText,
                hint: "Select $labelText",
              ),
            ),
          ),

          /// Dropdown arrow icon
          Positioned(
            right: 10,
            top: 30,
            child: Icon(Icons.arrow_drop_down, color: AppColors.primary),
          ),

          /// Loading indicator
          if (isLoading)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  // --- API and Image Picking ---

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => itemImage = File(picked.path));
    }
  }

  void loadCategories() async {
    setState(() => isCategoryLoading = true);

    try {
      final categories = await ApiService.fetchCategoryList();
      if (!mounted) return;

      setState(() {
        categoryList = categories.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint("❌ loadCategories error: $e");
    } finally {
      if (mounted) setState(() => isCategoryLoading = false);
    }
  }

  void loadunits() async {
    setState(() => isUnitLoading = true);

    try {
      final unit = await ApiService.getUnit();
      if (!mounted) return;

      setState(() {
        unitLists = unit.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      debugPrint("❌ loadunits error: $e");
    } finally {
      if (mounted) setState(() => isUnitLoading = false);
    }
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    _removeOverlay();

    setState(() => isSaving = true);

    final itemData = {
      "ItemId": widget.itemId ?? "",
      "Type": selectedType ?? "Goods",
      "Name": nameCtrl.text.trim(),
      "CategoryId": selectedCategoryId ?? '0',
      "SKUCode": skuCtrl.text.trim(),
      "PartNo": partNoCtrl.text.trim(),
      "DrgNo": dragNoCtrl.text.trim(),
      "HSNCode": hsnCtrl.text.trim(),
      "MRP": mrpCtrl.text.trim(),
      "SalePrice": salesPriceCtrl.text.trim(),
      "PurchasePrice": purchasePriceCtrl.text.trim(),
      "Brand": brandCtrl.text.trim(),
      "Unit": selectedUnit ?? '1',
      "GST": selectedGST ?? '0',
      "Stock": stockCtrl.text.trim(),
    };

    bool success;

    try {
      /// ADD ITEM
      if (widget.itemId == null) {
        success = await ApiService.storeData(itemData, itemImage);
      }
      /// UPDATE ITEM
      else {
        success = await ApiService.updateItem(itemData, itemImage);
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.itemId == null
                  ? "✅ Item stored successfully"
                  : "✅ Item updated successfully",
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ Failed to save item")));
      }
    } catch (e) {
      debugPrint("❌ saveItem error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error while saving item")),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    skuCtrl.dispose();
    hsnCtrl.dispose();
    gstCtrl.dispose();
    salesPriceCtrl.dispose();
    purchasePriceCtrl.dispose();
    mrpCtrl.dispose();
    brandCtrl.dispose();
    stockCtrl.dispose();
    partNoCtrl.dispose();
    dragNoCtrl.dispose();
    imagecontroller.dispose();
    categoryCtrl.dispose();
    unitCtrl.dispose();
    categoryFocus.dispose();
    unitFocus.dispose();
    _removeOverlay();
    super.dispose();
  }

  Widget _buildTypeToggleBar(String label1, String label2, String selected) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ChoiceChip(
              labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
              visualDensity: VisualDensity.compact,
              label: Center(
                child: Text(
                  label1,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected == label1
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              selected: selected == label1,
              selectedColor: Colors.blue,
              backgroundColor: Colors.grey.shade100,
              onSelected: (_) => setState(() => selectedType = label1),
            ),
          ),
          const SizedBox(width: kCompactSpacing),
          Expanded(
            child: ChoiceChip(
              labelPadding: const EdgeInsets.symmetric(horizontal: 0.0),
              visualDensity: VisualDensity.compact,
              label: Center(
                child: Text(
                  label2,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: selected == label2
                        ? Colors.white
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              selected: selected == label2,
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey.shade100,
              onSelected: (_) => setState(() => selectedType = label2),
            ),
          ),
        ],
      ),
    );
  }

  // ====================== BUILD METHOD (UI) ======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          widget.itemId == null ? "Add Item" : "Update Item",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isEditLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(kHorizontalSpacing),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTypeToggleBar("Goods", "Services", selectedType!),
                    const SizedBox(height: kCompactSpacing),
                    _gradientLabel("Basic Details", [
                      Color(0xffff9966),
                      Color(0xffff5e62),
                    ]),
                    const SizedBox(height: kCompactSpacing),
                    // 2. Name
                    _compactField(
                      controller: nameCtrl,
                      label: "Name *",
                      hint: "Enter Item Name",
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Name is required'
                          : null,
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCustomDropdownField(
                          key: _categoryKey,
                          controller: categoryCtrl,
                          focusNode: categoryFocus,
                          labelText: 'Category',
                          list: categoryList,
                          isLoading: isCategoryLoading,
                          labelKey: 'Name',
                          valueKey: 'id',
                          onItemSelected: (value, label) {
                            setState(() {
                              selectedCategoryId = value;
                              categoryCtrl.text = label;
                            });
                          },
                        ),
                      ],
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHalfWidthField(skuCtrl, 'SKU Code'),
                        const SizedBox(width: kHorizontalSpacing),
                        _buildHalfWidthField(hsnCtrl, 'HSN/SAC Code'),
                      ],
                    ),
                    const SizedBox(height: kCompactSpacing),
                    _gradientLabel("Pricing Details", [
                      Color(0xff8E2DE2),
                      Color(0xffC471ED),
                    ]),
                    const SizedBox(height: kCompactSpacing),
                    Row(
                      children: [
                        _buildHalfWidthField(
                          salesPriceCtrl,
                          "Sale Price",
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(width: 10),
                        _buildHalfWidthField(
                          purchasePriceCtrl,
                          "Purchase Price",
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHalfWidthField(
                          mrpCtrl,
                          'MRP',
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(width: kHorizontalSpacing),

                        _buildCustomDropdownField(
                          key: _gstKey,
                          controller: gstCtrl,
                          focusNode: gstFocus,
                          labelText: 'GST',
                          list: taxes,
                          isLoading: false,
                          labelKey: 'label',
                          valueKey: 'value',
                          onItemSelected: (value, label) {
                            setState(() {
                              selectedGST = value;
                              gstCtrl.text = label;
                            });
                          },
                        ),
                      ],
                    ),

                    GestureDetector(
                      onTap: () => setState(() => showMore = !showMore),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(
                              showMore ? Icons.expand_less : Icons.expand_more,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Add More Details',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (showMore) ...[
                      _gradientLabel("Additional Details", [
                        Color(0xff43cea2),
                        Color(0xff185a9d),
                      ]),
                      const SizedBox(height: kCompactSpacing),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Unit Custom Dropdown
                          _buildCustomDropdownField(
                            key: _unitKey,
                            controller: unitCtrl,
                            focusNode: unitFocus,
                            labelText: 'Unit',
                            list: unitLists,
                            isLoading: isUnitLoading,
                            labelKey: 'Unit',
                            valueKey: 'id',
                            onItemSelected: (value, label) {
                              setState(() {
                                selectedUnit = value;
                                unitCtrl.text = label;
                              });
                            },
                          ),
                          const SizedBox(width: kHorizontalSpacing),
                          _buildHalfWidthField(
                            brandCtrl,
                            "Brand",
                          ), // Brand half-width
                        ],
                      ),
                      const SizedBox(height: kCompactSpacing),

                      // STOCK & PART NO
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHalfWidthField(
                            stockCtrl,
                            "Stock",
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(width: kHorizontalSpacing),
                          _buildHalfWidthField(
                            partNoCtrl,
                            "Part No",
                          ), // Part No half-width
                        ],
                      ),
                      const SizedBox(height: kCompactSpacing),

                      // DRAG NO & IMAGE PICKER
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHalfWidthField(
                            dragNoCtrl,
                            "Drag No",
                          ), // Drag No half-width
                          const SizedBox(width: kHorizontalSpacing),
                          Expanded(
                            child: Column(
                              children: [
                                /// Image Preview Box
                                Container(
                                  height: 80,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: itemImage != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            itemImage!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.camera_alt_outlined,
                                            size: 30,
                                            color: Colors.grey,
                                          ),
                                        ),
                                ),

                                const SizedBox(height: 6),

                                /// Attach Image Button
                                ElevatedButton.icon(
                                  onPressed: pickImage,
                                  icon: const Icon(
                                    Icons.upload,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    "Attach Image",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    minimumSize: const Size(
                                      double.infinity,
                                      36,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      if (itemImage != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Image.file(itemImage!, height: 100),
                          ),
                        ),
                    ],
                    const SizedBox(height: 30),
                    // 9. Save Button (Full width),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : saveItem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          elevation: 5,
                        ),
                        child: isSaving
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3.0,
                                ),
                              )
                            : Text(
                                widget.itemId == null
                                    ? "Save Item"
                                    : "Update Item",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
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
}
