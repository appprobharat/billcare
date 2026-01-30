import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:billcare/screens/login.dart';

/// =======================
/// 🔐 AUTH STORAGE
/// =======================
class AuthStorage {
  static const FlutterSecureStorage _secure = FlutterSecureStorage();

  // 🔑 TOKEN (Secure)
  static Future<void> saveToken(String token) async {
    await _secure.write(key: 'auth_token', value: token);
  }

  static Future<String?> getToken() async {
    return await _secure.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _secure.delete(key: 'auth_token');
  }

  // ⚙️ LOGIN FLAG (Fast)
  static Future<void> setLoggedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<void> logout() async {
    await deleteToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}

/// =======================
/// 🛡️ AUTH GUARD
/// =======================
class AuthGuard {
  static Future<void> ensureLoggedIn(BuildContext context) async {
    final loggedIn = await AuthStorage.isLoggedIn();
    final token = await AuthStorage.getToken();

    if (!loggedIn || token == null || token.isEmpty) {
      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    }
  }
}
