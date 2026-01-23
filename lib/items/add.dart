import 'dart:io';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryColor = Color(0xFF1E3A8A);
const double kCompactSpacing = 8.0;
const double kHorizontalSpacing = 12.0;

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

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

  InputDecoration _inputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: kPrimaryColor, fontSize: 14),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 10.0,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: kPrimaryColor, width: 2),
      ),
      // Suffix icon removed from here
    );
  }

  Widget _buildHalfWidthField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Expanded(
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label).copyWith(suffixIcon: null),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  // --- Custom Dropdown Logic ---

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
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            readOnly: true,
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
            // **ICON ADDED HERE**
            decoration: _inputDecoration(labelText).copyWith(
              suffixIcon: const Icon(
                Icons.arrow_drop_down,
                color: kPrimaryColor,
              ),
            ),
            // **ICON ADDED HERE**
          ),
          if (isLoading)
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: kPrimaryColor,
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
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("authToken");

    if (token == null) {
      setState(() => isCategoryLoading = false);
      return;
    }

    try {
      final categories = await ApiService.fetchCategories(token);
      setState(() {
        categoryList = categories.map((e) => e).toList();
      });
    } catch (e) {
      // ... error handling
    } finally {
      setState(() => isCategoryLoading = false);
    }
  }

  void loadunits() async {
    setState(() => isUnitLoading = true);
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("authToken");

    if (token == null) {
      setState(() => isUnitLoading = false);
      return;
    }

    try {
      final unit = await ApiService.getUnit(token);
      setState(() {
        unitLists = unit.map((e) => e).toList();
        // डिफ़ॉल्ट चयन लॉजिक हटा दिया गया है।
        // selectedUnit और unitCtrl.text अब null/empty रहेंगे।
      });
    } catch (e) {
      // ... error handling
    } finally {
      setState(() => isUnitLoading = false);
    }
  }

  Future<void> saveItem() async {
    if (!_formKey.currentState!.validate()) return;
    _removeOverlay(); // Ensure any open dropdown is closed

    setState(() => isSaving = true);

    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("authToken");

    if (token == null) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Error: Please log in again (No Auth Token)."),
          ),
        );
      }
      return;
    }

    final itemData = {
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
      "Unit": selectedUnit ?? '1', // Use the stored ID
      "GST": selectedGST ?? '0',
      "Stock": stockCtrl.text.trim(),
      "Image": imagecontroller.text,
    };
    // 🚀 DEBUG STATEMENT 1: Print the entire data map
    print("=======================================");
    print("🚀 Data being sent to API:");
    print(itemData);
    print("=======================================");

    // 🚀 DEBUG STATEMENT 2: Print specific fields to verify IDs
    print("🔑 Selected IDs Check:");
    print("   - CategoryId: ${itemData['CategoryId']}");
    print("   - Unit: ${itemData['Unit']}");
    print("   - GST: ${itemData['GST']}");
    print("---------------------------------------");
    try {
      bool success = await ApiService.storeData(
        itemData.cast<String, String>(),
        itemImage,
        token,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Item stored successfully")),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to store item (API failed)")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ An error occurred during saving.")),
        );
      }
    } finally {
      setState(() => isSaving = false);
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
    _removeOverlay(); // Ensure overlay is removed on dispose
    super.dispose();
  }

  // Custom Toggle Buttons using ChoiceChip
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
              selectedColor: kPrimaryColor,
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
        title: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(kHorizontalSpacing),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeToggleBar("Goods", "Services", selectedType!),
              const SizedBox(height: kCompactSpacing * 2),

              // 2. Name
              TextFormField(
                controller: nameCtrl,
                decoration: _inputDecoration(
                  'Name *',
                ), // .copyWith(suffixIcon: null) हटा दिया गया है
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: kCompactSpacing),

              // 3. Category Custom Dropdown (Full width)
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
              const SizedBox(height: kCompactSpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHalfWidthField(skuCtrl, 'SKU Code'),
                  const SizedBox(width: kHorizontalSpacing),
                  _buildHalfWidthField(hsnCtrl, 'HSN/SAC Code'),
                ],
              ),
              const SizedBox(height: kCompactSpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHalfWidthField(
                    salesPriceCtrl,
                    'Sale Price',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(width: kHorizontalSpacing),
                  _buildHalfWidthField(
                    purchasePriceCtrl,
                    'Purchase Price',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              const SizedBox(height: kCompactSpacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHalfWidthField(
                    mrpCtrl,
                    'MRP',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(width: kHorizontalSpacing),
                  // 👈 DropdownButtonFormField को _buildCustomDropdownField से बदला गया है
                  _buildCustomDropdownField(
                    key: _gstKey, // GST key
                    controller: gstCtrl, // GST controller
                    focusNode: gstFocus, // GST focus node
                    labelText: 'GST',
                    list: taxes, // Static taxes list
                    isLoading: false, // Static लिस्ट के लिए
                    labelKey: 'label', // लिस्ट में key name 'label' है
                    valueKey: 'value', // लिस्ट में key name 'value' है
                    onItemSelected: (value, label) {
                      setState(() {
                        selectedGST = value;
                        gstCtrl.text = label; // चयनित मान को फ़ील्ड में दिखाएँ
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: kCompactSpacing),
              GestureDetector(
                onTap: () => setState(() => showMore = !showMore),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Icon(
                        showMore ? Icons.expand_less : Icons.expand_more,
                        color: kPrimaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add More Details',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (showMore) ...[
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
                      // Image Picker Button half-width
                      child: ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.image, color: Colors.white),
                        label: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Item Photo',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor.withOpacity(0.8),
                          visualDensity: VisualDensity.compact,
                        ),
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
                    backgroundColor: kPrimaryColor,
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
                      : const Text(
                          "Save Item",
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
}
