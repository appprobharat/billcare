import 'dart:convert';
import 'package:billcare/clients/add.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:billcare/expenses/addtxnpage.dart';
import 'package:billcare/sale/add.dart';
import 'package:billcare/sale/report.dart';
import 'package:billcare/home/leftsidebar.dart';
import 'package:billcare/home/moreoptionsheet.dart';
import 'package:billcare/home/transactionsettingpage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool showPartyDetails = false;
  // bool isSidebarOpen = false;
 
  List<Map<String, dynamic>> savedData = [];
  String companyName = "Enter Company";
  String userName = "vishal";
  String userPhotoUrl = "";
  // void toggleSidebar() {
  //   setState(() {
  //     isSidebarOpen = !isSidebarOpen;
  //   });
  // }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AuthGuard.ensureLoggedIn(context);
    });

    _loadSavedData();
    _loadCompanyName();
  }

  Future<void> _loadCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('companyName') ?? "Enter Company";
    final name = prefs.getString("userName") ?? "User";
    final photo = prefs.getString("userPhotoUrl") ?? "";

    if (!mounted) return;
    setState(() {
      companyName = savedName;
      userName = name;
      userPhotoUrl = photo;
    });
  }

  Future<void> printInvoice(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  "BillCare Invoice",
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Divider(),

                pw.SizedBox(height: 10),

                // Customer Details
                pw.Text("Customer Name: ${data['partyName']}"),
                pw.Text("Phone: ${data['phone']}"),
                pw.Text("Date: ${data['selectedDate']}"),

                pw.SizedBox(height: 20),

                // Payment Details
                pw.Text(
                  "Total Amount: ₹${data['totalAmount']}",
                  style: pw.TextStyle(fontSize: 16),
                ),
                pw.Text("Received: ₹${data['received']}"),
                pw.Text(
                  "Payment Status: ${data['isReceived'] ? '✅ Received' : '❌ Pending'}",
                ),

                pw.Spacer(),

                pw.Center(
                  child: pw.Text(
                    "Thank you for your business!",
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    final List<String>? jsonList = prefs.getStringList('salesData');

    if (!mounted) return;

if (jsonList != null) {
  setState(() {
    savedData = jsonList.map((e) {
      return json.decode(e) as Map<String, dynamic>;
    }).toList();
  });
} else {
  setState(() {
    savedData = [];
  });
}

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      key: _scaffoldKey,
      drawer: SizedBox(
        width: 220,
        child: Drawer(
          child: LeftSidebar(
            companyName: companyName,
            // email: "info@techinnovationapp.in",
            name: userName,
            photo: userPhotoUrl,
          ),
        ),
      ),

      appBar: AppBar(
        elevation: 0,
        titleSpacing: 2.0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          companyName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // Toggle Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Transaction Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showPartyDetails = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Color(0xFF1E3A8A)),
                        color: showPartyDetails
                            ? Colors.white
                            : Color(0xFF1E3A8A),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Transaction Details',
                        style: TextStyle(
                          color: showPartyDetails ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Party Tab
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        showPartyDetails = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.red),
                        color: showPartyDetails ? Colors.red : Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Party Details',
                        style: TextStyle(
                          color: showPartyDetails ? Colors.white : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // MID CONTENT
          Expanded(
            child: showPartyDetails
                ? _buildPartyContent()
                : _buildTransactionContent(),
          ),
        ],
      ),
      bottomNavigationBar: SizedBox(
        height: 120,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: GestureDetector(
              onTap: () => {
                if (showPartyDetails)
                  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddClientPage()),
                    ).then((_) {
                      print(
                        "🔁 Returned from AddNewPartyPage. Reloading data...",
                      );
                      _loadSavedData();
                    }),
                  }
                else
                  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AddNewSalePage()),
                    ).then((_) {
                      print(
                        "🔁 Returned from AddNewSalePage. Reloading data...",
                      );
                      _loadSavedData();
                    }),
                  },
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, size: 20, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      (showPartyDetails ? "Add New Party" : "Add New Sale"),
                      style: const TextStyle(
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
    );
  }

  // Full Transaction Content Widget
  Widget _buildTransactionContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        _buildQuickLinks([
          _QuickLink(
            icon: Icons.note_add,
            label: 'Add Txn',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddTxnPage()),
              );
            },
          ),
          _QuickLink(
            icon: Icons.bar_chart,
            label: 'Sale Report',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SaleReportPage()),
              );
            },
          ),
          _QuickLink(
            icon: Icons.settings,
            label: 'Txn Settings',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TransactionSettingsPage()),
              );
            },
          ),
          _QuickLink(
            icon: Icons.arrow_forward_ios,
            label: 'Show All',
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => const MoreOptionsSheet(),
              );
            },
          ),
        ]),
        const SizedBox(height: 12),
        _buildTransactionCards(),
      ],
    );
  }

  Widget _buildPartyContent() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        _buildQuickLinks([
          _QuickLink(icon: Icons.wifi, label: 'Network'),
          _QuickLink(icon: Icons.receipt_long, label: 'Party State...'),
          _QuickLink(icon: Icons.settings, label: 'Party Settings'),
          _QuickLink(
            icon: Icons.arrow_forward_ios,
            label: 'Show All',
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => const MoreOptionsSheet(),
              );
            },
          ),
        ]),
        const SizedBox(height: 12),

        // ⬇️ Show ALL saved data in Cards
        ...savedData.map((item) {
          final partyName = item['partyName'] ?? 'N/A';
          final dateStr = item['selectedDate'] ?? '';
          final totalAmount = item['totalAmount'] ?? '0';
          final isReceived = item['isReceived'] == true;

          return Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(partyName),
              subtitle: Text(dateStr ?? 'N/A'),

              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹ $totalAmount",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    isReceived ? "Received" : "You'll Get",
                    style: const TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildQuickLinks(List<_QuickLink> links) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: links,
        ),
      ),
    );
  }

  Widget _buildTransactionCards() {
    if (savedData.isEmpty) {
      return const Center(child: Text("No transactions found."));
    }

    return Column(
      children: savedData.asMap().entries.map((entry) {
        int index = entry.key;
        Map<String, dynamic> transaction = entry.value;

        final partyName = transaction['partyName'] ?? 'N/A';
        final date = transaction['selectedDate'] ?? '';
        final totalAmount = transaction['totalAmount'] ?? '0';
        final receivedAmount = transaction['received'] ?? '0';

        double total = double.tryParse(totalAmount) ?? 0;
        double received = double.tryParse(receivedAmount) ?? 0;
        double balance = total - received;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      partyName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("#${index + 1}"),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "SALE",
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                    const Spacer(),
                    Text(date),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total\n₹ $totalAmount"),
                    Text("Balance\n₹ ${balance.toStringAsFixed(2)}"),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            printInvoice(transaction);
                          },
                          child: const Icon(Icons.print, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () {},
                          child: const Icon(Icons.share, color: Colors.grey),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  // final Color color;
  final VoidCallback? onTap;

  const _QuickLink({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        children: [
          CircleAvatar(child: Icon(icon)),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
