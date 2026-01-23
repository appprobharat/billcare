import 'dart:io'; // File क्लास के लिए
import 'dart:typed_data'; // Uint8List के लिए
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart'; // नया इम्पोर्ट
import 'package:billcare/api/api_service.dart'; // मौजूदा इम्पोर्ट

class PdfService {
  // --- Utility Functions ---

  // Number to Words function (जैसा है वैसा ही)
  static String numberToWords(double number) {
    if (number == 0) {
      return "Rupees Zero Only";
    }

    final int integerPart = number.toInt();
    final int decimalPart = ((number - integerPart) * 100).round();

    String words = '';

    String convertHundreds(int n) {
      final List<String> units = [
        '',
        'One',
        'Two',
        'Three',
        'Four',
        'Five',
        'Six',
        'Seven',
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
      final List<String> tens = [
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
      if (n > 0) {
        result += units[n];
      }
      return result.trim();
    }

    if (integerPart >= 10000000) {
      words += convertHundreds(integerPart ~/ 10000000) + ' Crore ';
      int remaining = integerPart % 10000000;
      if (remaining > 0) {
        words += numberToWords(remaining.toDouble());
      }
    } else if (integerPart >= 100000) {
      words += convertHundreds(integerPart ~/ 100000) + ' Lakh ';
      int remaining = integerPart % 100000;
      if (remaining > 0) {
        words += numberToWords(remaining.toDouble());
      }
    } else if (integerPart >= 1000) {
      words += convertHundreds(integerPart ~/ 1000) + ' Thousand ';
      int remaining = integerPart % 1000;
      if (remaining > 0) {
        words += numberToWords(remaining.toDouble());
      }
    } else {
      words = convertHundreds(integerPart);
    }

    String finalWords = "Rupees $words Only";

    if (decimalPart > 0) {
      finalWords += ' and ';
      finalWords +=
          'Paise ${convertHundreds(decimalPart)} Only'; // Decimal part को भी words में कन्वर्ट करें
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

  static Future<String> generateAndSavePdf({
    required String authToken,
    required Map<String, dynamic> sale,
  }) async {
    try {
      if (authToken.isEmpty) {
        throw Exception("Authentication token is missing.");
      }

      final int saleId = sale['id'] as int? ?? 0;
      if (saleId == 0) {
        throw Exception("Invalid Sale ID received.");
      }

      // 1. API से Sale Details Fetch करें
      final Map<String, dynamic> fullSaleData =
          await ApiService.fetchPrintSaleDetails(authToken, saleId);

      // 2. PDF Document Generate करें
      final Uint8List pdfBytes = await _generatePdfDocument(fullSaleData);

      // 3. File Path निर्धारित करें
      final baseDirectory = await getApplicationDocumentsDirectory();
      final invoicePathSegment =
          fullSaleData['RefNo'] ?? 'Invoice_Temp'; // जैसे SVD/24-25/43

      // Path को /data/user/0/.../app_flutter/Invoice_SVD/24-25/43.pdf में तोड़ना
      // फ़ाइल का नाम और डायरेक्टरी पाथ अलग करें
      final List<String> pathParts = invoicePathSegment.split('/');
      final String fileName =
          pathParts.last; // '43.pdf' या जो भी आख़िरी हिस्सा है
      final String directoryPath = pathParts
          .sublist(0, pathParts.length - 1)
          .join('/'); // 'SVD/24-25'

      // पूरी डायरेक्टरी पाथ बनाएं
      final Directory finalDirectory = Directory(
        '${baseDirectory.path}/$directoryPath',
      );

  
      if (!await finalDirectory.exists()) {
        await finalDirectory.create(recursive: true);
        print("Created Directory: ${finalDirectory.path}");
      }
      final filePath =
          '${finalDirectory.path}/$fileName.pdf'; 
      final file = File(filePath);

    
      await file.writeAsBytes(pdfBytes);

    
      return filePath;
    } catch (e) {
      print("Error generating or saving PDF: $e");
      return '';
    }
  }

  static Future<void> printDocument({
    required String authToken,
    required Map<String, dynamic> sale,
  }) async {
    if (authToken.isEmpty) {
      throw Exception("Authentication token is missing.");
    }

    final int saleId = sale['id'] as int? ?? 0;
    if (saleId == 0) {
      throw Exception("Invalid Sale ID received.");
    }

    final Map<String, dynamic> fullSaleData =
        await ApiService.fetchPrintSaleDetails(authToken, saleId);

    // PDF जनरेट करें
    final Uint8List pdfBytes = await _generatePdfDocument(fullSaleData);

    // Printing.layoutPdf का उपयोग करके प्रिंट करें
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }


  static Future<Uint8List> _generatePdfDocument(
    Map<String, dynamic> fullSaleData,
  ) async {
    final pdf = pw.Document();

    const String companyName = 'BillCare';
    const String companyAddress = 'Faridabad Haryana';
    const String signatureText = 'Authorized Signatory';
    const String termsAndConditions =
        'Thank you for your business. All goods once sold will not be taken back.';

    final String invoiceNumber = fullSaleData['RefNo'] ?? 'N/A';
    final String date = fullSaleData['Date'] ?? 'N/A';
    final String clientName = fullSaleData['Name'] ?? 'N/A';
    final String contact = fullSaleData['ContactNo']?.toString() ?? 'N/A';
    final String clientGstin = fullSaleData['GSTIN'] ?? 'N/A';

    final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
      fullSaleData['items'] ?? [],
    );

    double subTotalAmount = 0.0;
    double totalDiscount = 0.0;
    double totalTax = 0.0;
    double grandTotalAmount =
        double.tryParse(fullSaleData['GrandTotalAmt']?.toString() ?? '0') ??
        0.0;

    for (var item in items) {
      final double salePrice =
          double.tryParse(item['SalePrice']?.toString() ?? '0') ?? 0.0;
      final double quantity =
          double.tryParse(item['Quantity']?.toString() ?? '0') ?? 0.0;
      final double discount =
          double.tryParse(item['Discount']?.toString() ?? '0') ?? 0.0;
      final double gstAmount =
          double.tryParse(item['GSTAmt']?.toString() ?? '0') ?? 0.0;

      subTotalAmount += (salePrice * quantity);
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
                  final double salePrice =
                      double.tryParse(item['SalePrice']?.toString() ?? '0') ??
                      0.0;
                  final double quantity =
                      double.tryParse(item['Quantity']?.toString() ?? '0') ??
                      0.0;
                  final double totalAmountForItem = salePrice * quantity;
                  return [
                    (entry.key + 1).toString(),
                    item['ItemName'] ?? 'N/A',
                    item['Quantity']?.toString() ?? '0',
                    item['Unit'] ?? 'N/A',
                    salePrice.toStringAsFixed(2),
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
