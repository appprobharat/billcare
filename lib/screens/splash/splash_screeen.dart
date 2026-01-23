import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billcare/screens/login.dart';
import 'package:billcare/home/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // ✅ Wait for splash delay
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("authToken");

    if (token != null && token.isNotEmpty) {
      // ✅ Already logged in → go to Dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      // 🔁 Not logged in → go to Login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
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
                color:  Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          ],
        ),
      ),
    );
  }
}
