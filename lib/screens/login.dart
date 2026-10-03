import 'package:billcare/SalesManFolder/salesman_dashboard.dart';
import 'package:billcare/Usersfolder/user_Dashboard.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/admin/home/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _errorMessage;
  Future<void> _login() async {
    if (_isLoading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please enter username and password";
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loginRes = await ApiService.login(username, password);
      debugPrint("LOGIN RESPONSE: $loginRes");

      if (loginRes['status'] == true) {
        final token = loginRes['token']?.toString() ?? '';

        if (token.isEmpty) {
          _showSnackBar("Token missing");
          return;
        }

        final profile = loginRes['profile'] ?? {};

        // ✅ TOKEN SAVE
        await AuthStorage.saveToken(token);

        // ✅ SHARED PREF SAVE
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("token", token);
        await prefs.setString("username", username);
        await prefs.setString("userType", loginRes['type'] ?? '');
        await prefs.setString("userName", profile['name'] ?? '');
        await prefs.setString("companyName", profile['company'] ?? '');
        await prefs.setString("userPhotoUrl", profile['photo'] ?? '');

        debugPrint("✅ Saved Name: ${profile['name']}");
        debugPrint("✅ Saved Company: ${profile['company']}");
        debugPrint("✅ Saved Photo: ${profile['photo']}");

        if (!mounted) return;

        final userType = loginRes['type']?.toString().toLowerCase() ?? '';

        await prefs.setString("userType", userType);

        if (!mounted) return;

        if (userType == "client") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserDashboard()),
          );
        } else if (userType == "sales") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SalesDashboard()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      } else {
        setState(() {
          _errorMessage = loginRes['message'] ?? "Invalid username or password";
        });
      }
    } catch (e) {
      debugPrint("ERROR: $e");

      setState(() {
        _errorMessage = "Invalid username or password";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _launchURL() async {
    final Uri url = Uri.parse('https://www.techinnovationapp.in');

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showSnackBar("Could not open website");
      }
    } catch (e) {
      _showSnackBar("Error opening website");
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xffEEF4FF), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),

            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 420),
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(blurRadius: 25, color: Colors.black12),
                          ],
                        ),

                        child: Column(
                          children: [
                            Container(
                              height: 95,
                              width: 95,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 18,
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(18),
                                child: Image.asset("assets/images/logo.png"),
                              ),
                            ),
                            SizedBox(height: 5),

                            Text(
                              "BillCare",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "GST Billing Software",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 50),

                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: "Username",
                                prefixIcon: Container(
                                  margin: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColors.primary,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade100,

                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),

                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: "Password",
                                prefixIcon: Container(
                                  margin: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.lock,
                                    color: AppColors.primary,
                                  ),
                                ),
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
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide.none,
                                ),

                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  borderSide: BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                height: 55,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff4F46E5),
                                      Color(0xff7C3AED),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _login,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.login,
                                              color: Colors.white,
                                              size: 20,
                                            ),

                                            SizedBox(width: 10),

                                            Text(
                                              "Login",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                    ),

                                    SizedBox(width: 10),

                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            SizedBox(height: 20),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                _chip("GST Ready"),

                                _chip("Inventory"),

                                _chip("Reports"),

                                _chip("Secure"),
                              ],
                            ),
                            SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                const Text(
                                  "Designed & Developed by ",
                                  style: TextStyle(fontSize: 12),
                                ),
                                const Text(
                                  "TechInnovationApp",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Text(
                                  "Visit our website",
                                  style: TextStyle(fontSize: 12),
                                ),
                                GestureDetector(
                                  onTap: _launchURL,
                                  child: const Text(
                                    "www.techinnovationapp.in",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(30),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 14, color: Colors.deepPurple),

          SizedBox(width: 6),

          Text(text),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
