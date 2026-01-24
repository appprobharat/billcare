import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:billcare/screens/splash/splash_screeen.dart';
import 'package:billcare/themedata.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("🛌 Background notification: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Only minimal safe init here
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BillCare',
      theme: blueGoldTheme,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
