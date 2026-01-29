import 'dart:convert';
import 'package:billcare/api/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;


class AddIncomePage extends StatefulWidget {
  final int? incomeId;
  const AddIncomePage({super.key, this.incomeId});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> items = [];
  List<String> categoryList = [];
  List<Map<String, dynamic>> itemList = [];
  String? authToken;
  String remark = "";
  bool isEditMode = false;
  bool isLoading = false;
  final TextEditingController remarkCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    initPage();
  }

  Future<void> initPage() async {
    await loadToken();

    isEditMode = widget.incomeId != null;

    if (isEditMode) {
      await fetchEditData();
    }

    setState(() {});
  }

  Future<void> fetchEditData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.post(
        Uri.parse("https://gst.billcare.in/api/income/edit"),
        headers: {"Authorization": "Bearer $authToken"},
        body: {"IncomeId": widget.incomeId.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          // ---- NULL SAFE ----
          selectedDate =
              DateTime.tryParse(data["Date"] ?? "") ?? DateTime.now();
         

          final category = (data["Category"] ?? "").toString();
          final item = (data["ItemName"] ?? "").toString();
          final price = (data["Price"] ?? "0").toString();
          final qty = (data["Quantity"] ?? "1").toString();
          remark = (data["Remark"] ?? "").toString();
          remarkCtrl.text = remark;

          double p = double.tryParse(price) ?? 0;
          double q = double.tryParse(qty) ?? 0;

          // ---- PRE-FILL ITEM ----
          items = [
            {
              "category": category,
              "item": item,
              "price": price,
              "qty": qty,
              "total": (p * q).toStringAsFixed(2),

              "priceCtrl": TextEditingController(text: price),
              "qtyCtrl": TextEditingController(text: qty),
            },
          ];
        });
      }
    } catch (e) {
      print("Edit Fetch Error: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateIncome() async {
    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://gst.billcare.in/api/income/update"),
      );

      request.headers["Authorization"] = "Bearer $authToken";

      request.fields["IncomeId"] = widget.incomeId.toString();
      request.fields["Date"] = DateFormat("yyyy-MM-dd").format(selectedDate);
      request.fields["Remark"] = remark;

      request.fields["Category"] = items[0]["category"];
      request.fields["ItemName"] = items[0]["item"];
      request.fields["Price"] = items[0]["price"];
      request.fields["Quantity"] = items[0]["qty"];

      var response = await request.send();
      var resBody = await response.stream.bytesToString();

      print("Update Response: $resBody");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Income Updated Successfully")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Update Failed")));
      }
    } catch (e) {
      print("Update Error: $e");
    }
  }

Future<void> loadToken() async {
  authToken = await AuthStorage.getToken();

  if (authToken == null || authToken!.isEmpty) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Session expired. Please login again.")),
    );
    Navigator.pop(context);
    return;
  }

  await fetchCategories();
  await fetchItems();
}


  Future<void> saveIncome() async {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add at least one item")),
      );
      return;
    }

    try {
      // Convert items into API format
      List<String> categoryArr = [];
      List<String> itemArr = [];
      List<String> priceArr = [];
      List<String> qtyArr = [];

      for (var it in items) {
        categoryArr.add(it["category"] ?? "");
        itemArr.add(it["item"] ?? "");
        priceArr.add(it["price"] ?? "0");
        qtyArr.add(it["qty"] ?? "1");
      }

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("https://gst.billcare.in/api/income/store"),
      );

      request.headers["Authorization"] = "Bearer $authToken";

      request.fields["Date"] = DateFormat("yyyy-MM-dd").format(selectedDate);
      request.fields["Remark"] = remark;

      for (var c in categoryArr) {
        request.fields["Category[]"] = c;
      }
      for (var i in itemArr) {
        request.fields["ItemName[]"] = i;
      }
      for (var p in priceArr) {
        request.fields["Price[]"] = p;
      }
      for (var q in qtyArr) {
        request.fields["Quantity[]"] = q;
      }

      print("📤 Sending Form Data: ${request.fields}");

      var response = await request.send();
      var resBody = await response.stream.bytesToString();

      print("📥 API Response: $resBody");

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Income Saved Successfully")),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed! Status: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("Save Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Something went wrong")));
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await http.post(
        Uri.parse("https://gst.billcare.in/api/inc_exp/get_category"),
        headers: {"Authorization": "Bearer $authToken"},
        body: {"type": "Income"},
      );
      print("Category Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Category Data: $data");
        setState(() {
          categoryList = List<String>.from(data.map((e) => e["Category"]));
        });
      } else {
        print("Category API Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Category Error: $e");
    }
  }

  Future<void> fetchItems() async {
    try {
      final response = await http.post(
        Uri.parse("https://gst.billcare.in/api/inc_exp/get_item"),
        headers: {"Authorization": "Bearer $authToken"},
        body: {"type": "Income"},
      );
      print("Item Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Item Data: $data");
        setState(() {
          itemList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print("Item API Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("Item Error: $e");
    }
  }

  Future<void> pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: selectedDate,
    );
    if (d != null) setState(() => selectedDate = d);
  }

  void addNewItem() {
    setState(() {
      items.add({
        "category": null,
        "item": null,
        "price": "0",
        "qty": "1",
        "total": "0",
        "priceCtrl": TextEditingController(text: "0"),
        "qtyCtrl": TextEditingController(text: "1"),
      });
    });
  }

  void removeLastItem() {
    if (items.isNotEmpty) {
      setState(() => items.removeLast());
    }
  }

  void _recalculate(int index) {
    final price = double.tryParse(items[index]["price"] ?? "0") ?? 0;
    final qty = double.tryParse(items[index]["qty"] ?? "0") ?? 0;
    setState(() {
      items[index]["total"] = (price * qty).toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Income"), elevation: 1),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                // Date Picker
                _label("Date"),
                GestureDetector(
                  onTap: pickDate,
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: _box(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat("dd-MM-yyyy").format(selectedDate)),
                        const Icon(Icons.calendar_month, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Add/Remove Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: addNewItem,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add New Item"),
                    ),
                    TextButton.icon(
                      onPressed: removeLastItem,
                      icon: const Icon(
                        Icons.remove,
                        size: 18,
                        color: Colors.red,
                      ),
                      label: const Text(
                        "Remove Last",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Item Cards
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _dropdown(
                                      "Category",
                                      items[index]["category"],
                                      categoryList,
                                      (v) => setState(
                                        () => items[index]["category"] = v,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 5,
                                    child: _dropdown(
                                      "Item",
                                      items[index]["item"],
                                      itemList
                                          .map((e) => e["ItemName"].toString())
                                          .toList(),
                                      (v) {
                                        setState(() {
                                          items[index]["item"] = v;
                                          final selected = itemList.firstWhere(
                                            (e) => e["ItemName"] == v,
                                            orElse: () => {},
                                          );

                                          final price =
                                              selected["Price"]?.toString() ??
                                              "0";
                                          items[index]["price"] = price;

                                          items[index]["priceCtrl"].text =
                                              price;

                                          // Total recalc
                                          _recalculate(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),
                              // Price, Qty, Total
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: _field(
                                      "Price",
                                      items[index]["priceCtrl"],
                                      (v) {
                                        items[index]["price"] = v;
                                        _recalculate(index);
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: _field(
                                      "Qty",
                                      items[index]["qtyCtrl"],
                                      (v) {
                                        items[index]["qty"] = v;
                                        _recalculate(index);
                                      },
                                    ),
                                  ),

                                  const SizedBox(width: 6),
                                  Expanded(
                                    flex: 2,
                                    child: _readOnly(
                                      "Total",
                                      items[index]["total"],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // Single Remark Field
                _smallField("Remark", remarkCtrl, (v) => remark = v),

                const SizedBox(height: 10),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isEditMode) {
                        updateIncome();
                      } else {
                        saveIncome();
                      }
                    },
                    child: Text(isEditMode ? "Update Income" : "Save Income"),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _smallField(
    String label,
    TextEditingController controller,
    Function(String) onChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextField(
          controller: controller,
          onChanged: onChange,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 10,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) =>
      Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(text));

  BoxDecoration _box() => BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade400),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<String> list,
    Function(String?) onChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          height: 38,

          decoration: _box(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true, // Ensures full width
              value: value,
              hint: Padding(
                padding: const EdgeInsets.all(8.0),
                child: const Text("Select", style: TextStyle(fontSize: 15)),
              ),
              items: list
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(e, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    Function(String) onChange,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            onChanged: onChange,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _readOnly(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          height: 38,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: _box().copyWith(color: Colors.grey.shade200),
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
