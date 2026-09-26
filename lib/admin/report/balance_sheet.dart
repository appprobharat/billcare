// import 'package:billcare/admin/report/balance_sheet_pdf.dart';
// import 'package:billcare/api/api_service.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class BalanceSheetPage extends StatefulWidget {
//   const BalanceSheetPage({super.key});

//   @override
//   State<BalanceSheetPage> createState() => _BalanceSheetPageState();
// }

// class _BalanceSheetPageState extends State<BalanceSheetPage> {
//   DateTime toDate = DateTime.now();
//   DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));

//   final double totalIncome = 66;
//   final double totalExpenses = 40;
//   final double totalReceipt = 222;
//   final double totalDiscount = 20;
//   String receiptSearch = '';
//   final List<Map<String, dynamic>> receiptList = [
//     {
//       "name": "Kishan Ji Company",
//       "amount": 2.0,
//       "discount": 0.0,
//       "refNo": "RN/20",
//     },
//     {
//       "name": "Sohanlal Company",
//       "amount": 100.0,
//       "discount": 20.0,
//       "refNo": "RN/21",
//     },
//     {"name": "ab---", "amount": 120.0, "discount": 0.0, "refNo": "RN/22"},
//   ];

//   double get netBalance =>
//       totalIncome + totalReceipt - totalExpenses - totalDiscount;

//   String formatDate(DateTime date) {
//     return DateFormat("dd MMM yyyy").format(date);
//   }

//   Future<void> pickDate(bool isFrom) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: isFrom ? fromDate : toDate,
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );

//     if (picked != null) {
//       setState(() {
//         if (isFrom) {
//           fromDate = picked;
//         } else {
//           toDate = picked;
//         }
//       });

//       // getBalanceSheet(); // Auto refresh
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF5F6FA),
//       appBar: AppBar(
//         elevation: 0,
//         centerTitle: true,
//         title: const Text(
//           "Balance Sheet",
//           style: TextStyle(color: Colors.white),
//         ),
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [AppColors.primary, AppColors.primary.withOpacity(.8)],
//             ),
//           ),
//         ),
//         actions: [
//           Padding(
//             padding: EdgeInsets.symmetric(horizontal: 12),
//             child: IconButton(
//               icon: const Icon(Icons.picture_as_pdf),
//               onPressed: () async {
//                 await BalanceSheetPdf.generate(
//                   companyName: "ABCD ENTERPRISES",
//                   fromDate: formatDate(fromDate),
//                   toDate: formatDate(toDate),

//                   totalIncome: totalIncome,
//                   totalExpense: totalExpenses,
//                   totalReceipt: totalReceipt,
//                   totalDiscount: totalDiscount,

//                   incomeList: [
//                     {
//                       "date": "03-06-2026",
//                       "category": "Book",
//                       "item": "Diary",
//                       "qty": 1,
//                       "price": 66,
//                       "amount": 66,
//                     },
//                   ],

//                   expenseList: [
//                     {
//                       "date": "03-06-2026",
//                       "category": "Coffee",
//                       "item": "Cold Drink",
//                       "qty": 1,
//                       "price": 40,
//                       "amount": 40,
//                     },
//                   ],

//                   receiptList: [
//                     {
//                       "name": "Kishan Ji Company",
//                       "date": "25-05-2026",
//                       "refNo": "RN/20",
//                       "amount": 2,
//                       "discount": 0,
//                     },
//                   ],
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(14),

//         child: Column(
//           children: [
//             /// FILTERS
//             Row(
//               children: [
//                 Expanded(
//                   child: _dateBox("From Date", fromDate, () => pickDate(true)),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: _dateBox("To Date", toDate, () => pickDate(false)),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 15),

//             /// COMPANY CARD
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppColors.primary,
//                     AppColors.primary.withOpacity(.75),
//                   ],
//                 ),
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "ABCD ENTERPRISES",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 19,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     "GSTIN : 22AAAAA0000A1Z5",
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                   const SizedBox(height: 10),
//                   Text(
//                     "Period : ${formatDate(fromDate)} - ${formatDate(toDate)}",
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 15),

//             summaryCard(
//               title: "Net Balance",
//               value: "₹ ${netBalance.toStringAsFixed(2)}",
//               color: Colors.orange,
//               icon: Icons.account_balance_wallet,
//             ),

//             const SizedBox(height: 10),

//             Row(
//               children: [
//                 Expanded(
//                   child: summaryCard(
//                     title: "Income",
//                     value: "₹ ${totalIncome.toStringAsFixed(2)}",
//                     color: Colors.green,
//                     icon: Icons.arrow_downward,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: summaryCard(
//                     title: "Expense",
//                     value: "₹ ${totalExpenses.toStringAsFixed(2)}",
//                     color: Colors.red,
//                     icon: Icons.arrow_upward,
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 10),

//             Row(
//               children: [
//                 Expanded(
//                   child: summaryCard(
//                     title: "Receipt",
//                     value: "₹ ${totalReceipt.toStringAsFixed(2)}",
//                     color: Colors.blue,
//                     icon: Icons.people,
//                   ),
//                 ),
//                 const SizedBox(width: 10),
//                 Expanded(
//                   child: summaryCard(
//                     title: "Discount",
//                     value: "₹ ${totalDiscount.toStringAsFixed(2)}",
//                     color: Colors.deepPurple,
//                     icon: Icons.discount,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),

//             /// Income Details
//             Card(
//               child: ExpansionTile(
//                 initiallyExpanded: true,
//                 title: const Text(
//                   "Income Details",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 children: const [
//                   ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.green,
//                       child: Icon(Icons.currency_rupee, color: Colors.white),
//                     ),
//                     title: Text("Diary"),
//                     subtitle: Text("03-06-2026 • Book • Qty 1"),
//                     trailing: Text(
//                       "₹66",
//                       style: TextStyle(
//                         color: Colors.green,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             /// Expense Details
//             Card(
//               child: ExpansionTile(
//                 title: const Text(
//                   "Expense Details",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 children: const [
//                   ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: Colors.red,
//                       child: Icon(Icons.money_off, color: Colors.white),
//                     ),
//                     title: Text("Cold Drink"),
//                     subtitle: Text("03-06-2026 • Coffee • Qty 1"),
//                     trailing: Text(
//                       "₹40",
//                       style: TextStyle(
//                         color: Colors.red,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             /// Receipt Details
//             Card(
//               child: ExpansionTile(
//                 title: const Text(
//                   "Party Receipt Details",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 12,
//                       vertical: 6,
//                     ),
//                     child: SizedBox(
//                       height: 40,
//                       child: TextField(
//                         style: const TextStyle(fontSize: 13),
//                         decoration: InputDecoration(
//                           hintText: "Search Party",
//                           hintStyle: const TextStyle(fontSize: 13),
//                           prefixIcon: const Icon(Icons.search, size: 18),
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 10,
//                             vertical: 0,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(10),
//                             borderSide: BorderSide(color: Colors.grey.shade300),
//                           ),
//                         ),
//                         onChanged: (value) {
//                           setState(() {
//                             receiptSearch = value.toLowerCase();
//                           });
//                         },
//                       ),
//                     ),
//                   ),
//                   ...receiptList
//                       .where(
//                         (item) => item["name"]
//                             .toString()
//                             .toLowerCase()
//                             .contains(receiptSearch),
//                       )
//                       .map(
//                         (item) => receiptTile(
//                           name: item["name"],
//                           amount: item["amount"],
//                           discount: item["discount"],
//                           refNo: item["refNo"],
//                         ),
//                       )
//                       .toList(),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _dateBox(String label, DateTime date, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               label,
//               style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
//             ),
//             const SizedBox(height: 4),
//             Row(
//               children: [
//                 Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
//                 const SizedBox(width: 6),
//                 Expanded(
//                   child: Text(
//                     DateFormat("dd-MM-yyyy").format(date),
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w600,
//                       fontSize: 13,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget filterBox(String title, String value, VoidCallback onTap) {
//     return InkWell(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: Colors.grey.shade300),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               title,
//               style: const TextStyle(color: Colors.grey, fontSize: 12),
//             ),
//             const SizedBox(height: 6),
//             Row(
//               children: [
//                 const Icon(Icons.calendar_month, size: 18),
//                 const SizedBox(width: 6),
//                 Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildSection({
//     required String title,
//     required Color color,
//     required List<Map<String, dynamic>> data,
//     required double total,
//     required IconData icon,
//   }) {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(14),
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 Icon(icon, color: color),
//                 const SizedBox(width: 8),
//                 Text(
//                   title,
//                   style: TextStyle(
//                     color: color,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//               ],
//             ),

//             const Divider(height: 25),

//             ...data.map(
//               (e) => Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8),
//                 child: Row(
//                   children: [
//                     Expanded(child: Text(e["name"])),
//                     Text(
//                       "₹ ${e["amount"].toStringAsFixed(2)}",
//                       style: const TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                   ],
//                 ),
//               ),
//             ),

//             const Divider(),

//             Row(
//               children: [
//                 Expanded(
//                   child: Text(
//                     "Total $title",
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//                 Text(
//                   "₹ ${total.toStringAsFixed(2)}",
//                   style: TextStyle(
//                     color: color,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget summaryRow(String title, double amount, Color color) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 10),
//       child: Row(
//         children: [
//           Expanded(child: Text(title)),
//           Text(
//             "₹ ${amount.toStringAsFixed(2)}",
//             style: TextStyle(color: color, fontWeight: FontWeight.bold),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget summaryCard({
//     required String title,
//     required String value,
//     required Color color,
//     required IconData icon,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
//       ),
//       child: Row(
//         children: [
//           CircleAvatar(
//             backgroundColor: color.withOpacity(.1),
//             child: Icon(icon, color: color),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(title),
//                 const SizedBox(height: 4),
//                 Text(
//                   value,
//                   style: TextStyle(
//                     color: color,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 18,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget receiptTile({
//     required String name,
//     required double amount,
//     required double discount,
//     required String refNo,
//   }) {
//     return ListTile(
//       leading: const CircleAvatar(child: Icon(Icons.person)),
//       title: Text(name),
//       subtitle: Text("Ref No : $refNo"),
//       trailing: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             "₹$amount",
//             style: const TextStyle(
//               color: Colors.blue,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           Text("Disc ₹$discount", style: const TextStyle(fontSize: 11)),
//         ],
//       ),
//     );
//   }
// }
