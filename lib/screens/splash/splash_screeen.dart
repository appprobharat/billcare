import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
    _initApp();
  }

  /// 🔥 This runs AFTER UI loads (safe for iOS)
  Future<void> _initApp() async {
    try {
      // 1️⃣ Ask notification permission (iOS-safe now)
      await _requestNotificationPermission();

      // 2️⃣ Get FCM token (can be slow on iOS)
      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint("🔐 FCM Token: $token");

      // 3️⃣ Notification listeners
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          "📩 Foreground notification: ${message.notification?.title} - ${message.notification?.body}",
        );
      });

      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          debugPrint('🚀 Opened from terminated: ${message.notification?.title}');
        }
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint(
          '🔔 Notification tapped (background): ${message.notification?.title}',
        );
      });
    } catch (e) {
      debugPrint("⚠ Firebase init error (non-fatal): $e");
    }

    // 4️⃣ Small splash delay
    await Future.delayed(const Duration(seconds: 2));

    // 5️⃣ Now check login
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString("authToken");

    if (!mounted) return;

    if (authToken != null && authToken.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  Future<void> _requestNotificationPermission() async {
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus ==
        AuthorizationStatus.authorized) {
      debugPrint('✅ Notification permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('ℹ️ Provisional permission granted');
    } else {
      debugPrint('❌ Notification permission denied');
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
            const SizedBox(height: 10),
            const CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          ],
        ),
      ),
    );
  }
}
