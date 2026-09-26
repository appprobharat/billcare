import 'package:billcare/api/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';

class ReceiptPrintPage extends StatefulWidget {
  final int receiptId;
  final String receiptType;

  const ReceiptPrintPage({
    super.key,
    required this.receiptId,
    required this.receiptType,
  });

  @override
  State<ReceiptPrintPage> createState() => _ReceiptPrintPageState();
}

class _ReceiptPrintPageState extends State<ReceiptPrintPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _receiptData;

  @override
  void initState() {
    super.initState();
    _fetchReceiptData();
  }

  String _numberToWords(double number) {
    if (number == 0) {
      return 'Rupees Zero Only';
    }

    final int integerPart = number.toInt();

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

    String convert(int n) {
      if (n < 20) {
        return units[n];
      }

      if (n < 100) {
        return '${tens[n ~/ 10]}'
            '${n % 10 != 0 ? ' ${units[n % 10]}' : ''}';
      }

      if (n < 1000) {
        return '${units[n ~/ 100]} Hundred'
            '${n % 100 != 0 ? ' ${convert(n % 100)}' : ''}';
      }

      if (n < 100000) {
        return '${convert(n ~/ 1000)} Thousand'
            '${n % 1000 != 0 ? ' ${convert(n % 1000)}' : ''}';
      }

      if (n < 10000000) {
        return '${convert(n ~/ 100000)} Lakh'
            '${n % 100000 != 0 ? ' ${convert(n % 100000)}' : ''}';
      }

      return '${convert(n ~/ 10000000)} Crore'
          '${n % 10000000 != 0 ? ' ${convert(n % 10000000)}' : ''}';
    }

    return 'Rupees ${convert(integerPart)} Only';
  }

  Future<void> _fetchReceiptData() async {
    setState(() {
      _isLoading = true;
    });

    final authToken = await AuthStorage.getToken();

    if (authToken == null || authToken.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again.")),
      );

      Navigator.pop(context);
      return;
    }

    final data = await ApiService.getReceiptData(
      widget.receiptType,
      widget.receiptId,
    );

    setState(() {
      _receiptData = data;
      _isLoading = false;
    });
  }

  Future<Uint8List> _generatePdf(Map<String, dynamic> receiptData) async {
    final pdf = pw.Document();

    // ============================================================
    // COMPANY DATA
    // ============================================================

    final company = Map<String, dynamic>.from(receiptData['Company'] ?? {});

    final companyName = company['Name']?.toString().trim().isNotEmpty == true
        ? company['Name'].toString()
        : '-';

    final companyAddress =
        company['Address']?.toString().trim().isNotEmpty == true
        ? company['Address'].toString()
        : '-';

    final companyContact =
        company['ContactNo']?.toString().trim().isNotEmpty == true
        ? company['ContactNo'].toString()
        : '-';

    final companyEmail = company['Email']?.toString().trim().isNotEmpty == true
        ? company['Email'].toString()
        : '-';

    final companyGSTIN = company['GSTIN']?.toString().trim().isNotEmpty == true
        ? company['GSTIN'].toString()
        : '';

    // ============================================================
    // RECEIPT DATA
    // ============================================================

    final customerName = receiptData['Name']?.toString() ?? '-';

    final customerContact = receiptData['ContactNo']?.toString() ?? '-';

    final receiptNo = receiptData['RefNo']?.toString() ?? '-';

    final remark = receiptData['Remark']?.toString().trim() ?? '';

    final paymentMode =
        receiptData['PaymentMode']?.toString().trim().isNotEmpty == true
        ? receiptData['PaymentMode'].toString()
        : '-';

    final amount =
        double.tryParse(receiptData['Amount']?.toString() ?? '0') ?? 0;

    final discount =
        double.tryParse(receiptData['Discount']?.toString() ?? '0') ?? 0;

    // ============================================================
    // DATE
    // ============================================================

    String formattedDate = '';

    try {
      if (receiptData['Date'] != null &&
          receiptData['Date'].toString().isNotEmpty) {
        formattedDate = DateFormat(
          'dd-MM-yyyy',
        ).format(DateTime.parse(receiptData['Date'].toString()));
      }
    } catch (_) {
      formattedDate = receiptData['Date']?.toString() ?? '';
    }

    // ============================================================
    // LOGO
    // ============================================================

    pw.MemoryImage? logoImage;

    try {
      final logoValue = company['Logo']?.toString() ?? '';

      String logoUrl = '';

      if (logoValue.isNotEmpty && logoValue != 'null') {
        if (logoValue.startsWith('http://') ||
            logoValue.startsWith('https://')) {
          logoUrl = logoValue;
        } else {
          logoUrl = 'https://gst.billcare.in/storage/media/company/$logoValue';
        }

        logoImage = (await networkImage(logoUrl)) as pw.MemoryImage?;
      }
    } catch (e) {
      debugPrint('Receipt logo error: $e');
    }

    // ============================================================
    // COLORS
    // ============================================================

    final primary = PdfColor.fromInt(0xff173F5F);

    final blue = PdfColor.fromInt(0xff20639B);

    final lightBlue = PdfColor.fromInt(0xffEAF3F8);

    final border = PdfColor.fromInt(0xffC9D2D9);

    // ============================================================
    // HELPERS
    // ============================================================

    pw.Widget infoLabel(String label, String value) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 75,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      );
    }

    pw.Widget amountRow(String title, double value, {bool bold = false}) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
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
                fontSize: bold ? 8 : 7,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    // ============================================================
    // PDF PAGE
    // ============================================================

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),

        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,

            children: [
              // ==================================================
              // COMPANY HEADER
              // ==================================================
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 10),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: blue, width: 2),
                  ),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    // LOGO
                    pw.Container(
                      width: 52,
                      height: 52,
                      padding: const pw.EdgeInsets.all(3),
                      child: logoImage != null
                          ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                          : pw.Container(),
                    ),

                    pw.SizedBox(width: 8),

                    // COMPANY
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyName,
                            maxLines: 1,
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: primary,
                            ),
                          ),

                          pw.SizedBox(height: 2),

                          pw.Text(
                            companyAddress,
                            maxLines: 2,
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey700,
                            ),
                          ),

                          pw.SizedBox(height: 2),

                          pw.Text(
                            'Phone: $companyContact',
                            style: const pw.TextStyle(fontSize: 7),
                          ),

                          if (companyEmail != '-') ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Email: $companyEmail',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                          ],

                          if (companyGSTIN.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'GSTIN: $companyGSTIN',
                              style: const pw.TextStyle(fontSize: 7),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // RECEIPT BADGE
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: pw.BoxDecoration(
                        color: primary,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'PAYMENT\nRECEIPT',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ==================================================
              // RECEIPT INFORMATION
              // ==================================================
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: lightBlue,
                  border: pw.Border.all(color: border, width: 0.7),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          infoLabel('Receipt No.', receiptNo),
                          pw.SizedBox(height: 4),
                          infoLabel('Receipt Date', formattedDate),
                        ],
                      ),
                    ),

                    pw.Container(width: 1, height: 30, color: border),

                    pw.SizedBox(width: 10),

                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          infoLabel('Payment Mode', paymentMode),
                          pw.SizedBox(height: 4),
                          infoLabel('Status', 'Received'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // ==================================================
              // RECEIVED FROM
              // ==================================================
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(9),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: border, width: 0.7),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RECEIVED FROM',
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
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 3),

                    pw.Text(
                      'Contact: $customerContact',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // ==================================================
              // PAYMENT DETAILS
              // ==================================================
              pw.Container(
                width: double.infinity,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: border, width: 0.7),
                ),
                child: pw.Column(
                  children: [
                    // HEADER
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      color: primary,
                      child: pw.Text(
                        'PAYMENT DETAILS',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),

                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        children: [
                          amountRow('Received Amount', amount),

                          if (discount > 0) amountRow('Discount', discount),

                          pw.Divider(color: border, thickness: 0.6),

                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 7,
                            ),
                            color: lightBlue,
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TOTAL RECEIVED',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primary,
                                  ),
                                ),

                                pw.Text(
                                  'Rs ${amount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primary,
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
              ),

              pw.SizedBox(height: 10),

              // ==================================================
              // DESCRIPTION / REMARK
              // ==================================================
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: border, width: 0.7),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'DESCRIPTION / REMARK',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: primary,
                      ),
                    ),

                    pw.SizedBox(height: 5),

                    pw.Text(remark, style: const pw.TextStyle(fontSize: 7.5)),
                  ],
                ),
              ),

              pw.SizedBox(height: 10),

              // ==================================================
              // AMOUNT IN WORDS
              // ==================================================
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(8),
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
                        text: _numberToWords(amount),
                        style: const pw.TextStyle(fontSize: 7.5),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 18),

              // ==================================================
              // SIGNATURE
              // ==================================================
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Container(
                  width: 130,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'For, $companyName',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 6,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 22),

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

              pw.Spacer(),

              // ==================================================
              // FOOTER
              // ==================================================
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                color: primary,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Thank you for your payment!',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),

                    pw.Text(
                      receiptNo,
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.white,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Print Receipt')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _receiptData != null
            ? PdfPreview(
                build: (format) => _generatePdf(_receiptData!),
                allowPrinting: true,
                allowSharing: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
              )
            : const Text(
                'Failed to load receipt data.',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}
