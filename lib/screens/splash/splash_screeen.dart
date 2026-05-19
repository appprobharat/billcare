import 'package:billcare/SalesManFolder/salesman_dashboard.dart';
import 'package:billcare/home/new_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/screens/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billcare/Usersfolder/user_Dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

 Future<void> _boot() async {
  await Future.delayed(const Duration(seconds: 1));

  final token = await AuthStorage.getToken();
  final prefs = await SharedPreferences.getInstance();

  final userType = prefs.getString("userType");

  print("TOKEN: $token");
  print("USERTYPE: $userType");

  if (!mounted) return;

  /// ✅ LOGGED IN
  if (token != null && token.isNotEmpty) {
    if (userType == "admin") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        ),
      );
    } else if (userType == "sales") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const SalesDashboard(),
        ),
      );
    } else if (userType == "client") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const UserDashboard(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    }
  }

  /// ❌ NOT LOGGED IN
  else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', height: 120),
            const SizedBox(height: 20),
            const Text(
              'BillCare',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
