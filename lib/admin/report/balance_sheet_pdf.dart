// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:printing/printing.dart';

// class BalanceSheetPdf {
//   static Future<void> generate({
//     required String companyName,
//     required String fromDate,
//     required String toDate,
//     required double totalIncome,
//     required double totalExpense,
//     required double totalReceipt,
//     required double totalDiscount,
//     required List<Map<String, dynamic>> incomeList,
//     required List<Map<String, dynamic>> expenseList,
//     required List<Map<String, dynamic>> receiptList,
//   }) async {
//     final pdf = pw.Document();

//     pdf.addPage(
//       pw.MultiPage(
//         pageFormat: PdfPageFormat.a4,
//         build: (context) => [
//           pw.Center(
//             child: pw.Text(
//               companyName,
//               style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
//             ),
//           ),

//           pw.SizedBox(height: 10),

//           pw.Text(
//             "Balance Sheet Report",
//             style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//           ),

//           pw.Text("From : $fromDate"),
//           pw.Text("To : $toDate"),

//           pw.SizedBox(height: 15),

//           /// SUMMARY
//           pw.Container(
//             padding: const pw.EdgeInsets.all(10),
//             decoration: pw.BoxDecoration(border: pw.Border.all()),
//             child: pw.Column(
//               children: [
//                 _summaryRow("Income", totalIncome),
//                 _summaryRow("Expense", totalExpense),
//                 _summaryRow("Receipt", totalReceipt),
//                 _summaryRow("Discount", totalDiscount),
//                 pw.Divider(),
//                 _summaryRow(
//                   "Net Balance",
//                   totalIncome + totalReceipt - totalExpense - totalDiscount,
//                 ),
//               ],
//             ),
//           ),

//           pw.SizedBox(height: 20),

//           /// INCOME TABLE
//           pw.Text(
//             "Income Details",
//             style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//           ),

//           pw.Table.fromTextArray(
//             headers: [
//               "S.No",
//               "Date",
//               "Category",
//               "Item",
//               "Qty",
//               "Price",
//               "Amount",
//             ],
//             data: List.generate(
//               incomeList.length,
//               (index) => [
//                 "${index + 1}",
//                 incomeList[index]["date"],
//                 incomeList[index]["category"],
//                 incomeList[index]["item"],
//                 "${incomeList[index]["qty"]}",
//                 "${incomeList[index]["price"]}",
//                 "${incomeList[index]["amount"]}",
//               ],
//             ),
//           ),

//           pw.SizedBox(height: 20),

//           /// EXPENSE TABLE
//           pw.Text(
//             "Expense Details",
//             style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//           ),

//           pw.Table.fromTextArray(
//             headers: [
//               "S.No",
//               "Date",
//               "Category",
//               "Item",
//               "Qty",
//               "Price",
//               "Amount",
//             ],
//             data: List.generate(
//               expenseList.length,
//               (index) => [
//                 "${index + 1}",
//                 expenseList[index]["date"],
//                 expenseList[index]["category"],
//                 expenseList[index]["item"],
//                 "${expenseList[index]["qty"]}",
//                 "${expenseList[index]["price"]}",
//                 "${expenseList[index]["amount"]}",
//               ],
//             ),
//           ),

//           pw.SizedBox(height: 20),

//           /// PARTY RECEIPT TABLE
//           pw.Text(
//             "Party Receipt Details",
//             style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
//           ),

//           pw.Table.fromTextArray(
//             headers: ["S.No", "Party", "Date", "Ref No", "Amount", "Discount"],
//             data: List.generate(
//               receiptList.length,
//               (index) => [
//                 "${index + 1}",
//                 receiptList[index]["name"],
//                 receiptList[index]["date"],
//                 receiptList[index]["refNo"],
//                 "${receiptList[index]["amount"]}",
//                 "${receiptList[index]["discount"]}",
//               ],
//             ),
//           ),
//         ],
//       ),
//     );

//     await Printing.layoutPdf(
//       onLayout: (PdfPageFormat format) async => pdf.save(),
//     );
//   }

//   static pw.Widget _summaryRow(String title, double amount) {
//     return pw.Padding(
//       padding: const pw.EdgeInsets.symmetric(vertical: 3),
//       child: pw.Row(
//         children: [
//           pw.Expanded(child: pw.Text(title)),
//           pw.Text("Rs. ${amount.toStringAsFixed(2)}"),
//         ],
//       ),
//     );
//   }
// }
