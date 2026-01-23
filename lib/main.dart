import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:billcare/screens/splash/splash_screeen.dart';
import 'package:billcare/themedata.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🛌 Background notification: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await _requestNotificationPermission();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  String? token = await FirebaseMessaging.instance.getToken();
  if (kDebugMode) print("🔐 FCM Token: $token");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground notification: ${message.notification?.title} - ${message.notification?.body}");
  });

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      print('🚀 Opened from terminated: ${message.notification?.title}');
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('🔔 Notification tapped (background): ${message.notification?.title}');
  });

  runApp(const MyApp());
}

Future<void> _requestNotificationPermission() async {
  NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('✅ Notification permission granted');
  } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
    print('ℹ️ Provisional permission granted');
  } else {
    print('❌ Notification permission denied');
  }
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
