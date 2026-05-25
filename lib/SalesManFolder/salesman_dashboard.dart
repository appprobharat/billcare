import 'package:billcare/SalesManFolder/SalesManAddReceipt.dart';
import 'package:billcare/SalesManFolder/bills/salesman_bills.dart';
import 'package:billcare/SalesManFolder/due/salesman_due.dart';
import 'package:billcare/SalesManFolder/notification/salesman_notification.dart';
import 'package:billcare/SalesManFolder/orders/salesman_order.dart';
import 'package:billcare/SalesManFolder/orders/salesman_order_history.dart';
import 'package:billcare/SalesManFolder/profile/salesman_profile.dart';
import 'package:billcare/SalesManFolder/salesman_sidebar.dart';
import 'package:billcare/admin/receipt/manage.dart';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesDashboard extends StatefulWidget {
  const SalesDashboard({super.key});

  @override
  State<SalesDashboard> createState() => _SalesDashboardState();
}

class _SalesDashboardState extends State<SalesDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = "";
  String companyName = "";
  String? photoUrl;

  double outstanding = 0;
  String lastAmount = "";

  bool isSuccess = true;
  bool isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    loadUserData();
  }

  Future<void> loadUserData() async {
    /// 🔥 START LOADING
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();

    /// ✅ SharedPrefs data
    userName = prefs.getString("userName") ?? "";

    companyName = prefs.getString("companyName") ?? "";

    photoUrl = prefs.getString("userPhotoUrl");

    final res = await ApiService.postRequest(
      endpoint: "/saleman/dashboard",
      body: {},
    );

    if (res != null && res is Map<String, dynamic>) {
      outstanding = double.tryParse(res['due'].toString()) ?? 0;

      lastAmount = res['received'].toString();

      isSuccess = lastAmount != "0";
    } else {
      debugPrint("Dashboard API failed");
    }

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }

  Widget _homePage() {
    return Column(
      children: [
        // 🔵 PREMIUM HEADER
        Container(
          padding: const EdgeInsets.fromLTRB(20, 55, 20, 25),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xffFF9966), Color(0xffFF5E62)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 TOP BAR
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      _scaffoldKey.currentState?.openDrawer();
                    },
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // 👋 NAME
                  Expanded(
                    child: Text(
                      "Hi, ${userName.isNotEmpty ? userName : "User"} 👋",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 🔔 + 👤 (same as before)
                  Row(
                    children: [
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationPage(),
                                ),
                              );
                            },
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                "3",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              photoUrl != null && photoUrl!.isNotEmpty
                              ? NetworkImage(photoUrl!)
                              : const AssetImage("assets/images/logo.png")
                                    as ImageProvider,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(color: Colors.white30),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _modernCard(
                      title: "Client Dues",
                      value: "₹ ${outstanding.toStringAsFixed(0)}",
                      color: Colors.red,

                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _modernCard(
                      title: "Today Received",
                      value: isSuccess ? "₹$lastAmount" : "No Payment",
                      color: isSuccess ? Colors.green : Colors.red,
                      icon: isSuccess ? Icons.check_circle : Icons.cancel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: loadUserData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Quick Actions
                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          Icons.shopping_cart,
                          "Order",
                          Colors.purple,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SalesOrderPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionCard(
                          Icons.payment,
                          "Receipt",
                          Colors.green,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SalesManAddReceipt(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionCard(
                          Icons.receipt,
                          "Bills",
                          Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SalesBillPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _actionCard(
                          Icons.history,
                          "Due",
                          Colors.red,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SalesDuePaymentPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _bigTile("Receipt History", Icons.payment, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageReceiptPage(),
                      ),
                    );
                  }),
                  _bigTile("Order History", Icons.shopping_bag, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SalesOrderHistoryPage(),
                      ),
                    );
                  }),

                  const SizedBox(height: 25),

                  // 🔹 PROFILE CARD
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalesProfilePage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade100, Colors.white],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage:
                                photoUrl != null && photoUrl!.isNotEmpty
                                ? NetworkImage(photoUrl!)
                                : const AssetImage("assets/images/logo.png")
                                      as ImageProvider,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  companyName,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _homePage(),
      const SalesOrderHistoryPage(),
      const ManageReceiptPage(),
      const SalesProfilePage(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xfff2f4f8),
      key: _scaffoldKey,

      drawer: SizedBox(
        width: 220,
        child: SalesSidebar(
          userName: userName,
          companyName: companyName,
          imageUrl: photoUrl,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Orders"),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: "Receipts"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _modernCard({
    required String title,
    required String value,

    required Color color,
    required IconData icon,
  }) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const Spacer(),
            ],
          ),

          const SizedBox(height: 8),

          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),

          const SizedBox(height: 6),

          // 🔥 VALUE → auto fit inside box
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 ACTION CARD
  Widget _actionCard(
    IconData icon,
    String text,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: Icon(icon, color: color, size: 30)),
            ),

            const SizedBox(height: 6),

            Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 BIG TILE
  Widget _bigTile(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(child: Text(title)),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
