import 'dart:convert';
import 'dart:io';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Defined a primary color for a clean look
const Color kPrimaryColor = Color(0xFF1E3A8A);
const double kCompactSpacing = 8.0; // Reduced vertical spacing
const double kHorizontalSpacing = 12.0; // Spacing between fields in a Row

class EditItemPage extends StatefulWidget {
  final int itemId;
  const EditItemPage({super.key, required this.itemId});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController skuController = TextEditingController();
  TextEditingController partNoController = TextEditingController();
  TextEditingController drgNoController = TextEditingController();
  TextEditingController hsnController = TextEditingController();
  TextEditingController mrpController = TextEditingController();
  TextEditingController salePriceController = TextEditingController();
  TextEditingController purchasePriceController = TextEditingController();
  TextEditingController brandController = TextEditingController();
  TextEditingController stockController = TextEditingController();
  // imageController is no longer necessary as image handling is file-based
  final categoryCtrl = TextEditingController();
  final unitCtrl = TextEditingController();
  final categoryFocus = FocusNode();
  final unitFocus = FocusNode();
  final gstCtrl = TextEditingController(); // नया Controller
  final gstFocus = FocusNode();
  // State Variables
  String? selectedType = "Goods"; // Default value
  String? selectedUnit;
  String? selectedGST = "0";
  File? itemImage;
  bool showMore = false;
  String? selectedCategoryId;
  List<Map<String, dynamic>> unitLists = [];
  List<Map<String, dynamic>> categoryList = [];
  bool isLoading = true;
  bool _isupdate = false;
  String? existingImageUrl;
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _unitKey = GlobalKey();
  final GlobalKey _gstKey = GlobalKey();
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
  }

  @override
  void dispose() {
    super.dispose();
    categoryFocus.dispose();
    unitFocus.dispose();
    gstFocus.dispose();
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

  // 💡 NEW METHOD: Combine all data loading
  Future<void> _loadAllData() async {
    try {
      await Future.wait<void>([loadCategories(), loadunits()]);
      // Categories and Units are loaded, now fetch item details
      await fetchItemDetails();
    } catch (e) {
      print("❌ Error during initial data loading: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Failed to load initial data.")),
        );
        setState(() => isLoading = false);
      }
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("authToken");
    if (token == null) return;

    final categories = await ApiService.fetchCategories(token);

    if (!mounted) return;
    // setState here is fine, but we will combine it in _loadAllData for cleaner final render
    categoryList = categories;

    print("✅ Categories Loaded: ${categoryList.length}");
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => itemImage = File(picked.path));
    }
  }

  Future<void> loadunits() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("authToken");
    if (token == null) return;

    final unit = await ApiService.getUnit(token);

    if (!mounted) return;
    // setState here is fine, but we will combine it in _loadAllData for cleaner final render
    unitLists = unit;

    print("✅ Units Loaded: ${unitLists.length}");
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("authToken");
  }

  String? selectedCategoryName;
  String? selectedUnitName;
  Future<void> fetchItemDetails() async {
    print("🔄 Fetching item details for ID: ${widget.itemId}");

    try {
      final token = await getToken();
      if (token == null) throw Exception("Authentication token not found.");

      var response = await http.post(
        Uri.parse("https://gst.billcare.in/api/item/edit"),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
        body: {"ItemId": widget.itemId.toString()},
      );

      print("📡 API Response Code: ${response.statusCode}");
      print("📡 API Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Parsed Item Data: $data");

        if (!mounted) return;

        setState(() {
          // Assign values
          nameController.text = data['Name']?.toString() ?? '';
          selectedCategoryId = data['CategoryId']?.toString();
          salePriceController.text = data['SalePrice']?.toString() ?? '';
          mrpController.text = data['MRP']?.toString() ?? '';
          hsnController.text = data['HSNCode']?.toString() ?? '';
          selectedUnit = data['Unit']?.toString();
          selectedType = data['Type']?.toString() ?? "Goods";
          selectedGST = data['IGST']?.toString() ?? "0";
          stockController.text = data['Stock']?.toString() ?? '';
          partNoController.text = data['PartNo']?.toString() ?? '';
          drgNoController.text = data['DrgNo']?.toString() ?? '';
          skuController.text = data['SKUCode']?.toString() ?? '';
          purchasePriceController.text =
              data['PurchasePrice']?.toString() ?? '';
          brandController.text = data['Brand']?.toString() ?? '';
          existingImageUrl = data['Image']?.toString();
          isLoading = false;
        });

        // ✅ Auto-select readable names for dropdown-like fields
        _updateDisplayNames();

        print("✅ UI Updated with Item Data:");
        print("🟦 Name: ${nameController.text}");
        print("🟨 Category: $selectedCategoryName");
        print("🟩 Unit: $selectedUnitName");
        print("🧾 GST: $selectedGST");
        print("📦 Stock: ${stockController.text}");
        print("💰 SalePrice: ${salePriceController.text}");
        print("🏷️ Brand: ${brandController.text}");
      } else {
        print("❌ Failed to load item - Status: ${response.statusCode}");
        print("❌ Response: ${response.body}");
        if (!mounted) return;
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ Failed to load item (Status: ${response.statusCode})",
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Exception fetching item: $e");
      if (mounted) setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Error fetching item details.")),
      );
    }
  }

  void _updateDisplayNames() {
    // 🟦 Auto-fill Category Name
    if (selectedCategoryId != null && categoryList.isNotEmpty) {
      final match = categoryList.firstWhere(
        (c) => c['id'].toString() == selectedCategoryId,
        orElse: () => {},
      );
      selectedCategoryName = match.isNotEmpty
          ? match['Name']?.toString()
          : null;
    }

    // 🟩 Auto-fill Unit Name
    if (selectedUnit != null && unitLists.isNotEmpty) {
      final match = unitLists.firstWhere(
        (u) => u['id'].toString() == selectedUnit,
        orElse: () => {},
      );
      selectedUnitName = match.isNotEmpty ? match['Unit']?.toString() : null;
    }

    // 🧾 Auto-fill GST label
    if (selectedGST != null && taxes.isNotEmpty) {
      final match = taxes.firstWhere(
        (t) => t['value'].toString() == selectedGST,
        orElse: () => {},
      );
      gstCtrl.text = match.isNotEmpty ? match['label']?.toString() ?? '' : '';
    }

    // ✅ Update controllers so they show text in the TextFields
    categoryCtrl.text = selectedCategoryName ?? '';
    unitCtrl.text = selectedUnitName ?? '';
    gstCtrl.text = gstCtrl.text.isEmpty ? (selectedGST ?? '') : gstCtrl.text;

    print(
      "✅ Display Updated → Category: ${categoryCtrl.text}, Unit: ${unitCtrl.text}, GST: ${gstCtrl.text}",
    );
  }

  Future<void> updateItem() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedCategoryId == null || selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select Category and Unit.")),
      );
      return;
    }

    setState(() {
      _isupdate = true;
    });

    try {
      final token = await getToken();
      if (token == null) {
        if (mounted) setState(() => _isupdate = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Authentication failed. Please login again."),
          ),
        );
        return;
      }

      final Map<String, String> itemData = {
        "ItemId": widget.itemId.toString(),
        "Type": selectedType ?? "Goods",
        "Name": nameController.text.trim(),
        "CategoryId": selectedCategoryId!,  
        "SKUCode": skuController.text.trim(),
        "PartNo": partNoController.text.trim(),
        "DrgNo": drgNoController.text.trim(),
        "HSNCode": hsnController.text.trim(),
        "MRP": mrpController.text.trim(),
        "SalePrice": salePriceController.text.trim(),
        "PurchasePrice": purchasePriceController.text.trim(),
        "Brand": brandController.text.trim(),
        "Unit": selectedUnit!, 
        "GST": selectedGST ?? "0",
        "Stock": stockController.text.trim(),
        "Image": itemImage == null ? existingImageUrl ?? '' : '',
      };

      bool success = await ApiService.updateItemWithImage(
        itemData: itemData,
        imageFile: itemImage,
        token: token,
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Item updated successfully")),
        );
        Navigator.pop(context, true);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("❌ Failed to update item. Check API logs."),
          ),
        );
      }
    } catch (e) {
      print("❌ Error updating item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error updating item: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isupdate = false;
        });
      }
    }
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
              onSelected: (_) {
                setState(() => selectedType = label1);
              },
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
              onSelected: (_) {
                setState(() => selectedType = label2);
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Item",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              child: Padding(
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
                        controller: nameController,
                        decoration: _inputDecoration("Name"),
                        validator: (value) =>
                            value!.isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: kCompactSpacing),

                      // 3. Category Dropdown
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCustomDropdownField(
                            key: _categoryKey,
                            controller: categoryCtrl,
                            focusNode: categoryFocus,
                            labelText: 'Category',
                            list: categoryList,
                            isLoading: isLoading,
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
                          Expanded(
                            child: TextFormField(
                              controller: skuController,
                              decoration: _inputDecoration("SKU Code"),
                            ),
                          ),
                          const SizedBox(width: kHorizontalSpacing),
                          Expanded(
                            child: TextFormField(
                              controller: hsnController,
                              decoration: _inputDecoration("HSN Code"),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: kCompactSpacing),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: salePriceController,
                              decoration: _inputDecoration("Sale Price"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: kHorizontalSpacing),
                          Expanded(
                            child: TextFormField(
                              controller: purchasePriceController,
                              decoration: _inputDecoration("Purchase Price"),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: kCompactSpacing),
                      // 5. MRP & GST
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: mrpController,
                              decoration: _inputDecoration("MRP"),
                              keyboardType: TextInputType.number,
                            ),
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
                      const SizedBox(height: kCompactSpacing),
                      GestureDetector(
                        onTap: () => setState(() => showMore = !showMore),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Icon(
                                showMore
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: kPrimaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
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
                            _buildCustomDropdownField(
                              key: _unitKey,
                              controller: unitCtrl,
                              focusNode: unitFocus,
                              labelText: 'Unit',
                              list: unitLists,
                              isLoading: isLoading,
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

                            Expanded(
                              child: TextFormField(
                                controller: brandController,
                                decoration: _inputDecoration("Brand"),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: kCompactSpacing),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: stockController,
                                decoration: _inputDecoration("Stock"),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: kHorizontalSpacing),
                            Expanded(
                              child: TextFormField(
                                controller: partNoController,
                                decoration: _inputDecoration("Part No"),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: kCompactSpacing),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: drgNoController,
                                decoration: _inputDecoration("Drag No"),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: kHorizontalSpacing),
                            Expanded(

                              child: ElevatedButton.icon(
                                onPressed: pickImage,
                                icon: const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                ),
                                label: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    itemImage != null
                                        ? 'Change Photo'
                                        : 'Item Photo',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kPrimaryColor.withOpacity(
                                    0.8,
                                  ),
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
                              child: Image.file(
                                itemImage!,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else if (existingImageUrl != null &&
                            existingImageUrl!.isNotEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Image.network(
                             
                                'https://gst.billcare.in/${existingImageUrl!.startsWith('/') ? existingImageUrl!.substring(1) : existingImageUrl!}',

                                height: 100,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: kPrimaryColor,
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Text("Image not found 🖼️");
                                },
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: kCompactSpacing * 2),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                        
                          onPressed: _isupdate ? null : updateItem,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            elevation: 5,
                          ),
                         
                          child: _isupdate
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3.0,
                                  ),
                                )
                              : const Text(
                                  "Update Item",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(
                        height: kHorizontalSpacing,
                      ), 
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _showOverlay({
    required GlobalKey key,
    required List<Map<String, dynamic>> list,
    required String labelKey,
    required String valueKey,
    required Function(String value, String label) onItemSelected,
  }) {
    // Remove any existing overlay
    _removeOverlay();

    final RenderBox renderBox =
        key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // 🟢 1. Transparent backdrop to detect outside taps
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _removeOverlay();
            },
            child: Container(color: Colors.transparent),
          ),

          // 🟢 2. Actual dropdown positioned where needed
          Positioned(
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
                      ),
                      title: Text(label, style: const TextStyle(fontSize: 14)),
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
        ],
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
            readOnly: false, // ✅ user can clear text manually
            onChanged: (text) {
              if (text.isEmpty) {
                // ✅ Reset selection when cleared
                if (labelText == "Category") {
                  selectedCategoryId = null;
                } else if (labelText == "Unit") {
                  selectedUnit = null;
                } else if (labelText == "GST") {
                  selectedGST = null;
                }
              }
            },
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
            decoration: _inputDecoration(labelText).copyWith(
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        // ✅ Clear text manually
                        controller.clear();
                        if (labelText == "Category") {
                          selectedCategoryId = null;
                        } else if (labelText == "Unit") {
                          selectedUnit = null;
                        } else if (labelText == "GST") {
                          selectedGST = null;
                        }
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close,
                        color: Colors.grey,
                        size: 20,
                      ),
                    ),
                  const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
                ],
              ),
            ),
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
}
