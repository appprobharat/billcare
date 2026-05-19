import 'package:billcare/Usersfolder/orders/order_history.dart';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';

class UserOrderPage extends StatefulWidget {
  final bool isEdit;
  final int? saleId;

  const UserOrderPage({super.key, this.isEdit = false, this.saleId});

  @override
  State<UserOrderPage> createState() => _UserOrderPageState();
}

class _UserOrderPageState extends State<UserOrderPage> {
  List<Map<String, dynamic>> allProducts = [];
  List<Map<String, dynamic>> filteredProducts = [];
  final TextEditingController itemController = TextEditingController();

  final TextEditingController categoryController = TextEditingController();
  bool isLoading = true;
  double get total => subtotal + gst;
  double get subtotal {
    double sum = 0;

    for (var p in allProducts) {
      double price = double.tryParse(p["SalePrice"]?.toString() ?? "0") ?? 0;

      int qty = int.tryParse(p["qty"].toString()) ?? 0;

      sum += (price * qty);
    }

    return sum;
  }

  double get gst {
    double totalGst = 0;

    for (var p in allProducts) {
      double price = double.tryParse(p["SalePrice"]?.toString() ?? "0") ?? 0;

      double gstRate = double.tryParse(p["gst"]?.toString() ?? "0") ?? 0;

      int qty = int.tryParse(p["qty"].toString()) ?? 0;

      totalGst += ((price * qty) * gstRate) / 100;
    }

    return totalGst;
  }

  @override
  void initState() {
    super.initState();

    fetchItems().then((_) {
      if (widget.isEdit && widget.saleId != null) {
        fetchSaleForEdit();
      }
    });
  }

  void filterItems() {
    final itemQuery = itemController.text.toLowerCase();

    final categoryQuery = categoryController.text.toLowerCase();

    setState(() {
      filteredProducts = allProducts.where((p) {
        final itemName = p["Name"]?.toString().toLowerCase() ?? "";

        final category = p["Category"]?.toString().toLowerCase() ?? "";

        final itemMatch = itemName.contains(itemQuery);

        final categoryMatch = category.contains(categoryQuery);

        return itemMatch && categoryMatch;
      }).toList();
    });
  }

  Future<void> fetchSaleForEdit() async {
    setState(() {
      isLoading = true;
    });

    final response = await ApiService.postRequest(
      endpoint: "/client/sale/edit",
      body: {"id": widget.saleId.toString()},
    );

    debugPrint("📝 EDIT RESPONSE = $response");

    if (response != null && response["status"] == true) {
      final data = response["data"];

      final items = List<Map<String, dynamic>>.from(data["items"]);

      for (var orderItem in items) {
        final itemId = orderItem["item_id"];

        final qty = int.tryParse(orderItem["quantity"].toString()) ?? 0;

        final index = allProducts.indexWhere(
          (e) => e["id"].toString() == itemId.toString(),
        );

        if (index != -1) {
          allProducts[index]["qty"] = qty;
        }
      }

      filteredProducts = List.from(allProducts);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchItems() async {
    setState(() {
      isLoading = true;
    });

    final response = await ApiService.postRequest(endpoint: "/get_item");

    if (response != null) {
      allProducts = List<Map<String, dynamic>>.from(
        response.map(
          (e) => Map<String, dynamic>.from(e)
            ..addAll({
              "qty": 0,
              "gst": double.tryParse(e["IGST"]?.toString() ?? "0") ?? 0.0,
            }),
        ),
      );

      filteredProducts = List.from(allProducts);
    }

    setState(() {
      isLoading = false;
    });
  }

  void increaseQty(int index) {
    setState(() {
      filteredProducts[index]["qty"]++;

      /// 🔥 MAIN LIST UPDATE
      final id = filteredProducts[index]["id"];

      final mainIndex = allProducts.indexWhere((e) => e["id"] == id);

      if (mainIndex != -1) {
        allProducts[mainIndex]["qty"] = filteredProducts[index]["qty"];
      }
    });
  }

  void decreaseQty(int index) {
    setState(() {
      if (filteredProducts[index]["qty"] > 0) {
        filteredProducts[index]["qty"]--;

        /// 🔥 MAIN LIST UPDATE
        final id = filteredProducts[index]["id"];

        final mainIndex = allProducts.indexWhere((e) => e["id"] == id);

        if (mainIndex != -1) {
          allProducts[mainIndex]["qty"] = filteredProducts[index]["qty"];
        }
      }
    });
  }

  Future<void> submitOrder({bool isEdit = false, int? saleId}) async {
    final selectedItems = allProducts.where((e) => e["qty"] > 0).toList();

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please add at least one item"),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    /// 🔥 BODY
    Map<String, dynamic> body = {
      /// 🔥 UPDATE ONLY
      if (isEdit && saleId != null) "id": saleId.toString(),

      if (isEdit) "ClientId": "1",

      "Date": DateTime.now().toString().split(" ").first,

      "SubtotalAmt": subtotal.toStringAsFixed(2),

      "TotalGSTAmt": gst.toStringAsFixed(2),

      "GrandTotalAmt": total.toStringAsFixed(2),
    };
    for (int i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];

      double price = double.tryParse(item["SalePrice"]?.toString() ?? "0") ?? 0;

      double gstRate = double.tryParse(item["gst"]?.toString() ?? "0") ?? 0;

      int qty = int.tryParse(item["qty"].toString()) ?? 0;

      double itemTotal = (price * qty);

      double gstAmt = (itemTotal * gstRate) / 100;

      body["ItemId[$i]"] = item["id"].toString();

      body["SalePrice[$i]"] = price.toStringAsFixed(2);

      body["Quantity[$i]"] = qty.toString();

      body["Discount[$i]"] = "0";

      body["GST[$i]"] = gstRate.toStringAsFixed(0);

      body["GSTAmt[$i]"] = gstAmt.toStringAsFixed(2);

      body["TotalAmt[$i]"] = (itemTotal + gstAmt).toStringAsFixed(2);
    }

    /// 🔥 ITEMS LOOP
    for (int i = 0; i < selectedItems.length; i++) {
      final item = selectedItems[i];

      double price = double.tryParse(item["SalePrice"]?.toString() ?? "0") ?? 0;

      double gstRate = double.tryParse(item["gst"]?.toString() ?? "0") ?? 0;

      int qty = item["qty"] ?? 0;

      double itemTotal = (price * qty);

      double gstAmt = (itemTotal * gstRate) / 100;

      body["ItemId[$i]"] = item["id"].toString();

      body["SalePrice[$i]"] = price.toStringAsFixed(2);

      body["Quantity[$i]"] = qty.toString();

      body["Discount[$i]"] = "0";

      body["GST[$i]"] = gstRate.toStringAsFixed(0);

      body["GSTAmt[$i]"] = gstAmt.toStringAsFixed(2);

      body["TotalAmt[$i]"] = (itemTotal + gstAmt).toStringAsFixed(2);
    }

    debugPrint("📤 SALE BODY:");
    debugPrint(body.toString());

    setState(() {
      isLoading = true;
    });
    debugPrint("════════ SALE ORDER BODY ════════");

    body.forEach((key, value) {
      debugPrint("$key : $value");
    });

    debugPrint("════════ END BODY ════════");
    final response = await ApiService.postRequest(
      endpoint: "/client/sale/store",
      body: body,
    );

    setState(() {
      isLoading = false;
    });

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? "Order Updated Successfully" : "Order Placed Successfully",
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderSuccessPage(amount: total)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? "Failed to update order" : "Failed to submit order",
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit ? "Edit Order" : "Order Now"),
          centerTitle: true,
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  /// ITEM SEARCH
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: TextField(
                        controller: itemController,
                        onChanged: (_) => filterItems(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "Item Name",
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),

                          prefixIcon: Icon(
                            Icons.search,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),

                          filled: true,
                          fillColor: Colors.white,

                          isDense: true,

                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.2,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// CATEGORY SEARCH
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: TextField(
                        controller: categoryController,
                        onChanged: (_) => filterItems(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "Category Name",
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),

                          prefixIcon: Icon(
                            Icons.category_outlined,
                            size: 18,
                            color: Colors.grey.shade700,
                          ),

                          filled: true,
                          fillColor: Colors.white,

                          isDense: true,

                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 11,
                          ),

                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.2,
                            ),
                          ),

                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Theme.of(context).primaryColor,
                              width: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 🔹 PRODUCT GRID
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredProducts.isEmpty
                  ? const Center(child: Text("No Items Found"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: filteredProducts.length,
                      itemBuilder: (_, i) {
                        final item = filteredProducts[i];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // 🔹 LEFT SIDE (More Details)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// 🔥 NAME + CATEGORY
                                  RichText(
                                    text: TextSpan(
                                      text: item["Name"] ?? "",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.black,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: item["Category"] != null
                                              ? " (${item["Category"]})"
                                              : "",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 7),

                                  /// 🔥 PRICE | STOCK | GST
                                  Row(
                                    children: [
                                      Text(
                                        "₹${item["SalePrice"] ?? "0"}   |  ",
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),

                                      Text(
                                        "Stock: ${item["Stock"] ?? "0"}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,

                                          /// 🔥 STOCK COLOR
                                          color:
                                              (int.tryParse(
                                                        item["Stock"]
                                                                ?.toString() ??
                                                            "0",
                                                      ) ??
                                                      0) >
                                                  0
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                      Text(
                                        "   |   GST: ${(double.tryParse(item["gst"]?.toString() ?? "0") ?? 0).toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          fontSize: 12,

                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(
                                height: 32,
                                width: 90,
                                child: item["qty"] == 0
                                    ? ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onPressed: () => increaseQty(i),
                                        child: const Text(
                                          "Add",
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      )
                                    : Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.blue,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            GestureDetector(
                                              onTap: () => decreaseQty(i),
                                              child: const Icon(
                                                Icons.remove,
                                                size: 16,
                                              ),
                                            ),
                                            Text(
                                              "${item["qty"]}",
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => increaseQty(i),
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // 🔹 SUMMARY CARD
            Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [BoxShadow(color: Colors.black12)],
              ),
              child: Column(
                children: [
                  _row("Subtotal", subtotal),
                  _row("GST", gst),
                  _row("Total", total, bold: true),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        submitOrder(
                          isEdit: widget.isEdit,
                          saleId: widget.saleId,
                        );
                      },
                      child: Text(
                        widget.isEdit ? "Update Order" : "Submit Order",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String title, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "₹${value.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// 🔹 SUCCESS PAGE
class OrderSuccessPage extends StatelessWidget {
  final double amount;

  const OrderSuccessPage({super.key, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Placed"), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 10),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25),

              child: Text(
                "Your order has been placed successfully and is currently pending admin approval.",

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
            Text("₹${amount.toStringAsFixed(2)}"),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),

                borderRadius: BorderRadius.circular(20),
              ),

              child: const Text(
                "Status : Pending Approval",

                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: 190,
              height: 42,

              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const OrderHistoryPage()),

                    (route) => route.isFirst,
                  );
                },

                icon: const Icon(Icons.history, size: 18),

                label: const Text("View Order History"),

                style: ElevatedButton.styleFrom(
                  elevation: 0,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
