import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/clients/details.dart';
import 'package:billcare/income_expense/category_items_list.dart';
import 'package:billcare/income_expense/category_list.dart';
import 'package:billcare/income_expense/expense_list.dart';
import 'package:billcare/income_expense/income_list.dart';
import 'package:billcare/payment/manage.dart';
import 'package:billcare/purchase/manage.dart';
import 'package:billcare/quick_receipt/manage.dart';
import 'package:billcare/receipt/manage.dart';
import 'package:billcare/report/due_report.dart';
import 'package:billcare/report/ledger/ledger.dart';
import 'package:billcare/screens/login.dart';
import 'package:billcare/transaction/transaction.dart';
import 'package:flutter/material.dart';
import 'package:billcare/home/dashboard_screen.dart';
import 'package:billcare/items/itemspage.dart';
import 'package:billcare/sale/manage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeftSidebar extends StatelessWidget {
  final String companyName;
  final String name;
  final String photo;

  const LeftSidebar({
    super.key,
    required this.companyName,
    required this.name,
    required this.photo,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 220,
        color: Colors.white,
        child: Drawer(
          elevation: 0,
          child: ListView(
            children: [
              Container(
                color: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                height: 70,
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: ClipOval(
                        child: (photo.isNotEmpty)
                            ? Image.network(
                                photo,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.grey,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.store,
                                    color: Colors.grey,
                                    size: 24,
                                  );
                                },
                              )
                            : const Icon(
                                Icons.store,
                                color: Colors.grey,
                                size: 24,
                              ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 1. Dashboard
              _drawerItem(
                Icons.home,
                "Dashboard",
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => DashboardScreen()),
                  );
                },
              ),

              // 2. Clients
              _drawerItem(
                Icons.person,
                'Client',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageClientPage()),
                  );
                },
              ),
              // 3. Items
              _drawerItem(
                Icons.list_alt,
                'Items',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ItemScreen()),
                  );
                },
              ),

              // 4. Sales
              ExpansionTile(
                leading: const Icon(Icons.receipt),
                title: const Text('Sales'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                visualDensity: const VisualDensity(vertical: -4),
                children: [
                  _drawerItem(
                    Icons.manage_accounts,
                    'Manage',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SalesManagePage()),
                      );
                    },
                  ),
                  // _drawerItem(
                  //   Icons.receipt_long,
                  //   'Order',
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (_) => SalesOrderPage()),
                  //     );
                  //   },
                  // ),
                  // _drawerItem(
                  //   Icons.keyboard_return,
                  //   'Return',
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (_) => ReturnPage()),
                  //     );
                  //   },
                  // ),
                ],
              ),

              // 5. Purchase
              ExpansionTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('Purchase'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                visualDensity: const VisualDensity(vertical: -4),
                children: [
                  _drawerItem(
                    Icons.manage_accounts,
                    'Manage',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PurchaseManagePage()),
                      );
                    },
                  ),
                  // _drawerItem(
                  //   Icons.receipt_long,
                  //   'Order',
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (_) => PurchaseOrderPage()),
                  //     );
                  //   },
                  // ),
                  // _drawerItem(
                  //   Icons.money_off,
                  //   'Return',
                  //   onTap: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (_) => PurchaseReturnPage()),
                  //     );
                  //   },
                  // ),
                ],
              ),

              // 6. Quotation
              // _drawerItem(
              //   Icons.request_quote,
              //   "Quotation",
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => QuotationPage()),
              //     );
              //   },
              // ),

              // 7. Payment
              _drawerItem(
                Icons.payments,
                'Payment',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManagePaymentPage()),
                  );
                },
              ),

              // 8. Receipt
              _drawerItem(
                Icons.receipt_long,
                'Receipt',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageReceiptPage()),
                  );
                },
              ),

              // 9. Quick Receipt
              _drawerItem(
                Icons.flash_on,
                'Quick Receipt',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageQuickReceiptPage()),
                  );
                },
              ),

              // 10. Income
              ExpansionTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Inc/Exp'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                visualDensity: const VisualDensity(vertical: -4),
                children: [
                  _drawerItem(
                    Icons.category,
                    'Category',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CategoryListPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.add_box,
                    'Items',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CategoryItemsListPage(),
                        ),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.money_outlined,
                    'Income',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => IncomeListPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.money_off,
                    'Expense',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ExpenseListPage()),
                      );
                    },
                  ),
                ],
              ),

              // 11. Reports
              ExpansionTile(
                leading: const Icon(Icons.insert_chart),
                title: const Text('Reports'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                visualDensity: const VisualDensity(vertical: -4),
                children: [
                  _drawerItem(
                    Icons.book,
                    'Ledger',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LedgerPage()),
                      );
                    },
                  ),
                  // _drawerItem(Icons.book, 'Day Book'),
                  // _drawerItem(Icons.balance, 'Balance Sheet'),
                  // _drawerItem(Icons.assignment, 'Item Report'),
                  _drawerItem(
                    Icons.swap_horiz,
                    'Txn Report',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TransactionPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.schedule,
                    'Due Report',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReportDuePage()),
                      );
                    },
                  ),
                  _drawerItem(Icons.inventory_2, 'Item Stock'),
                ],
              ),

              // 12. Settings
              ExpansionTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                visualDensity: const VisualDensity(vertical: -4),
                children: [
                  _drawerItem(Icons.calendar_month, "Session"),
                  _drawerItem(Icons.receipt, 'Sale Format'),
                  _drawerItem(Icons.key, 'Password'),
                ],
              ),

              // 13.Logout
             // 13. Logout
ListTile(
  leading: const Icon(Icons.logout, color: Colors.red),
  title: const Text(
    'Logout',
    style: TextStyle(color: Colors.red),
  ),
  onTap: () async {

    // 🔐 1. Delete secure token
    await AuthStorage.deleteToken();

    // 🧾 2. Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    // 🔁 3. Go to Login & clear navigation stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  },
),

            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        visualDensity: const VisualDensity(horizontal: 0, vertical: -3),
        title: Text(title),
        onTap: onTap,
      ),
    );
  }
}
