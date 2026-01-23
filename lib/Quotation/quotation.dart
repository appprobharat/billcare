import 'package:billcare/Quotation/add.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuotationPage extends StatefulWidget {
  const QuotationPage({super.key});

  @override
  State<QuotationPage> createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage> {
  final List<Map<String, dynamic>> _allQuotations = [
    {
      "invoiceNo": "INV001",
      "date": "2024-05-20",
      "clientName": "ABC Corp",
      "contactNo": "9876543210",
      "noOfItems": 5,
      "total": 1200.0,
      "items": [],
    },
    {
      "invoiceNo": "INV002",
      "date": "2024-05-21",
      "clientName": "XYZ Ltd",
      "contactNo": "9123456780",
      "noOfItems": 3,
      "total": 800.0,
      "items": [],
    },
    {
      "invoiceNo": "INV003",
      "date": "2024-06-10",
      "clientName": "ABC Corp",
      "contactNo": "9876543210",
      "noOfItems": 1,
      "total": 500.0,
      "items": [],
    },
  ];
  List<Map<String, dynamic>> _filteredQuotations = [];

  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 1. Default to 1 month ago (Format Changed: 'dd-MM-yy')
    _fromDateController.text = DateFormat(
      'dd-MM-yy', // 👈 CHANGED
    ).format(DateTime.now().subtract(const Duration(days: 30)));
    _toDateController.text = DateFormat(
      'dd-MM-yy',
    ).format(DateTime.now()); // 👈 CHANGED

    _filteredQuotations = _allQuotations;
    // 1. Filter immediately to show 1 month data
    WidgetsBinding.instance.addPostFrameCallback((_) => _filterQuotations());
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addNewQuotation(Map<String, dynamic> newQuotation) {
    setState(() {
      _allQuotations.add(newQuotation);
      _filterQuotations();
    });
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      // Format Changed: 'dd-MM-yy'
      controller.text = DateFormat('dd-MM-yy').format(picked); // 👈 CHANGED
    }
  }

  void _filterQuotations() {
    final DateTime? fromDate = _fromDateController.text.isNotEmpty
        // Format Changed: 'dd-MM-yy'
        ? DateFormat('dd-MM-yy').parse(_fromDateController.text) // 👈 CHANGED
        : null;
    final DateTime? toDate = _toDateController.text.isNotEmpty
        // Format Changed: 'dd-MM-yy'
        ? DateFormat('dd-MM-yy').parse(_toDateController.text) // 👈 CHANGED
        : null;
    final String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredQuotations = _allQuotations.where((q) {
        final DateTime qDate = DateTime.parse(q["date"]);
        final bool isDateInRange =
            (fromDate == null ||
                qDate.isAfter(fromDate.subtract(const Duration(days: 1)))) &&
            (toDate == null ||
                qDate.isBefore(toDate.add(const Duration(days: 1))));

        final bool isQueryMatch =
            q['clientName'].toLowerCase().contains(query) ||
            q['invoiceNo'].toLowerCase().contains(query) ||
            q['contactNo'].contains(query); // Added contact search

        return isDateInRange && isQueryMatch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text("Quotations"),
        foregroundColor: Colors.white,
      ),
      // Reduced overall padding
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
        child: Column(
          children: [
            // 2 & 3. Date Range Fields and Search Button in one compact row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // From Date - SMALLER
                Expanded(
                  flex: 4, // 👈 CHANGED: Reduced from 5 to 4
                  child: TextFormField(
                    readOnly: true,
                    controller: _fromDateController,
                    decoration: const InputDecoration(
                      // labelText: "From Date", // 👈 REMOVED label
                      hintText: "From", // 👈 ADDED smaller hint
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      suffixIcon: Icon(Icons.calendar_today, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ), // Small
                    ),
                    onTap: () => _selectDate(context, _fromDateController).then(
                      (_) => _filterQuotations(),
                    ), // Search after selection
                  ),
                ),
                const SizedBox(width: 8),

                // To Date - SMALLER
                Expanded(
                  flex: 4, // 👈 CHANGED: Reduced from 5 to 4
                  child: TextFormField(
                    readOnly: true,
                    controller: _toDateController,
                    decoration: const InputDecoration(
                      // labelText: "To Date", // 👈 REMOVED label
                      hintText: "To", // 👈 ADDED smaller hint
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      suffixIcon: Icon(Icons.calendar_today, size: 20),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 10,
                      ), // Small
                    ),
                    onTap: () => _selectDate(context, _toDateController).then(
                      (_) => _filterQuotations(),
                    ), // Search after selection
                  ),
                ),
                const SizedBox(width: 6),

                // Search Button (Small and Square)
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _filterQuotations,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(
                      Icons.search,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 4 & 5. Simple Search/Filter Field (Client Style)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by Client Name or Invoice No.",
                  prefixIcon: const Icon(Icons.search, size: 20),
                  // Clear Button functionality
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _filterQuotations();
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 10.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
                onChanged: (value) => _filterQuotations(), // Instant filtering
              ),
            ),
            const SizedBox(height: 10),

            // 6. Quotation List (Grid View - 2 per Row)
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero, // Remove grid padding
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 items per row
                  crossAxisSpacing: 8.0, // Horizontal space
                  mainAxisSpacing: 8.0, // Vertical space
                  childAspectRatio: 1.5, // Item aspect ratio (width/height)
                ),
                itemCount: _filteredQuotations.length,
                itemBuilder: (context, index) {
                  final q = _filteredQuotations[index];

                  return Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Client Name (Bold and Small)
                          Text(
                            q['clientName'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Invoice and Date
                          Text(
                            "Inv: ${q['invoiceNo']}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            "Date: ${q['date']}",
                            style: const TextStyle(fontSize: 12),
                          ),

                          const Spacer(), // Pushes amount to the bottom
                          // Total Amount (Aligned Right and Green)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              "₹${q['total'].toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GestureDetector(
              onTap: () async {
                final newQuotation = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddQuotationPage()),
                );
                if (newQuotation != null) {
                  _addNewQuotation(newQuotation);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15.0,
                  vertical: 7.0,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFF1E3A8A),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'Add Quotation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      // // 5. Add Quotation Button (Center)
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // floatingActionButton: FloatingActionButton.extended(
      //   extendedPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      //   onPressed:
      //   label: const Text("Add Quotation"),
      //   icon: const Icon(Icons.add),
      //   foregroundColor: Colors.white,
      // ),
    );
  }
}
