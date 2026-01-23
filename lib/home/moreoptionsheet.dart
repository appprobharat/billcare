import 'package:flutter/material.dart';

class MoreOptionsSheet extends StatefulWidget {
  const MoreOptionsSheet({super.key});
  @override
  State<MoreOptionsSheet> createState() => _MoreOptionsSheetState();
}

class _MoreOptionsSheetState extends State<MoreOptionsSheet> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          color: Colors.white,
        ),
        // Use MediaQuery to get the height based on available space
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "More Options",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              // textAlign: TextAlign.left,
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      double screenWidth = constraints.maxWidth;
                      double spacing = screenWidth * 0.10;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing / 1.5,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildOption(Icons.account_balance, "Bank Accounts"),
                          _buildOption(Icons.menu_book, "Day Book"),
                          _buildOption(Icons.receipt_long, "All Txns Report"),
                          _buildOption(Icons.pie_chart, "Profit & Loss"),
                          _buildOption(
                            Icons.balance,
                            "Balance Sheet",
                            isPremium: true,
                          ),
                          _buildOption(
                            Icons.bar_chart,
                            "Billwise PnL",
                            isPremium: true,
                          ),
                          _buildOption(Icons.print, "Print Settings"),
                          _buildOption(Icons.settings, "Txn SMS Settings"),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(IconData icon, String label, {bool isPremium = false}) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label clicked'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: Colors.orangeAccent),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          if (isPremium)
            const Positioned(
              right: 4,
              top: -4,
              left: 18,
              child: Icon(
                Icons.workspace_premium,
                size: 18,
                color: Colors.amber,
              ),
            ),
        ],
      ),
    );
  }
}
