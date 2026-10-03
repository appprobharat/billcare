import 'dart:convert';
import 'package:billcare/admin/report/ledger.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/admin/clients/details.dart';
import 'package:billcare/admin/employee/details.dart';
import 'package:billcare/admin/graphs/income_expense_graph.dart';
import 'package:billcare/admin/home/dashboard_insights.dart';
import 'package:billcare/admin/home/leftsidebar.dart';
import 'package:billcare/admin/income_expense/category_list.dart';
import 'package:billcare/admin/income_expense/income_list.dart';
import 'package:billcare/admin/items/itemspage.dart';
import 'package:billcare/admin/payment/manage.dart';
import 'package:billcare/admin/purchase/manage.dart';
import 'package:billcare/admin/quick_receipt/manage.dart';
import 'package:billcare/admin/receipt/manage.dart';
import 'package:billcare/admin/report/due_report.dart';
import 'package:billcare/admin/report/item_stock.dart';
import 'package:billcare/admin/report/low_stock.dart';
import 'package:billcare/admin/sale/manage.dart';
import 'package:billcare/admin/graphs/sales_graph.dart';
import 'package:billcare/admin/report/transaction.dart';
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
  final GlobalKey<SalesManagePageState> salesPageKey =
      GlobalKey<SalesManagePageState>();

  final GlobalKey<PurchaseManagePageState> purchasePageKey =
      GlobalKey<PurchaseManagePageState>();

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
    _syncFcmToken();

    _initializeCompanySession();
  }

  Future<void> _initializeCompanySession() async {
    try {
      if (!mounted) return;

      setState(() {
        graphLoading = true;
      });

      // 1. Companies load
      final companyRes = await ApiService.postRequest(endpoint: "/get_company");

      if (companyRes == null) {
        debugPrint("❌ Company API failed");
        return;
      }

      final companies = List<Map<String, dynamic>>.from(companyRes);

      if (companies.isEmpty) {
        debugPrint("❌ No company found");
        return;
      }

      companyList = companies;

      // 2. Default company select
      final defaultCompany = companyList.firstWhere(
        (e) => e['is_default'].toString() == '1',
        orElse: () => companyList.first,
      );

      selectedCompany = defaultCompany;
      companyName = defaultCompany['Name'].toString();

      if (mounted) {
        setState(() {});
      }

      debugPrint("🏢 Default Company: ${selectedCompany?['Name']}");

      // 3. Company ke sessions load
      await loadSessions();

      // 4. Ab current company + session ke according dashboard
      await fetchDashboardData();

      debugPrint("✅ Initial Company + Session loaded");
    } catch (e) {
      debugPrint("❌ _initializeCompanySession ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          graphLoading = false;
        });
      }
    }
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      graphLoading = true;
    });

    final response = await ApiService.postRequest(endpoint: "/dashboard");
    debugPrint("========== DASHBOARD RESPONSE ==========");
    debugPrint("$response");
    debugPrint("========================================");
    if (!mounted) return;
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

  // Future<void> loadCompanies() async {
  //   final res = await ApiService.postRequest(endpoint: "/get_company");

  //   if (res != null) {
  //     companyList = List<Map<String, dynamic>>.from(res);

  //     selectedCompany = companyList.firstWhere(
  //       (e) => e['is_default'] == 1,
  //       orElse: () => companyList.first,
  //     );

  //     setState(() {});
  //   }
  // }

  Future<void> loadSessions({int? preferredSessionId}) async {
    try {
      final res = await ApiService.postRequest(endpoint: "/get_session");

      if (res == null) {
        debugPrint("❌ Session API failed");
        return;
      }

      sessionList = List<Map<String, dynamic>>.from(res);

      // No session
      if (sessionList.isEmpty) {
        selectedSession = null;

        if (mounted) {
          setState(() {});
        }

        debugPrint("⚠️ No session found");
        return;
      }

      // --------------------------------------------------
      // 1. Agar preferred session available hai
      // --------------------------------------------------

      if (preferredSessionId != null) {
        final matchingSession = sessionList.where(
          (e) => e['id'].toString() == preferredSessionId.toString(),
        );

        if (matchingSession.isNotEmpty) {
          selectedSession = matchingSession.first;

          debugPrint(
            "📅 Same Session selected: "
            "${selectedSession?['Name']}",
          );

          if (mounted) {
            setState(() {});
          }

          return;
        }
      }

      // --------------------------------------------------
      // 2. Otherwise default session
      // --------------------------------------------------

      final defaultSessions = sessionList.where(
        (e) => e['is_default'].toString() == '1',
      );

      selectedSession = defaultSessions.isNotEmpty
          ? defaultSessions.first
          : sessionList.first;

      debugPrint("📅 Default Session: ${selectedSession?['Name']}");

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("❌ loadSessions ERROR: $e");
    }
  }

  Future<void> refreshAllData() async {
    if (!mounted) return;

    setState(() {
      graphLoading = true;
    });

    await fetchDashboardData();

    await salesPageKey.currentState?.refreshList();

    await purchasePageKey.currentState?.refreshList();

    if (!mounted) return;

    setState(() {
      graphLoading = false;
    });
  }

  Future<void> setSession(int sessionId) async {
    try {
      if (!mounted) return;

      setState(() {
        graphLoading = true;
      });

      final res = await ApiService.postRequest(
        endpoint: "/set_session",
        body: {"SessionId": sessionId.toString()},
      );

      if (res != null && res['status'] == true) {
        // New session token
        await AuthStorage.saveToken(res['token'].toString());

        // Selected session update
        final session = sessionList.firstWhere(
          (e) => e['id'].toString() == sessionId.toString(),
          orElse: () => <String, dynamic>{},
        );

        if (session.isNotEmpty && mounted) {
          setState(() {
            selectedSession = session;
          });
        }

        // New Session data
        await refreshAllData();

        debugPrint("=================================");
        debugPrint("✅ SESSION CHANGED");
        debugPrint("🏢 Company: ${selectedCompany?['Name']}");
        debugPrint("📅 Session: ${selectedSession?['Name']}");
        debugPrint("=================================");
      } else {
        debugPrint("❌ Session change failed");
      }
    } catch (e) {
      debugPrint("❌ setSession ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          graphLoading = false;
        });
      }
    }
  }

  Future<void> setCompany(int companyId) async {
    try {
      if (!mounted) return;

      setState(() {
        graphLoading = true;
      });

      // --------------------------------------------------
      // CURRENT SESSION SAVE
      // --------------------------------------------------

      final int? currentSessionId = selectedSession?['id'] == null
          ? null
          : int.tryParse(selectedSession!['id'].toString());

      debugPrint("🔄 Changing Company...");

      debugPrint("📅 Current Session ID: $currentSessionId");

      // --------------------------------------------------
      // 1. CHANGE COMPANY
      // --------------------------------------------------

      final companyRes = await ApiService.postRequest(
        endpoint: "/set_company",
        body: {"CompanyId": companyId.toString()},
      );

      if (companyRes == null || companyRes['status'] != true) {
        debugPrint("❌ Company change failed");
        return;
      }

      // --------------------------------------------------
      // 2. SAVE COMPANY TOKEN
      // --------------------------------------------------

      final companyToken = companyRes['token']?.toString();

      if (companyToken != null && companyToken.isNotEmpty) {
        await AuthStorage.saveToken(companyToken);
      }

      // --------------------------------------------------
      // 3. FIND SELECTED COMPANY
      // --------------------------------------------------

      final company = companyList.firstWhere(
        (e) => e['id'].toString() == companyId.toString(),
        orElse: () => <String, dynamic>{},
      );

      if (company.isEmpty) {
        debugPrint("❌ Company not found");
        return;
      }

      selectedCompany = company;
      companyName = company['Name'].toString();

      // Save company name
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('companyName', companyName);

      if (mounted) {
        setState(() {});
      }

      debugPrint("🏢 Company changed: $companyName");

      // --------------------------------------------------
      // 4. LOAD NEW COMPANY SESSIONS
      // --------------------------------------------------

      await loadSessions(preferredSessionId: currentSessionId);

      // --------------------------------------------------
      // 5. CHECK WHICH SESSION IS SELECTED
      // --------------------------------------------------

      if (selectedSession == null) {
        debugPrint("⚠️ No session available for new company");

        return;
      }

      debugPrint(
        "📅 Selected Session: "
        "${selectedSession?['Name']}",
      );

      // --------------------------------------------------
      // 6. APPLY SESSION TO NEW COMPANY
      // --------------------------------------------------

      final sessionRes = await ApiService.postRequest(
        endpoint: "/set_session",
        body: {"SessionId": selectedSession!['id'].toString()},
      );

      if (sessionRes == null || sessionRes['status'] != true) {
        debugPrint("❌ Session apply failed after company change");

        return;
      }

      // --------------------------------------------------
      // 7. SAVE FINAL COMPANY + SESSION TOKEN
      // --------------------------------------------------

      final finalToken = sessionRes['token']?.toString();

      if (finalToken != null && finalToken.isNotEmpty) {
        await AuthStorage.saveToken(finalToken);
      }

      // --------------------------------------------------
      // 8. REFRESH ALL DATA
      // --------------------------------------------------

      await refreshAllData();

      debugPrint("=================================");
      debugPrint("✅ COMPANY CHANGED SUCCESSFULLY");
      debugPrint("🏢 Company: $companyName");
      debugPrint("📅 Session: ${selectedSession?['Name']}");
      debugPrint("=================================");
    } catch (e) {
      debugPrint("❌ setCompany ERROR: $e");
    } finally {
      if (mounted) {
        setState(() {
          graphLoading = false;
        });
      }
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
      appBar: currentIndex == 0
          ? AppBar(
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
                  PopupMenuButton<Map<String, dynamic>>(
                    onSelected: (value) async {
                      await setCompany(int.parse(value['id'].toString()));
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
                    onSelected: (value) async {
                      await setSession(int.parse(value['id'].toString()));
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
            )
          : null,
      backgroundColor: Colors.grey.shade100,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) async {
          setState(() {
            currentIndex = index;
          });

          if (index == 0) {
            await fetchDashboardData();
          } else if (index == 1) {
            await salesPageKey.currentState?.refreshList();
          } else if (index == 2) {
            await purchasePageKey.currentState?.refreshList();
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
            label: "Clients",
          ),
        ],
      ),

      body: IndexedStack(
        index: currentIndex,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              child: graphLoading
                  ? const SizedBox(
                      height: 500,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(strokeWidth: 3),
                            SizedBox(height: 14),
                            Text(
                              "Loading Dashboard...",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        DashboardInsights(dashboardData: dashboardData),

                        /// 🔹 TITLE
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Quick Links",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

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
                              quickCard(
                                Icons.people_alt,
                                "Client",
                                Colors.purple,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManageClientPage(),
                                    ),
                                  );
                                },
                              ),

                              quickCard(
                                Icons.person,
                                "Employee",
                                Colors.green,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManageEmployeePage(),
                                    ),
                                  );
                                },
                              ),

                              quickCard(
                                Icons.inventory_2,
                                "Items",
                                Colors.teal,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ItemScreen(),
                                    ),
                                  );
                                },
                              ),
                              quickCard(
                                Icons.shopping_cart,
                                "Sale",
                                Colors.indigo,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SalesManagePage(),
                                    ),
                                  );
                                },
                              ),

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

                              quickCard(
                                Icons.payments,
                                "Payment",
                                Colors.red,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManagePaymentPage(),
                                    ),
                                  );
                                },
                              ),

                              quickCard(
                                Icons.receipt_long,
                                "Receipt",
                                Colors.amber,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManageReceiptPage(),
                                    ),
                                  );
                                },
                              ),
                              quickCard(
                                Icons.book,
                                "Ledger",
                                Colors.blueGrey,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => LedgerPage(),
                                    ),
                                  );
                                },
                              ),
                              quickCard(
                                Icons.inventory_2,
                                "Item-Report",
                                Colors.lightGreen,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ItemStockPage(),
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
                                    MaterialPageRoute(
                                      builder: (_) => TransactionPage(),
                                    ),
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
                                    MaterialPageRoute(
                                      builder: (_) => ReportDuePage(),
                                    ),
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
                                    MaterialPageRoute(
                                      builder: (_) => IncomeListPage(),
                                    ),
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
                                    MaterialPageRoute(
                                      builder: (_) => LowStockPage(),
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
                                    MaterialPageRoute(
                                      builder: (_) => TransactionPage(),
                                    ),
                                  );
                                },
                              ),
                              quickCard(
                                Icons.category,
                                "Category",
                                Colors.green,
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CategoryListPage(),
                                    ),
                                  );
                                },
                              ),
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
                                    padding: const EdgeInsets.all(8),

                                    child: SalesPurchaseChart(
                                      months: List<String>.from(
                                        dashboardData?["months"] ?? [],
                                      ),

                                      salesData: List<double>.from(
                                        (dashboardData?["SaleActivity"] ?? [])
                                            .map((e) => (e as num).toDouble()),
                                      ),

                                      purchaseData: List<double>.from(
                                        (dashboardData?["PurchaseActivity"] ??
                                                [])
                                            .map((e) => (e as num).toDouble()),
                                      ),
                                    ),
                                  ),

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
          SalesManagePage(key: salesPageKey),

          PurchaseManagePage(key: purchasePageKey),

          const ManageClientPage(),
        ],
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
