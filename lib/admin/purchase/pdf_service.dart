import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:billcare/api/api_service.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;

class PdfService {
  static const bool isInterState = true;
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
    required Map<String, dynamic> purchase,
    required String authToken,
  }) async {
    try {
      final int purchaseId = purchase['id'] ?? 0;
      if (purchaseId == 0) return null;

      final data = await ApiService.fetchPrintPurchaseDetails(purchaseId);
      if (data == null || data.isEmpty) return null;

      final pdfBytes = await _generatePdfDocument(data);

      final baseDir = await getApplicationDocumentsDirectory();
      final refNo = data['RefNo'] ?? 'Invoice';

      final parts = refNo.split('/');
      final rawName = parts.last;
      final safeName = rawName.endsWith('.pdf') ? rawName : '$rawName.pdf';

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
    try {
      final int purchaseId = purchase['id'] as int? ?? 0;

      if (purchaseId == 0) {
        throw Exception("Invalid Purchase ID received.");
      }

      final Map<String, dynamic>? fullPurchaseData =
          await ApiService.fetchPrintPurchaseDetails(purchaseId);

      if (fullPurchaseData == null || fullPurchaseData.isEmpty) {
        throw Exception("Purchase details not found.");
      }

      final Uint8List pdfBytes = await _generatePdfDocument(fullPurchaseData);

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error generating PDF: $e");
      }
      rethrow;
    }
  }

  static Future<Uint8List> _generatePdfDocument(
    Map<String, dynamic> fullSaleData,
  ) async {
    final pdf = pw.Document();
  
    final company = Map<String, dynamic>.from(fullSaleData['Company'] ?? {});

    // Backend se logo URL
    final logoUrl = company['Logo']?.toString().trim() ?? '';

    pw.MemoryImage? logoImage;

    if (logoUrl.isNotEmpty && logoUrl != 'null') {
      try {
        print('LOGO URL => $logoUrl');

        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(logoUrl));
        final response = await request.close();

        print('LOGO STATUS => ${response.statusCode}');
        print('LOGO CONTENT TYPE => ${response.headers.contentType}');

        final bytes = await response.fold<List<int>>(<int>[], (
          previous,
          element,
        ) {
          previous.addAll(element);
          return previous;
        });

        client.close();

        if (response.statusCode == 200 && bytes.isNotEmpty) {
          final contentType = response.headers.contentType?.mimeType ?? '';

          if (contentType.startsWith('image/')) {
            logoImage = pw.MemoryImage(Uint8List.fromList(bytes));

            print('LOGO LOADED SUCCESSFULLY');
          } else {
            print('LOGO IS NOT AN IMAGE => $contentType');
          }
        } else {
          print('LOGO DOWNLOAD FAILED');
        }
      } catch (e) {
        print('LOGO IMAGE ERROR => $e');
      }
    }
    final invoiceNo = fullSaleData['RefNo']?.toString() ?? '-';
    final date = fullSaleData['Date']?.toString() ?? '-';


    final companyName = company['Name']?.toString() ?? '-';
    final companyContact = company['ContactNo']?.toString() ?? '-';
    final companyGSTIN = company['GSTIN']?.toString() ?? '-';
    final companyAddress = company['Address']?.toString() ?? '-';
    final companyState = company['State']?.toString() ?? '-';
    final qrUrl = company['QR']?.toString().trim() ?? '';

    pw.MemoryImage? qrImage;

    if (qrUrl.isNotEmpty && qrUrl != 'null') {
      try {
        print('QR URL => $qrUrl');

        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(qrUrl));
        final response = await request.close();

        print('QR STATUS => ${response.statusCode}');
        print('QR CONTENT TYPE => ${response.headers.contentType}');

        final bytes = await response.fold<List<int>>(<int>[], (
          previous,
          element,
        ) {
          previous.addAll(element);
          return previous;
        });

        print('QR BYTES LENGTH => ${bytes.length}');

        if (response.statusCode == 200 && bytes.isNotEmpty) {
          qrImage = pw.MemoryImage(Uint8List.fromList(bytes));

          print('QR IMAGE LOADED SUCCESSFULLY');
        } else {
          print('QR IMAGE NOT VALID');
        }

        client.close();
      } catch (e) {
        print('QR IMAGE ERROR => $e');
      }
    }
    final bankName = company['Bank']?.toString() ?? '-';
    final accountName = company['AccName']?.toString() ?? '-';
    final accountNo = company['AccNo']?.toString() ?? '-';
    final ifsc = company['IFSC']?.toString() ?? '-';
    final upiId = company['UpiId']?.toString() ?? '-';
    final rawTerms = company['Terms']?.toString() ?? '';

    // Client details
    final client = Map<String, dynamic>.from(fullSaleData['Client'] ?? {});

    final customerName = client['Name']?.toString() ?? '-';
    final customerContact = client['ContactNo']?.toString() ?? '-';
    final customerGSTIN = client['GSTIN']?.toString() ?? '-';
    final customerAddress = client['Address']?.toString() ?? '-';
    final customerState = client['State']?.toString() ?? '-';

    final grandTotal =
        double.tryParse(fullSaleData['GrandTotalAmt']?.toString() ?? '0') ?? 0;

    final List<Map<String, dynamic>> items =
        (fullSaleData['items'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ??
        [];

    double subTotal = 0;
    double taxableTotal = 0;
    double discount = 0;
    double gstTotal = 0;

    for (final item in items) {
      final rate =
          double.tryParse(item['PurchasePrice']?.toString() ?? '0') ?? 0;

      final qty = double.tryParse(item['Quantity']?.toString() ?? '0') ?? 0;

      final disc = double.tryParse(item['Discount']?.toString() ?? '0') ?? 0;

      final taxable = (rate * qty) - disc;

      final cgstRate = double.tryParse(item['CGST']?.toString() ?? '0') ?? 0;

      final sgstRate = double.tryParse(item['SGST']?.toString() ?? '0') ?? 0;

      final igstRate = double.tryParse(item['IGST']?.toString() ?? '0') ?? 0;

      final cgstAmount = taxable * cgstRate / 100;
      final sgstAmount = taxable * sgstRate / 100;
      final igstAmount = taxable * igstRate / 100;

      final gstAmt = cgstAmount + sgstAmount + igstAmount;

      subTotal += rate * qty;
      taxableTotal += taxable;
      discount += disc;
      gstTotal += gstAmt;
    }
    final List<Map<String, dynamic>> itemList = items
        .cast<Map<String, dynamic>>();

    final Map<String, Map<String, double>> taxSummary = {};

    for (final item in items) {
      final hsn = item['HSNCode']?.toString() ?? '-';

      final rate =
          double.tryParse(item['PurchasePrice']?.toString() ?? '0') ?? 0;

      final qty = double.tryParse(item['Quantity']?.toString() ?? '0') ?? 0;

      final discountAmount =
          double.tryParse(item['Discount']?.toString() ?? '0') ?? 0;

      final cgstRate = double.tryParse(item['CGST']?.toString() ?? '0') ?? 0;

      final sgstRate = double.tryParse(item['SGST']?.toString() ?? '0') ?? 0;

      final igstRate = double.tryParse(item['IGST']?.toString() ?? '0') ?? 0;

      final apiTaxable = double.tryParse(item['TaxableAmt']?.toString() ?? '');

      final taxableValue = (apiTaxable == null || apiTaxable == 0)
          ? ((rate * qty) - discountAmount)
          : apiTaxable;
      final cgstAmount = taxableValue * cgstRate / 100;
      final sgstAmount = taxableValue * sgstRate / 100;
      final igstAmount = taxableValue * igstRate / 100;

      final totalTax = cgstAmount + sgstAmount + igstAmount;
      if (!taxSummary.containsKey(hsn)) {
        taxSummary[hsn] = {
          'taxable': 0,
          'cgst': 0,
          'sgst': 0,
          'igst': 0,
          'totalTax': 0,
        };
      }

      taxSummary[hsn]!['taxable'] = taxSummary[hsn]!['taxable']! + taxableValue;

      taxSummary[hsn]!['cgst'] = taxSummary[hsn]!['cgst']! + cgstAmount;

      taxSummary[hsn]!['sgst'] = taxSummary[hsn]!['sgst']! + sgstAmount;

      taxSummary[hsn]!['igst'] = taxSummary[hsn]!['igst']! + igstAmount;

      taxSummary[hsn]!['totalTax'] = taxSummary[hsn]!['totalTax']! + totalTax;
    }
    const primary = PdfColor.fromInt(0xff173F5F);
    const blue = PdfColor.fromInt(0xff20639B);
    const lightBlue = PdfColor.fromInt(0xffEAF3F8);

    const border = PdfColor.fromInt(0xffC9D2D9);
    List<pw.Widget> buildTermsWidgets(String htmlData) {
      final document = html_parser.parse(htmlData);
      final body = document.body;

      if (body == null) {
        return [];
      }

      final widgets = <pw.Widget>[];

      for (final node in body.nodes) {
        // Normal text
        if (node.nodeType == 3) {
          final text = node.text?.trim() ?? '';

          if (text.isNotEmpty) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(text, style: const pw.TextStyle(fontSize: 7)),
              ),
            );
          }

          continue;
        }

        // HTML Element
        if (node is! html_dom.Element) {
          continue;
        }

        final tag = node.localName;

        // Paragraph
        if (tag == 'p') {
          final text = node.text.trim();

          if (text.isNotEmpty) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(text, style: const pw.TextStyle(fontSize: 7)),
              ),
            );
          }
        }
        // Line break
        else if (tag == 'br') {
          widgets.add(pw.SizedBox(height: 3));
        }
        // Unordered list
        else if (tag == 'ul') {
          for (final li in node.children) {
            if (li.localName != 'li') continue;

            final text = li.text.trim();

            if (text.isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 8,
                        child: pw.Text(
                          '•',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          text,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }
        }
        // Ordered list
        else if (tag == 'ol') {
          int number = 1;

          for (final li in node.children) {
            if (li.localName != 'li') continue;

            final text = li.text.trim();

            if (text.isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.SizedBox(
                        width: 14,
                        child: pw.Text(
                          '$number.',
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          text,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                      ),
                    ],
                  ),
                ),
              );

              number++;
            }
          }
        }
        // Bold / strong text
        else if (tag == 'b' || tag == 'strong') {
          final text = node.text.trim();

          if (text.isNotEmpty) {
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: pw.Text(
                  text,
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            );
          }
        }
      }

      return widgets;
    }

    pw.Widget itemText(
      String text, {
      pw.Alignment alignment = pw.Alignment.center,
      bool bold = false,
    }) {
      return pw.Container(
        height: 23,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        alignment: alignment,
        child: pw.Text(
          text,
          maxLines: 2,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      );
    }

    pw.Widget headerCell(String text) {
      return pw.Container(
        height: 23,
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      );
    }

    pw.Widget buildItemTable(
      List<Map<String, dynamic>> currentItems,
      int startingSerial,
    ) {
      return pw.Table(
        border: pw.TableBorder(
          left: pw.BorderSide(color: border, width: 0.6),
          right: pw.BorderSide(color: border, width: 0.6),
          top: pw.BorderSide(color: border, width: 0.6),
          bottom: pw.BorderSide(color: border, width: 0.6),
          verticalInside: pw.BorderSide(color: border, width: 0.6),
          horizontalInside: pw.BorderSide(color: border, width: 0.6),
        ),

        columnWidths: const {
          0: pw.FixedColumnWidth(22),
          1: pw.FlexColumnWidth(3),
          2: pw.FixedColumnWidth(45),
          3: pw.FixedColumnWidth(32),
          4: pw.FixedColumnWidth(40),
          5: pw.FixedColumnWidth(50),
          6: pw.FixedColumnWidth(58),
          7: pw.FixedColumnWidth(35),
          8: pw.FixedColumnWidth(45),
          9: pw.FixedColumnWidth(45),
          10: pw.FixedColumnWidth(60),
        },

        children: [
          // =========================
          // TABLE HEADER
          // =========================
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: primary),
            children: [
              headerCell('#'),
              headerCell('DESCRIPTION'),
              headerCell('HSN/SAC'),
              headerCell('QTY'),
              headerCell('UNIT'),
              headerCell('RATE'),
              headerCell('TAXABLE'),
              headerCell('GST'),
              if (!isInterState) headerCell('CGST'),
              if (!isInterState) headerCell('SGST'),
              if (isInterState) headerCell('IGST'),
              headerCell('TOTAL'),
            ],
          ),

          // =========================
          // ITEMS
          // =========================
          ...List.generate(currentItems.length, (index) {
            final item = currentItems[index];

            final rate =
                double.tryParse(item['PurchasePrice']?.toString() ?? '0') ?? 0;

            final qty =
                double.tryParse(item['Quantity']?.toString() ?? '0') ?? 0;

            final disc =
                double.tryParse(item['Discount']?.toString() ?? '0') ?? 0;

            final apiTaxable = double.tryParse(
              item['TaxableAmt']?.toString() ?? '',
            );

            final taxable = (apiTaxable == null || apiTaxable == 0)
                ? ((rate * qty) - disc)
                : apiTaxable;
            final cgstValue = item['CGST'];
            final sgstValue = item['SGST'];
            final igstValue = item['IGST'];

            final double cgst = cgstValue is num
                ? cgstValue.toDouble()
                : double.tryParse(cgstValue?.toString() ?? '0') ?? 0;

            final double sgst = sgstValue is num
                ? sgstValue.toDouble()
                : double.tryParse(sgstValue?.toString() ?? '0') ?? 0;

            final double cgstRate = cgstValue is num
                ? cgstValue.toDouble()
                : double.tryParse(cgstValue?.toString() ?? '0') ?? 0;

            final double sgstRate = sgstValue is num
                ? sgstValue.toDouble()
                : double.tryParse(sgstValue?.toString() ?? '0') ?? 0;

            final double igstRate = igstValue is num
                ? igstValue.toDouble()
                : double.tryParse(igstValue?.toString() ?? '0') ?? 0;

            final double cgstAmount = taxable * cgstRate / 100;
            final double sgstAmount = taxable * sgstRate / 100;
            final double igstAmount = taxable * igstRate / 100;

            final double gst = cgstAmount + sgstAmount + igstAmount;

            return pw.TableRow(
              children: [
                // SERIAL NUMBER
                itemText('${startingSerial + index}'),

                // DESCRIPTION
                itemText(
                  item['ItemName']?.toString() ?? '',
                  alignment: pw.Alignment.centerLeft,
                ),

                // HSN
                itemText(item['HSNCode']?.toString() ?? ''),

                // QTY
                itemText(item['Quantity']?.toString() ?? ''),

                // UNIT
                itemText(item['Unit']?.toString() ?? ''),

                // RATE
                itemText('Rs ${rate.toStringAsFixed(2)}'),

                // TAXABLE
                itemText('Rs ${taxable.toStringAsFixed(2)}'),

                // GST
                itemText('Rs ${gst.toStringAsFixed(2)}'),

                // CGST
                if (!isInterState) itemText('Rs ${cgst.toStringAsFixed(2)}'),

                // SGST
                if (!isInterState) itemText('Rs ${sgst.toStringAsFixed(2)}'),

                // IGST
                if (isInterState)
                  itemText('Rs ${igstAmount.toStringAsFixed(2)}'),

                // TOTAL
                itemText('Rs ${item['TotalAmt'] ?? 0}', bold: true),
              ],
            );
          }),
        ],
      );
    }

    pw.Widget amountRow(
      String title,
      double value, {
      bool bold = false,
      bool highlight = false,
    }) {
      return pw.Container(
        color: highlight ? lightBlue : null,
        padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: bold ? 8 : 7,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
            pw.Text(
              'Rs ${value.toStringAsFixed(2)}',
              style: pw.TextStyle(
                fontSize: bold ? 8.5 : 7,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(25),

        // ------------------------------------------------------
        // HEADER - EVERY PAGE
        // ------------------------------------------------------
        header: (context) {
          return pw.Column(
            children: [
              // COMPANY HEADER
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: blue, width: 2),
                  ),
                ),
                child: pw.Row(
                  children: [
                    // LOGO
                    pw.Container(
                      width: 55,
                      height: 55,
                      padding: const pw.EdgeInsets.all(4),
                     child: logoImage != null
                          ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                          : pw.SizedBox(),
                    ),

                    pw.SizedBox(width: 10),

                    // COMPANY DETAILS
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyName,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: primary,
                            ),
                          ),

                          pw.SizedBox(height: 2),

                          pw.Text(
                            'GST Billing & Inventory Management',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: PdfColors.grey700,
                            ),
                          ),

                          pw.SizedBox(height: 3),

                          pw.Text(
                            companyAddress,
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey700,
                            ),
                          ),

                          pw.SizedBox(height: 2),

                          pw.Text(
                            'GSTIN: $companyGSTIN',
                            style: const pw.TextStyle(fontSize: 7),
                          ),

                          pw.SizedBox(height: 2),

                          pw.Text(
                            'Phone: $companyContact',
                            style: const pw.TextStyle(fontSize: 7),
                          ),

                          pw.SizedBox(height: 2),

                          pw.Text(
                            'State: $companyState',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ],
                      ),
                    ),

                    // TAX INVOICE
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: primary,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            'TAX INVOICE',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.white,
                            ),
                          ),
                        ),

                        pw.SizedBox(height: 5),

                        pw.Container(
                          width: 185,
                          child: pw.Column(
                            children: [
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Invoice No.',
                                    style: const pw.TextStyle(
                                      fontSize: 7,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.Text(
                                    invoiceNo,
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              pw.SizedBox(height: 3),

                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Invoice Date',
                                    style: const pw.TextStyle(
                                      fontSize: 7,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.Text(
                                    date,
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              pw.SizedBox(height: 3),

                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Due Date',
                                    style: const pw.TextStyle(
                                      fontSize: 7,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.Text(
                                    date,
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              pw.SizedBox(height: 3),

                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Place of Supply',
                                    style: const pw.TextStyle(
                                      fontSize: 7,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.Text(
                                    companyState,
                                    style: pw.TextStyle(
                                      fontSize: 7,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // CUSTOMER DETAILS
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: border, width: 0.7),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(9),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'BILL TO',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: primary,
                              ),
                            ),

                            pw.SizedBox(height: 6),

                            pw.Text(
                              customerName,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),

                            pw.SizedBox(height: 3),

                            pw.Text(
                              customerAddress,
                              style: const pw.TextStyle(fontSize: 7.2),
                            ),

                            pw.SizedBox(height: 2),

                            pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: 'GSTIN: ',
                                    style: pw.TextStyle(
                                      fontSize: 7.2,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.TextSpan(
                                    text: customerGSTIN,
                                    style: const pw.TextStyle(fontSize: 7.2),
                                  ),
                                ],
                              ),
                            ),

                            pw.SizedBox(height: 2),

                            pw.Text(
                              'State: $customerState',
                              style: const pw.TextStyle(fontSize: 7.2),
                            ),

                            pw.SizedBox(height: 2),

                            pw.Text(
                              'Contact: $customerContact',
                              style: const pw.TextStyle(
                                fontSize: 7.2,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    pw.Container(width: 1, height: 60, color: border),

                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(9),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'SHIP TO',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: primary,
                              ),
                            ),

                            pw.SizedBox(height: 6),

                            pw.Text(
                              customerName,
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),

                            pw.SizedBox(height: 3),

                            pw.Text(
                              customerAddress,
                              style: const pw.TextStyle(fontSize: 7.2),
                            ),

                            pw.SizedBox(height: 2),

                            pw.Text(
                              'GSTIN: $customerGSTIN',
                              style: const pw.TextStyle(fontSize: 7.2),
                            ),

                            pw.SizedBox(height: 2),

                            pw.Text(
                              'State: $customerState',
                              style: const pw.TextStyle(fontSize: 7.2),
                            ),

                            pw.SizedBox(height: 2),

                            pw.Text(
                              'Contact: $customerContact',
                              style: const pw.TextStyle(
                                fontSize: 7.2,
                                color: PdfColors.grey700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),
            ],
          );
        },

        build: (context) {
          return <pw.Widget>[
            buildItemTable(itemList, 1),
            pw.SizedBox(height: 10),

            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // HSN TAX SUMMARY
                pw.Expanded(
                  flex: 6,
                  child: pw.Table(
                    border: pw.TableBorder.all(color: border, width: 0.6),

                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.4),
                      1: pw.FlexColumnWidth(1.8),
                      2: pw.FlexColumnWidth(1.2),
                      3: pw.FlexColumnWidth(1.2),
                      4: pw.FlexColumnWidth(1.6),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: primary),
                        children: [
                          headerCell('HSN/SAC'),
                          headerCell('Taxable Value'),

                          if (!isInterState) headerCell('CGST'),
                          if (!isInterState) headerCell('SGST'),
                          if (isInterState) headerCell('IGST'),

                          headerCell('Total Tax'),
                        ],
                      ),

                      ...taxSummary.entries.map((entry) {
                        final data = entry.value;

                        return pw.TableRow(
                          children: [
                            itemText(
                              entry.key,
                              alignment: pw.Alignment.centerLeft,
                            ),

                            itemText(
                              'Rs ${data['taxable']!.toStringAsFixed(2)}',
                            ),

                            if (!isInterState)
                              itemText(
                                'Rs ${data['cgst']!.toStringAsFixed(2)}',
                              ),

                            if (!isInterState)
                              itemText(
                                'Rs ${data['sgst']!.toStringAsFixed(2)}',
                              ),

                            if (isInterState)
                              itemText(
                                'Rs ${data['igst']!.toStringAsFixed(2)}',
                              ),

                            itemText(
                              'Rs ${data['totalTax']!.toStringAsFixed(2)}',
                            ),
                          ],
                        );
                      }),

                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: lightBlue),
                        children: [
                          itemText('Total', bold: true),
                          itemText(
                            'Rs ${taxableTotal.toStringAsFixed(2)}',
                            bold: true,
                          ),
                          if (!isInterState)
                            itemText(
                              'Rs ${(gstTotal / 2).toStringAsFixed(2)}',
                              bold: true,
                            ),

                          if (!isInterState)
                            itemText(
                              'Rs ${(gstTotal / 2).toStringAsFixed(2)}',
                              bold: true,
                            ),

                          if (isInterState)
                            itemText(
                              'Rs ${gstTotal.toStringAsFixed(2)}',
                              bold: true,
                            ),
                          itemText(
                            'Rs ${gstTotal.toStringAsFixed(2)}',
                            bold: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(width: 8),

                // AMOUNT SUMMARY
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    children: [
                      amountRow('Taxable Value', taxableTotal),

                      if (!isInterState) ...[
                        amountRow('CGST', gstTotal / 2),
                        amountRow('SGST', gstTotal / 2),
                      ],

                      if (isInterState) amountRow('IGST', gstTotal),

                      amountRow(
                        'Round Off',
                        grandTotal - (subTotal + gstTotal - discount),
                      ),

                      pw.Container(
                        color: primary,
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 8,
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'GRAND TOTAL',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),

                            pw.Text(
                              'Rs ${grandTotal.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 8),

            // AMOUNT IN WORDS
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: lightBlue,
                border: pw.Border.all(color: border, width: 0.7),
              ),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'Amount in Words: ',
                      style: pw.TextStyle(
                        fontSize: 7.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.TextSpan(
                      text: numberToWords(grandTotal),
                      style: const pw.TextStyle(fontSize: 7.5),
                    ),
                  ],
                ),
              ),
            ),
            // PAYMENT + TERMS + SIGNATURE
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // PAYMENT DETAILS
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    height: 90,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: border, width: 0.7),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // LEFT SIDE - PAYMENT DETAILS
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'PAYMENT DETAILS',
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primary,
                                ),
                              ),

                              pw.SizedBox(height: 6),

                              pw.Text(
                                'Bank: $bankName',
                                style: const pw.TextStyle(fontSize: 7),
                              ),

                              pw.SizedBox(height: 3),

                              pw.Text(
                                'Account Name: $accountName',
                                style: const pw.TextStyle(fontSize: 7),
                              ),

                              pw.SizedBox(height: 3),

                              pw.Text(
                                'A/C No: $accountNo',
                                style: const pw.TextStyle(fontSize: 7),
                              ),

                              pw.SizedBox(height: 3),

                              pw.Text(
                                'IFSC: $ifsc',
                                style: const pw.TextStyle(fontSize: 7),
                              ),

                              pw.SizedBox(height: 3),

                              pw.Text(
                                'UPI ID: $upiId',
                                style: const pw.TextStyle(fontSize: 7),
                              ),
                            ],
                          ),
                        ),

                        // RIGHT SIDE - QR
                        if (qrImage != null)
                          pw.Container(
                            width: 65,
                            height: 72,
                            margin: const pw.EdgeInsets.only(left: 5),
                            child: pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              children: [
                                pw.Container(
                                  width: 55,
                                  height: 55,
                                  child: pw.Image(
                                    qrImage,
                                    fit: pw.BoxFit.contain,
                                  ),
                                ),

                                pw.SizedBox(height: 2),

                                pw.Text(
                                  'Scan to Pay',
                                  style: const pw.TextStyle(fontSize: 6),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(width: 6),

                // TERMS
                pw.Expanded(
                  child: pw.Container(
                    height: 90,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: border, width: 0.7),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'TERMS & CONDITIONS',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: primary,
                          ),
                        ),

                        pw.SizedBox(height: 6),

                        ...buildTermsWidgets(rawTerms),
                      ],
                    ),
                  ),
                ),

                pw.SizedBox(width: 6),

                // SIGNATURE
                pw.Expanded(
                  child: pw.Container(
                    height: 90,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: border, width: 0.7),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'AUTHORISED SIGNATURE',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: primary,
                          ),
                        ),

                        pw.SizedBox(height: 10),

                        pw.Text(
                          'For $companyName',
                          style: pw.TextStyle(
                            fontSize: 6,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.Spacer(),

                        pw.Container(
                          width: double.infinity,
                          height: 1,
                          color: border,
                        ),

                        pw.SizedBox(height: 4),

                        pw.Text(
                          'Authorised Signatory',
                          style: const pw.TextStyle(
                            fontSize: 6.8,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
    return pdf.save();
  }
}
