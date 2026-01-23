import 'package:flutter/material.dart';

class TransactionSettingsPage extends StatefulWidget {
  const TransactionSettingsPage({super.key});

  @override
  State<TransactionSettingsPage> createState() =>
      _TransactionSettingsPageState();
}

class _TransactionSettingsPageState extends State<TransactionSettingsPage> {
  // Toggle states
  bool invoiceNumber = true;
  bool cashSale = false;
  bool billingName = false;
  bool poDetails = false;
  bool addTime = false;

  bool inclusiveTax = true;
  bool displayPurchasePrice = true;
  bool freeItemQty = false;
  bool count = false;
  bool barcodeScanning = false;

  bool transTax = false;
  bool _isSearching = false;
  String _searchText = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (value) {
                  setState(() {
                    _searchText = value.toLowerCase();
                  });
                },
                decoration: const InputDecoration(
                  hintText: "Search settings...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
              )
            : const Text(
                'Transaction Setting',
                style: TextStyle(color: Colors.white),
              ),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchText = "";
                  _searchController.clear();
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // --- Transaction Header ---
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              "Transaction Header",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          buildTileContainer([
            if (_shouldShow("Invoice/Bill Number"))
              buildSwitchTile(
                "Invoice/Bill Number",
                invoiceNumber,
                (val) => setState(() => invoiceNumber = val),
              ),
            if (_shouldShow("Cash Sale by default"))
              buildSwitchTile(
                "Cash Sale by default",
                cashSale,
                (val) => setState(() => cashSale = val),
              ),
            if (_shouldShow("Billing name of Parties"))
              buildSwitchTile(
                "Billing name of Parties",
                billingName,
                (val) => setState(() => billingName = val),
              ),
            if (_shouldShow("PO Details (of customer)"))
              buildSwitchTile(
                "PO Details (of customer)",
                poDetails,
                (val) => setState(() => poDetails = val),
              ),
            if (_shouldShow("Add Time On Transactions"))
              buildSwitchTile(
                "Add Time On Transactions",
                addTime,
                (val) => setState(() => addTime = val),
              ),
          ]),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              "Items table",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          buildTileContainer([
            if (_shouldShow(
              "Allow Inclusive/Exclusive tax on Rate (Price/unit)",
            ))
              buildSwitchTile(
                "Allow Inclusive/Exclusive tax on Rate (Price/unit)",
                inclusiveTax,
                (val) => setState(() => inclusiveTax = val),
              ),
            if (_shouldShow("Display Purchase Price"))
              buildSwitchTile(
                "Display Purchase Price",
                displayPurchasePrice,
                (val) => setState(() => displayPurchasePrice = val),
              ),
            if (_shouldShow("Free Item quantity"))
              buildSwitchTile(
                "Free Item quantity",
                freeItemQty,
                (val) => setState(() => freeItemQty = val),
              ),
            if (_shouldShow("Count"))
              buildSwitchTile(
                "Count",
                count,
                (val) => setState(() => count = val),
                icon: Icons.edit,
              ),
            if (_shouldShow("Barcode scanning for items"))
              buildSwitchTile(
                "Barcode scanning for items",
                barcodeScanning,
                (val) => setState(() => barcodeScanning = val),
              ),
          ]),

          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.only(left: 12.0),
            child: Text(
              "Taxes, Discount & Total",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          buildTileContainer([
            if (_shouldShow("Transaction wise Tax"))
              buildSwitchTile(
                "Transaction wise Tax",
                transTax,
                (val) => setState(() => transTax = val),
              ),
            if (_shouldShow("Display Purchase Price"))
              buildSwitchTile(
                "Display Purchase Price",
                displayPurchasePrice,
                (val) => setState(() => displayPurchasePrice = val),
              ),
            if (_shouldShow("Free Item quantity"))
              buildSwitchTile(
                "Free Item quantity",
                freeItemQty,
                (val) => setState(() => freeItemQty = val),
              ),
            if (_shouldShow("Count"))
              buildSwitchTile(
                "Count",
                count,
                (val) => setState(() => count = val),
                icon: Icons.edit,
              ),
            if (_shouldShow("Barcode scanning for items"))
              buildSwitchTile(
                "Barcode scanning for items",
                barcodeScanning,
                (val) => setState(() => barcodeScanning = val),
              ),
          ]),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Helper: returns true if tile title matches search or no search
  bool _shouldShow(String title) {
    return _searchText.isEmpty || title.toLowerCase().contains(_searchText);
  }

  // Helper: Wrap list of switch tiles into container
  Widget buildTileContainer(List<Widget> children) {
    // Don't render empty groups during search
    if (children.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // Helper: Build single switch tile
  Widget buildSwitchTile(
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    IconData? icon,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Row(
        children: [
          Expanded(child: Text(title)),
          Tooltip(
            message: "Info about $title",
            child: const Icon(Icons.info_outline, size: 18),
          ),
          if (icon != null) ...[const SizedBox(width: 5), Icon(icon, size: 18)],
        ],
      ),
    );
  }
}
