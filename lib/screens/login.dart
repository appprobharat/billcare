import 'package:billcare/api/api_service.dart';
import 'package:billcare/home/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar("Please enter username and password");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loginRes = await ApiService.login(username, password);

      if (loginRes['status'] == true) {
        final prefs = await SharedPreferences.getInstance();

        // Extracting and storing necessary data from the response
        final token = loginRes['token'] as String;
        final type = loginRes['type'] as String;
        final profile = loginRes['profile'] as Map<String, dynamic>;
        final name = profile['name'] as String;
        final company = profile['company'] as String;
        final photo = profile['photo'] as String;

        // Store data in SharedPreferences
        await prefs.setString("username", username);
        await prefs.setString("authToken", token);
        await prefs.setString("userType", type);
        await prefs.setString("userName", name);
        await prefs.setString(
          "companyName",
          company,
        ); 
        await prefs.setString("userPhotoUrl", photo);

        String? fcmToken = await FirebaseMessaging.instance.getToken();

        final tokenRes = await ApiService.saveToken(
          fcmToken!,
          token, // Use the extracted token
        );
        print("Token Save Response: $tokenRes");

        _showSnackBar("Login Successful ✅");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
      } else {
        _showSnackBar(loginRes['message'] ?? "Login failed");
      }
    } catch (e) {
      _showSnackBar("Error: $e");
    }

    setState(() => _isLoading = false);
  }

  void _launchURL() async {
    final Uri url = Uri.parse('https://www.techinnovationapp.in');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/images/logo.png', height: 80),
              const SizedBox(height: 10),

              const Text(
                "BillCare",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 5),

              const Text(
                "BillCare GST Billing Software",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  hintText: "Username",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          "Login",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 30),

              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    "Designed & Developed by ",
                    style: TextStyle(fontSize: 12),
                  ),
                  Text(
                    "TechInnovationApp",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 5),
                  Text("Visit our website", style: TextStyle(fontSize: 12)),
                  GestureDetector(
                    onTap: _launchURL,
                    child: Text(
                      "www.techinnovationapp.in",
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
