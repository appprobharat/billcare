import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool isLoading = true;

  Map<String, dynamic> profile = {};

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() {
      isLoading = true;
    });

    final res = await ApiService.postRequest(endpoint: "/client/profile");

    if (res != null) {
      setState(() {
        profile = Map<String, dynamic>.from(res);
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  void changePassword() {
    showDialog(
      context: context,
      builder: (_) {
        final oldCtrl = TextEditingController();
        final newCtrl = TextEditingController();

        bool showOld = false;
        bool showNew = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 TITLE
                    Row(
                      children: const [
                        Icon(Icons.lock, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "Change Password",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 🔹 OLD PASSWORD
                    TextField(
                      controller: oldCtrl,
                      obscureText: !showOld,
                      decoration: InputDecoration(
                        hintText: "Old Password",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showOld ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => showOld = !showOld);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 🔹 NEW PASSWORD
                    TextField(
                      controller: newCtrl,
                      obscureText: !showNew,
                      decoration: InputDecoration(
                        hintText: "New Password",
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            showNew ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() => showNew = !showNew);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 BUTTONS
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: API
                              Navigator.pop(context);
                            },
                            child: const Text("Update"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Profile"),
          centerTitle: true,
          elevation: 0,
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    children: [
                      /// =========================
                      /// PROFILE HEADER
                      /// =========================
                      Container(
                        width: double.infinity,

                        padding: const EdgeInsets.all(10),

                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(18),
                        ),

                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 42,

                              backgroundColor: Colors.white,

                              backgroundImage:
                                  profile["Photo"] != null &&
                                      profile["Photo"].toString().isNotEmpty
                                  ? NetworkImage(profile["Photo"])
                                  : null,

                              child:
                                  profile["Photo"] == null ||
                                      profile["Photo"].toString().isEmpty
                                  ? const Icon(
                                      Icons.person,
                                      size: 42,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            Text(
                              profile["Name"] ?? "Customer",

                              textAlign: TextAlign.center,

                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              profile["ContactNo"]?.toString() ??
                                  "Not Provided",

                              style: TextStyle(
                                color: Colors.black26,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// =========================
                      /// DETAILS CARD
                      /// =========================
                      Container(
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,

                          borderRadius: BorderRadius.circular(18),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),

                        child: Column(
                          children: [
                            _profileRow(
                              Icons.phone_outlined,
                              "Mobile :",
                              profile["ContactNo"],
                            ),

                            _profileRow(
                              Icons.email_outlined,
                              "Email :",
                              profile["Email"],
                            ),

                            _profileRow(
                              Icons.badge_outlined,
                              "GSTIN :",
                              profile["GSTIN"],
                            ),

                            _profileRow(
                              Icons.credit_card_outlined,
                              "PAN :",
                              profile["PanNo"],
                            ),

                            _profileRow(
                              Icons.perm_identity_outlined,
                              "Aadhar :",
                              profile["AadharNo"],
                            ),

                            _profileRow(
                              Icons.location_on_outlined,
                              "Address :",
                              profile["Address"],
                            ),

                            _profileRow(
                              Icons.map_outlined,
                              "State :",
                              profile["State"],
                            ),

                            _profileRow(
                              Icons.pin_drop_outlined,
                              "Pincode :",
                              profile["Pincode"],
                            ),

                            _profileRow(
                              Icons.account_balance_outlined,
                              "Bank :",
                              profile["Bank"],
                            ),

                            _profileRow(
                              Icons.numbers_outlined,
                              "Account No :",
                              profile["AccNo"],
                            ),

                            _profileRow(
                              Icons.qr_code_outlined,
                              "IFSC :",
                              profile["IFSC"],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 46,

                        child: ElevatedButton.icon(
                          onPressed: changePassword,

                          icon: const Icon(Icons.lock_reset_outlined),

                          label: const Text("Change Password"),

                          style: ElevatedButton.styleFrom(
                            elevation: 0,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _profileRow(IconData icon, String title, dynamic value) {
    final text = value == null || value.toString().trim().isEmpty
        ? "Not Provided"
        : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Container(
            padding: const EdgeInsets.all(8),

            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),

              borderRadius: BorderRadius.circular(10),
            ),

            child: Icon(icon, size: 18, color: Colors.blue),
          ),

          const SizedBox(width: 12),

          SizedBox(
            width: 85,

            child: Text(
              title,

              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              text,

              style: TextStyle(
                fontSize: 13,

                fontWeight: text == "Not Provided"
                    ? FontWeight.w400
                    : FontWeight.w500,

                color: text == "Not Provided"
                    ? Colors.grey.shade500
                    : Colors.black87,

                fontStyle: text == "Not Provided"
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
