import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _oldObscure = true;
  bool _newObscure = true;
  bool _confirmObscure = true;

  bool _isLoading = false;

 Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) return;

  final currentPass = _oldPassCtrl.text.trim();
  final newPass = _newPassCtrl.text.trim();
  final confirmPass = _confirmPassCtrl.text.trim();

  if (currentPass == newPass) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "New password cannot be same as current password",
        ),
      ),
    );
    return;
  }

  if (newPass != confirmPass) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "New password and confirm password do not match",
        ),
      ),
    );
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text("Confirm Change"),
      content: const Text(
        "Are you sure you want to change your password?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text("Yes"),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  setState(() => _isLoading = true);

  final res = await ApiService.postRequest(
    endpoint: "/password",
    isJson: true,
    body: {
      "current_pass": currentPass,
      "new_pass": newPass,
    },
  );

  setState(() => _isLoading = false);

  if (res != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          res["message"]?.toString() ??
              "Password changed successfully!",
        ),
      ),
    );

    Navigator.pop(context);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Password change failed"),
      ),
    );
  }
}

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required Function() toggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,

          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: Colors.grey.shade100,
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
              onPressed: toggle,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Change Password"),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16, // 👈 keyboard fix
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                /// Card UI
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(blurRadius: 8, color: Colors.black12),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 10),

                      const Text(
                        "Update Your Password",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _passwordField(
                        label: "Current Password",
                        controller: _oldPassCtrl,
                        obscure: _oldObscure,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          return null;
                        },
                        toggle: () =>
                            setState(() => _oldObscure = !_oldObscure),
                      ),

                      _passwordField(
                        label: "New Password",
                        controller: _newPassCtrl,
                        obscure: _newObscure,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          if (v.length < 6) return "Min 6 characters";
                          return null;
                        },
                        toggle: () =>
                            setState(() => _newObscure = !_newObscure),
                      ),

                      _passwordField(
                        label: "Confirm Password",
                        controller: _confirmPassCtrl,
                        obscure: _confirmObscure,
                        toggle: () =>
                            setState(() => _confirmObscure = !_confirmObscure),

                        validator: (v) {
                          if (v == null || v.isEmpty) return "Required";
                          if (v != _newPassCtrl.text) {
                            return "Passwords do not match";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      /// Button
                      GestureDetector(
                        onTap: _isLoading ? null : _submit,
                        child: Container(
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: AppColors.primary,
                          ),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Update Password",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
