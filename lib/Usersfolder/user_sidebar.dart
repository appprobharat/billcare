import 'package:billcare/Usersfolder/bills/user_bills.dart';
import 'package:billcare/Usersfolder/due/user_due.dart';
import 'package:billcare/Usersfolder/orders/order_history.dart';
import 'package:billcare/Usersfolder/orders/user_order.dart';
import 'package:billcare/Usersfolder/payment/payment_history.dart';
import 'package:billcare/Usersfolder/profile/user_profile.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';

import 'package:billcare/screens/login.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSidebar extends StatelessWidget {
  final String userName;
  final String companyName;
  final String? imageUrl;

  const UserSidebar({
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
                    MaterialPageRoute(builder: (_) => UserOrderPage()),
                  );
                }),
                _tile(Icons.card_travel, "Orders History", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderHistoryPage()),
                  );
                }),

                _tile(Icons.payment, "Payments", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PaymentHistoryPage()),
                  );
                }),
                _tile(Icons.receipt_long, "Bills", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserBillPage()),
                  );
                }),
                _tile(Icons.receipt_outlined, "Due", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserDuePaymentPage()),
                  );
                }),
                _tile(Icons.person, "Profile", () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => UserProfilePage()),
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
