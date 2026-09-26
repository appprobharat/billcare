import 'package:billcare/api/auth_helper.dart';
import 'package:billcare/admin/clients/details.dart';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/home/admin_dashboard.dart';
import 'package:billcare/admin/report/item_stock.dart';
import 'package:billcare/admin/report/state_wise_report.dart';
import 'package:billcare/admin/sale_approval/approve_sale.dart';
import 'package:billcare/admin/settings/change_password.dart';
import 'package:billcare/admin/report/low_stock.dart';
import 'package:billcare/admin/setup/department/department.dart';
import 'package:billcare/admin/setup/designation/designation.dart';
import 'package:billcare/admin/employee/details.dart';
import 'package:billcare/admin/income_expense/category_items_list.dart';
import 'package:billcare/admin/income_expense/category_list.dart';
import 'package:billcare/admin/income_expense/expense_list.dart';
import 'package:billcare/admin/income_expense/income_list.dart';
import 'package:billcare/admin/payment/manage.dart';
import 'package:billcare/admin/purchase/manage.dart';
import 'package:billcare/admin/quick_receipt/manage.dart';
import 'package:billcare/admin/receipt/manage.dart';
import 'package:billcare/admin/report/due_report.dart';
import 'package:billcare/admin/report/ledger.dart';
import 'package:billcare/screens/login.dart';
import 'package:billcare/admin/setup/session.dart';
import 'package:billcare/admin/report/transaction.dart';
import 'package:flutter/material.dart';
import 'package:billcare/admin/items/itemspage.dart';
import 'package:billcare/admin/sale/manage.dart';
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
              _drawerItem(
                Icons.home,
                "Dashboard",
                color: Colors.indigo,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => DashboardPage()),
                  );
                },
              ),
              // 1. Dashboard
              // _drawerItem(
              //   Icons.home,
              //   "Dashboard",
              //   onTap: () {
              //     Navigator.pushReplacement(
              //       context,
              //       MaterialPageRoute(builder: (_) => DashboardScreen()),
              //     );
              //   },
              // ),
              // _drawerItem(
              //   Icons.apartment,
              //   'Company',
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(builder: (_) => CompanyListPage()),
              //     );
              //   },
              // ),
              // 2. Clients
              _drawerItem(
                Icons.person,
                'Client',
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageClientPage()),
                  );
                },
              ),
              _drawerItem(
                Icons.group,
                'Employee',
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ManageEmployeePage()),
                  );
                },
              ),

              // 3. Items
              _drawerItem(
                Icons.list_alt,
                color: Colors.orange,
                'Items',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ItemScreen()),
                  );
                },
              ),
              _drawerItem(
                Icons.fact_check_outlined,
                'Approve Sale',
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ApproveSalePage()),
                  );
                },
              ),
              ExpansionTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.settings, color: Colors.red),
                ),
                title: const Text(
                  'Setup',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),

                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                visualDensity: const VisualDensity(vertical: -4),
                children: [
                  _drawerItem(
                    Icons.category,
                    'Category',
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CategoryListPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.event,
                    'Session',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SessionPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.badge,
                    'Designation',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DesignationPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.work,
                    'Department',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => DepartmentPage()),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              // 4. Sales
              ExpansionTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt, color: Colors.deepPurple),
                ),
                title: const Text(
                  'Sales',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
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
                ],
              ),
              SizedBox(height: 10),
              // 5. Purchase
              ExpansionTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.cyan.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shopping_cart, color: Colors.cyan),
                ),
                title: const Text(
                  'Purchase',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
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
                color: Colors.pink,
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
                color: Colors.amber,
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
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.attach_money_outlined,
                    color: Colors.green,
                  ),
                ),
                title: const Text(
                  'Inc/Exp',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
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
              SizedBox(height: 10),
              // 11. Reports
              ExpansionTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insert_chart_outlined,
                    color: Colors.amber,
                  ),
                ),

                title: const Text(
                  'Reports',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                ),
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
                  _drawerItem(
                    Icons.assessment,
                    'State-wise Report',
                    color: Colors.deepPurple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StateWiseReportPage(),
                        ),
                      );
                    },
                  ),
                  // _drawerItem(Icons.balance, 'Balance Sheet'),
                  // _drawerItem(Icons.assignment, 'Item Report'),
                  _drawerItem(
                    Icons.swap_horiz,
                    'Txn Report',
                    color: Colors.green,
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
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ReportDuePage()),
                      );
                    },
                  ),

                  _drawerItem(
                    Icons.inventory_2,
                    'Item Stock',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ItemStockPage()),
                      );
                    },
                  ),
                  _drawerItem(
                    Icons.warning_amber_rounded,
                    'Low Stock',
                    color: Colors.brown,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LowStockPage()),
                      );
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              // 12. Settings
              ExpansionTile(
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.settings_suggest_rounded,
                    color: Colors.blue,
                  ),
                ),
                title: const Text(
                  'Settings',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                visualDensity: const VisualDensity(vertical: -4),
                children: [
                  _drawerItem(
                    Icons.key,
                    'Password',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                      );
                    },
                  ),
                ],
              ),

              // 13. Logout
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  // 🟡 1. Call Logout API
                  final res = await ApiService.postRequest(
                    endpoint: "/logout",
                    body: {},
                  );

                  debugPrint("🚪 Logout API Response: $res");

                  // 🔐 2. Delete secure token
                  await AuthStorage.deleteToken();

                  // 🧾 3. Clear SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  if (!context.mounted) return;

                  // 🔁 4. Navigate to Login (clear stack)
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

  Widget _drawerItem(
    IconData icon,
    String title, {
    Color color = Colors.blue,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
