import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // 🔹 Dummy Data (replace with API later)
  final List<Map<String, dynamic>> notifications = const [
    {
      "title": "Payment Reminder",
      "message": "Your payment of ₹5,000 is due tomorrow",
      "type": "payment",
      "time": "2 hrs ago"
    },
    {
      "title": "New Invoice",
      "message": "Invoice #INV1023 has been generated",
      "type": "invoice",
      "time": "5 hrs ago"
    },
    {
      "title": "Order Update",
      "message": "Your order #ORD45 has been shipped",
      "type": "order",
      "time": "1 day ago"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: notifications.length,
        itemBuilder: (_, i) {
          final item = notifications[i];

          return _notificationCard(item);
        },
      ),
    );
  }

  Widget _notificationCard(Map<String, dynamic> item) {
    IconData icon;
    Color color;

    switch (item["type"]) {
      case "payment":
        icon = Icons.payment;
        color = Colors.red;
        break;
      case "invoice":
        icon = Icons.receipt;
        color = Colors.orange;
        break;
      case "order":
        icon = Icons.local_shipping;
        color = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 ICON
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 10),

          // 🔹 TEXT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["title"],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  item["message"],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(
                  item["time"],
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}