import 'package:billcare/api/api_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SessionPage extends StatefulWidget {
  const SessionPage({super.key});

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  List<Map<String, dynamic>> _sessions = [];
  bool isLoading = false;

  final TextEditingController _startCtrl = TextEditingController();
  final TextEditingController _endCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  Future<void> _pickDate(TextEditingController controller) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd MMM yyyy').format(pickedDate);
      controller.text = formattedDate;
    }
  }

  String formatToApiDate(String inputDate) {
    try {
      final parsed = DateFormat('dd MMM yyyy').parse(inputDate);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (e) {
      return inputDate; // fallback
    }
  }

  Future<void> saveSession({int? id}) async {
    setState(() => isLoading = true);

    final endpoint = id == null ? "/session/store" : "/session/update";

    Map<String, dynamic> body;

    if (id == null) {
      /// ✅ STORE (simple keys)
      body = {
        "Start": formatToApiDate(_startCtrl.text),
        "End": formatToApiDate(_endCtrl.text),
      };
    } else {
      /// ✅ UPDATE (nested keys)
      body = {
        "session[SessionId]": id.toString(),
        "session[Start]": formatToApiDate(_startCtrl.text),
        "session[End]": formatToApiDate(_endCtrl.text),
      };
    }

    print("📤 SESSION SAVE => $body");

    final res = await ApiService.postRequest(endpoint: endpoint, body: body);

    print("📥 SESSION SAVE RESPONSE => $res");

    if (res != null) {
      await fetchSessions();
    }

    setState(() => isLoading = false);
  }

  Future<void> toggleStatus(int id, int currentStatus) async {
    setState(() => isLoading = true);

    final newStatus = currentStatus == 1 ? 0 : 1;

    final body = {"SessionId": id.toString(), "Status": newStatus.toString()};

    print("📤 SESSION STATUS => $body");

    final res = await ApiService.postRequest(
      endpoint: "/session/status",
      body: body,
    );

    print("📥 SESSION STATUS RESPONSE => $res");

    if (res != null) {
      await fetchSessions();
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchSessions() async {
    setState(() => isLoading = true);

    final data = await ApiService.postRequest(endpoint: "/session/list");

    print("📦 SESSION LIST => $data");

    if (data != null && data is List) {
      setState(() {
        _sessions = List<Map<String, dynamic>>.from(data);
      });
    }

    setState(() => isLoading = false);
  }

  /// 🔹 Bottom Sheet (Add/Edit)
  void _openSessionSheet({int? index}) {
    if (index == null) {
      _startCtrl.clear();
      _endCtrl.clear();
    } else {
      _startCtrl.text = _sessions[index]['Start'] ?? '';
      _endCtrl.text = _sessions[index]['End'] ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // 👈 important
      builder: (context) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),

            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),

              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),

                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        index == null ? "Add Session" : "Edit Session",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// 🔹 Start Session
                      GestureDetector(
                        onTap: () => _pickDate(_startCtrl),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _startCtrl,
                            decoration: InputDecoration(
                              labelText: "Session Start Date",
                              suffixIcon: const Icon(Icons.calendar_today),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      /// 🔹 End Session
                      GestureDetector(
                        onTap: () => _pickDate(_endCtrl),
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _endCtrl,
                            decoration: InputDecoration(
                              labelText: "Session End Date",
                              suffixIcon: const Icon(Icons.calendar_today),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_startCtrl.text.isEmpty ||
                                _endCtrl.text.isEmpty)
                              return;

                            await saveSession(
                              id: index != null ? _sessions[index]['id'] : null,
                            );

                            _startCtrl.clear();
                            _endCtrl.clear();
                            Navigator.pop(context);
                          },
                          child: Text(index == null ? "Add" : "Update"),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 🔹 Format display
  String _formatSession(String start, String end) {
    return "$start - $end";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sessions"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openSessionSheet(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
          ? const Center(child: Text("No Sessions Found"))
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _sessions.length,
              itemBuilder: (context, index) {
                final session = _sessions[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      /// Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          color: Colors.orange,
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// Text
                      Expanded(
                        child: Text(
                          _formatSession(
                            session['Start'] ?? "",
                            session['End'] ?? "",
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),

                      Row(
                        children: [
                          /// 🔥 STATUS BUTTON (NEW)
                          IconButton(
                            icon: Icon(
                              (session['Status'] ?? 0) == 1
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: (session['Status'] ?? 0) == 1
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            onPressed: () {
                              toggleStatus(session['id'], session['Status']);
                            },
                          ),

                          /// ✏️ EDIT BUTTON
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => _openSessionSheet(index: index),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
