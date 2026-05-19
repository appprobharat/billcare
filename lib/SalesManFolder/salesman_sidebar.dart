import 'package:billcare/SalesManFolder/bills/salesman_bills.dart';
import 'package:billcare/SalesManFolder/due/salesman_due.dart';
import 'package:billcare/SalesManFolder/orders/salesman_order.dart';
import 'package:billcare/SalesManFolder/orders/salesman_order_history.dart';
import 'package:billcare/SalesManFolder/payment/salesman_payment_history.dart';
import 'package:billcare/SalesManFolder/profile/salesman_profile.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SalesSidebar extends StatelessWidget {
  final String userName;
  final String companyName;
  final String? imageUrl;

  const SalesSidebar({
    super.key,
    required this.userName,
    required this.companyName,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // 🔥 TOP HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4A6CF7), Color(0xff6C63FF)],
              ),
            ),
            child: Row(
              children: [
                // 👤 PROFILE
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white,
                  backgroundImage: imageUrl != null
                      ? NetworkImage(imageUrl!)
                      : const AssetImage("assets/images/logo.png")
                            as ImageProvider,
                ),

                const SizedBox(width: 12),

                // 👋 NAME + COMPANY
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        companyName,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🔥 MENU ITEMS
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _tile(Icons.dashboard, "Dashboard", () {
                  Navigator.pop(context);
                }),
                _tile(Icons.shopping_bag, "Orders", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SalesOrderPage()),
                  );
                }),
                _tile(Icons.card_travel, "Orders History", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SalesOrderHistoryPage()),
                  );
                }),

                _tile(Icons.payment, "Payments", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SalesPaymentHistoryPage(),
                    ),
                  );
                }),
                _tile(Icons.receipt_long, "Bills", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SalesBillPage()),
                  );
                }),
                _tile(Icons.receipt_outlined, "Due", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SalesDuePaymentPage()),
                  );
                }),
                _tile(Icons.person, "Profile", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SalesProfilePage()),
                  );
                }),

                // _tile(Icons.bar_chart, "Reports", () {}),

                // _tile(Icons.settings, "Settings", () {}),

                // _tile(Icons.help_outline, "Help", () {}),
                const Divider(),

                _tile(Icons.logout, "Logout", () async {
                  // 🟡 1. Call logout API
                  final res = await ApiService.postRequest(
                    endpoint: "/logout",
                    body: {},
                  );

                  debugPrint("🚪 Logout API Response: $res");

                  // 🔐 2. Delete token
                  await AuthStorage.deleteToken();

                  // 🧾 3. Clear local storage
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  if (!context.mounted) return;

                  // 🔁 4. Navigate to login
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }, isLogout: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 REUSABLE TILE
  Widget _tile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}
