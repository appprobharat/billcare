import 'dart:io'; 
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart'; // नया इम्पोर्ट
import 'package:billcare/api/api_service.dart'; // मौजूदा इम्पोर्ट

class PdfService {

 static String numberToWords(double number) {
    if (number == 0) return "Rupees Zero Only";

    final int integerPart = number.toInt();
    final int decimalPart = ((number - integerPart) * 100).round();

    String convertHundreds(int n) {
      final units = [
        '',
        'One',
        'Two',
        'Three',
        'Four',
        'Five',
        'Six',
        'Seven',
        'Eight',
        'Nine',
        'Ten',
        'Eleven',
        'Twelve',
        'Thirteen',
        'Fourteen',
        'Fifteen',
        'Sixteen',
        'Seventeen',
        'Eighteen',
        'Nineteen',
      ];
      final tens = [
        '',
        '',
        'Twenty',
        'Thirty',
        'Forty',
        'Fifty',
        'Sixty',
        'Seventy',
        'Eighty',
        'Ninety',
      ];

      String result = '';
      if (n >= 100) {
        result += '${units[n ~/ 100]} Hundred ';
        n %= 100;
      }
      if (n >= 20) {
        result += '${tens[n ~/ 10]} ';
        n %= 10;
      }
      if (n > 0) result += units[n];
      return result.trim();
    }

    String words = '';

    if (integerPart >= 10000000) {
      words += '${convertHundreds(integerPart ~/ 10000000)} Crore ';
      words += convertHundreds(integerPart % 10000000);
    } else if (integerPart >= 100000) {
      words += '${convertHundreds(integerPart ~/ 100000)} Lakh ';
      words += convertHundreds(integerPart % 100000);
    } else if (integerPart >= 1000) {
      words += '${convertHundreds(integerPart ~/ 1000)} Thousand ';
      words += convertHundreds(integerPart % 1000);
    } else {
      words = convertHundreds(integerPart);
    }

    String finalWords = 'Rupees $words Only';

    if (decimalPart > 0) {
      finalWords += ' and Paise ${convertHundreds(decimalPart)} Only';
    }

    return finalWords.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // buildTotalRow function (जैसा है वैसा ही)
  static pw.Widget buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          'Rs ${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // --- Main Functions ---

    static Future<String?> generateAndSavePdf({
    required Map<String, dynamic> purchase, required String authToken,
  }) async {
    try {
      final int purchaseId = purchase['id'] ?? 0;
      if (purchaseId == 0) return null;

      final data =
          await ApiService.fetchPrintPurchaseDetails(purchaseId);
      if (data == null || data.isEmpty) return null;

      final pdfBytes = await _generatePdfDocument(data);

      final baseDir = await getApplicationDocumentsDirectory();
      final refNo = data['RefNo'] ?? 'Invoice';

      final parts = refNo.split('/');
      final rawName = parts.last;
      final safeName =
          rawName.endsWith('.pdf') ? rawName : '$rawName.pdf';

      final dirPath =
          '${baseDir.path}/${parts.take(parts.length - 1).join('/')}';
      final dir = Directory(dirPath);
      if (!await dir.exists()) await dir.create(recursive: true);

      final filePath = '${dir.path}/$safeName';
      await File(filePath).writeAsBytes(pdfBytes);

      return filePath;
    } catch (e) {
      if (kDebugMode) debugPrint('PDF save error: $e');
      return null;
    }
  }



  static Future<void> printDocument({
    required String authToken,
    required Map<String, dynamic> purchase,
  }) async {
    if (authToken.isEmpty) {
      throw Exception("Authentication token is missing.");
    }

    final int purchaseId = purchase['id'] as int? ?? 0;
    if (purchaseId == 0) {
      throw Exception("Invalid Purchase ID received.");
    }

    final Map<String, dynamic>? fullPurchaseData =
         await ApiService.fetchPrintPurchaseDetails(purchaseId);

    // PDF जनरेट करें
    final Uint8List pdfBytes = await _generatePdfDocument(fullPurchaseData!);

    // Printing.layoutPdf का उपयोग करके प्रिंट करें
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }


  static Future<Uint8List> _generatePdfDocument(
    Map<String, dynamic> fullPurchaseData,
  ) async {
    final pdf = pw.Document();

    const String companyName = 'BillCare';
    const String companyAddress = 'Faridabad Haryana';
    const String signatureText = 'Authorized Signatory';
    const String termsAndConditions =
        'Thank you for your business. All goods once sold will not be taken back.';

    final String invoiceNumber = fullPurchaseData['RefNo'] ?? 'N/A';
    final String date = fullPurchaseData['Date'] ?? 'N/A';
    final String clientName = fullPurchaseData['Name'] ?? 'N/A';
    final String contact = fullPurchaseData['ContactNo']?.toString() ?? 'N/A';
    final String clientGstin = fullPurchaseData['GSTIN'] ?? 'N/A';

    final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
      fullPurchaseData['items'] ?? [],
    );

    double subTotalAmount = 0.0;
    double totalDiscount = 0.0;
    double totalTax = 0.0;
    double grandTotalAmount =
        double.tryParse(fullPurchaseData['GrandTotalAmt']?.toString() ?? '0') ??
        0.0;

    for (var item in items) {
      final double purchasePrice =
          double.tryParse(item['PurchasePrice']?.toString() ?? '0') ?? 0.0;
      final double quantity =
          double.tryParse(item['Quantity']?.toString() ?? '0') ?? 0.0;
      final double discount =
          double.tryParse(item['Discount']?.toString() ?? '0') ?? 0.0;
      final double gstAmount =
          double.tryParse(item['GSTAmt']?.toString() ?? '0') ?? 0.0;

      subTotalAmount += (purchasePrice * quantity);
      totalTax += gstAmount;
      totalDiscount += discount;
    }

    final double receivedAmount = 0.0;
    final double balanceAmount = grandTotalAmount - receivedAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        companyName,
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        companyAddress,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Text(
                    'Tax Invoice',
                    style: pw.TextStyle(
                      fontSize: 30,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey700,
                    ),
                  ),
                  pw.SizedBox(width: 80),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Bill To:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text(clientName),
                            pw.Text('Contact No: $contact'),
                            pw.Text('GSTIN: $clientGstin'),
                          ],
                        ),
                      ),
                    ),
                    // VerticalDivider is not available in pw.Table. Use Box and Container instead.
                    pw.Container(
                      width: 1,
                      height: 60, // A fixed height for the divider
                      color: PdfColors.grey500,
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Invoice Details:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text('No: $invoiceNumber'),
                            pw.Text('Date: $date'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey500),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.5),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.5),
                },
                headers: <String>[
                  '#',
                  'Item Name',
                  'Qty',
                  'Unit',
                  'Rate',
                  'Amount',
                ],
                data: items.asMap().entries.map((entry) {
                  final item = entry.value;
                  final double purchasePrice =
                      double.tryParse(item['PurchasePrice']?.toString() ?? '0') ??
                      0.0;
                  final double quantity =
                      double.tryParse(item['Quantity']?.toString() ?? '0') ??
                      0.0;
                  final double totalAmountForItem = purchasePrice * quantity;
                  return [
                    (entry.key + 1).toString(),
                    item['ItemName'] ?? 'N/A',
                    item['Quantity']?.toString() ?? '0',
                    item['Unit'] ?? 'N/A',
                    purchasePrice.toStringAsFixed(2),
                    totalAmountForItem.toStringAsFixed(2),
                  ];
                }).toList(),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Invoice Amount In Words:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          PdfService.numberToWords(grandTotalAmount),
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey500),
                      ),
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Column(
                        children: [
                          PdfService.buildTotalRow(
                            'Sub Total :',
                            subTotalAmount,
                          ),
                          PdfService.buildTotalRow('Discount :', totalDiscount),
                          PdfService.buildTotalRow('Tax :', totalTax),
                          PdfService.buildTotalRow(
                            'Grand Total :',
                            grandTotalAmount,
                            isBold: true,
                          ),
                          PdfService.buildTotalRow(
                            'Received :',
                            receivedAmount,
                          ),
                          PdfService.buildTotalRow('Balance :', balanceAmount),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey500),
                ),
                padding: const pw.EdgeInsets.all(5),
                width: double.infinity,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Terms And Conditions:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(termsAndConditions),
                  ],
                ),
              ),
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'For $companyName:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Container(
                      height: 50,
                      width: 150,
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Center(child: pw.Text(signatureText)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
