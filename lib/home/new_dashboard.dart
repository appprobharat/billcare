import 'dart:convert';

import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/admin/clients/details.dart';
import 'package:billcare/admin/employee/details.dart';
import 'package:billcare/admin/graphs/income_expense_graph.dart';
import 'package:billcare/home/leftsidebar.dart';
import 'package:billcare/admin/income_expense/category_list.dart';
import 'package:billcare/admin/income_expense/income_list.dart';
import 'package:billcare/admin/items/itemspage.dart';
import 'package:billcare/admin/payment/manage.dart';
import 'package:billcare/admin/purchase/manage.dart';
import 'package:billcare/admin/quick_receipt/manage.dart';
import 'package:billcare/admin/receipt/manage.dart';
import 'package:billcare/admin/report/due_report.dart';
import 'package:billcare/admin/report/item_stock.dart';
import 'package:billcare/admin/report/ledger/ledger.dart';
import 'package:billcare/admin/report/low_stock.dart';
import 'package:billcare/admin/sale/manage.dart';
import 'package:billcare/admin/graphs/sales_graph.dart';
import 'package:billcare/transaction/transaction.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int currentIndex = 0;
  String companyName = "";
  List<Map<String, dynamic>> companyList = [];
  List<Map<String, dynamic>> sessionList = [];
  List<Map<String, dynamic>> savedData = [];
  Map<String, dynamic>? selectedCompany;
  Map<String, dynamic>? selectedSession;
  Map<String, dynamic>? dashboardData;

  bool graphLoading = true;

  String userName = "vishal";
  String userPhotoUrl = "";

  @override
  void initState() {
    super.initState();
    _safeAuthCheck();
    _loadSavedData();
    _loadCompanyName();
    fetchDashboardData();
    _syncFcmToken();
    loadCompanies();
    loadSessions();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      graphLoading = true;
    });

    final response = await ApiService.postRequest(endpoint: "/dashboard");

    if (response != null && response["status"] == true) {
      setState(() {
        dashboardData = response["data"];

        graphLoading = false;
      });
    } else {
      setState(() {
        graphLoading = false;
      });
    }
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

  Future<void> _syncFcmToken() async {
    await Future.delayed(const Duration(seconds: 1));
    final fcmToken = await FirebaseMessaging.instance.getToken();
    debugPrint("FCM TOKEN: $fcmToken");
    if (fcmToken != null && fcmToken.isNotEmpty) {
      await ApiService.saveToken(fcmToken);
    }
  }

  Future<void> loadCompanies() async {
    final res = await ApiService.postRequest(endpoint: "/get_company");

    if (res != null) {
      companyList = List<Map<String, dynamic>>.from(res);

      selectedCompany = companyList.firstWhere(
        (e) => e['is_default'] == 1,
        orElse: () => companyList.first,
      );

      setState(() {});
    }
  }

  Future<void> loadSessions() async {
    final res = await ApiService.postRequest(endpoint: "/get_session");

    if (res != null) {
      sessionList = List<Map<String, dynamic>>.from(res);

      selectedSession = sessionList.firstWhere(
        (e) => e['is_default'] == 1,
        orElse: () => sessionList.first,
      );

      setState(() {});
    }
  }

  Future<void> setCompany(int companyId) async {
    final res = await ApiService.postRequest(
      endpoint: "/set_company",
      body: {"CompanyId": companyId.toString()},
    );

    if (res != null && res['status'] == true) {
      String newToken = res['token'];

      await AuthStorage.saveToken(newToken);

      /// 🔥 INSTANT UI UPDATE
      final company = companyList.firstWhere((e) => e['id'] == companyId);

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('companyName', company['Name'].toString());

      if (!mounted) return;

      setState(() {
        selectedCompany = company;
        companyName = company['Name'].toString();
      });

      await loadCompanies();

      print("✅ Company Changed");
    }
  }

  Future<void> setSession(int sessionId) async {
    final res = await ApiService.postRequest(
      endpoint: "/set_session",
      body: {"SessionId": sessionId.toString()},
    );

    if (res != null && res['status'] == true) {
      String newToken = res['token'];

      await AuthStorage.saveToken(newToken);

      await loadSessions();

      setState(() {});
    }
  }

  Future<void> _safeAuthCheck() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final token = await AuthStorage.getToken();
    debugPrint("DASHBOARD TOKEN: $token");
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, "/login");
    }
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

            name: userName,
            photo: userPhotoUrl,
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),

        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),

        title: Row(
          children: [
            // 🔹 COMPANY DROPDOWN (LEFT)
            PopupMenuButton<Map<String, dynamic>>(
              onSelected: (value) {
                setCompany(value['id']);
              },
              itemBuilder: (context) {
                return companyList.map((company) {
                  return PopupMenuItem(
                    value: company,
                    child: Text(company['Name']),
                  );
                }).toList();
              },

              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),

            const Spacer(),

            // 🔹 SESSION DROPDOWN (RIGHT)
            PopupMenuButton<Map<String, dynamic>>(
              onSelected: (value) {
                setSession(value['id']);
              },
              itemBuilder: (context) {
                return sessionList.map((session) {
                  return PopupMenuItem(
                    value: session,
                    child: Text(session['Name']),
                  );
                }).toList();
              },

              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      selectedSession?['Name'] ?? "Loading...",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey.shade100,

      /// 🔻 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });

          switch (index) {
            case 0:
              break;

            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SalesManagePage()),
              );
              break;

            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PurchaseManagePage()),
              );
              break;

            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ManageClientPage()),
              );
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: "Sale",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: "Purchase",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profile",
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              /// 🔹 TITLE
              const Padding(
                padding: EdgeInsets.all(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Quick Links",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              /// 🔹 GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    quickCard(Icons.people_alt, "Client", Colors.purple, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ManageClientPage()),
                      );
                    }),

                    quickCard(Icons.person, "Employee", Colors.green, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ManageEmployeePage()),
                      );
                    }),

                    quickCard(Icons.inventory_2, "Items", Colors.teal, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ItemScreen()),
                      );
                    }),
                    quickCard(Icons.shopping_cart, "Sale", Colors.indigo, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalesManagePage()),
                      );
                    }),

                    quickCard(
                      Icons.shopping_cart_checkout,
                      "Purchase",
                      Colors.pink,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PurchaseManagePage(),
                          ),
                        );
                      },
                    ),

                    quickCard(Icons.payments, "Payment", Colors.red, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ManagePaymentPage()),
                      );
                    }),

                    quickCard(Icons.receipt_long, "Receipt", Colors.amber, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ManageReceiptPage()),
                      );
                    }),
                    quickCard(Icons.book, "Ledger", Colors.blueGrey, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LedgerPage()),
                      );
                    }),
                    quickCard(
                      Icons.inventory_2,
                      "Item-Report",
                      Colors.lightGreen,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemStockReportPage(),
                          ),
                        );
                      },
                    ),
                    quickCard(
                      Icons.swap_horiz,
                      "Transaction",
                      Colors.redAccent,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => TransactionPage()),
                        );
                      },
                    ),
                    quickCard(
                      Icons.schedule,
                      "Due Reports",
                      Colors.deepOrange,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ReportDuePage()),
                        );
                      },
                    ),

                    quickCard(
                      Icons.account_balance_wallet,
                      "Inc/Exp",
                      Colors.orange,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => IncomeListPage()),
                        );
                      },
                    ),
                    quickCard(
                      Icons.badge,
                      "Quick Receipt",
                      Colors.deepPurple,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManageQuickReceiptPage(),
                          ),
                        );
                      },
                    ),
                    quickCard(
                      Icons.warning_amber_rounded,
                      "Low Stock",
                      Colors.red,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LowStockPage()),
                        );
                      },
                    ),
                    quickCard(
                      Icons.balance,
                      "Balance-Sheet",
                      Colors.purple,
                      () {
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (_) => ),
                        // );
                      },
                    ),
                    quickCard(Icons.category, "Category", Colors.green, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CategoryListPage()),
                      );
                    }),
                  ],
                ),
              ),
              graphLoading
                  ? const Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(),
                    )
                  : Column(
                      children: [
                        /// 🔥 SALES PURCHASE GRAPH
                        Padding(
                          padding: const EdgeInsets.all(12),

                          child: SalesPurchaseChart(
                            months: List<String>.from(
                              dashboardData?["months"] ?? [],
                            ),

                            salesData: List<double>.from(
                              (dashboardData?["SaleActivity"] ?? []).map(
                                (e) => (e as num).toDouble(),
                              ),
                            ),

                            purchaseData: List<double>.from(
                              (dashboardData?["PurchaseActivity"] ?? []).map(
                                (e) => (e as num).toDouble(),
                              ),
                            ),
                          ),
                        ),

                        /// 🔥 INCOME EXPENSE GRAPH
                        Padding(
                          padding: const EdgeInsets.all(8),

                          child: IncomeExpenseChart(
                            months: List<String>.from(
                              dashboardData?["months"] ?? [],
                            ),

                            incomeData: List<double>.from(
                              (dashboardData?["Income"] ?? []).map(
                                (e) => (e as num).toDouble(),
                              ),
                            ),

                            expenseData: List<double>.from(
                              (dashboardData?["Expense"] ?? []).map(
                                (e) => (e as num).toDouble(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔹 QUICK CARD WIDGET
  Widget quickCard(
    IconData icon,
    String text,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.22), color.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(icon, color: color, size: 20),
              ),

              const SizedBox(height: 2),
              Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
