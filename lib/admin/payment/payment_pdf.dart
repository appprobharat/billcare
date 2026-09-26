import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import 'package:printing/printing.dart';

class PaymentPrintPage extends StatefulWidget {
  final int paymentId;
  final String paymentType;

  const PaymentPrintPage({
    super.key,
    required this.paymentId,
    required this.paymentType,
  });

  @override
  State<PaymentPrintPage> createState() => _PaymentPrintPageState();
}

class _PaymentPrintPageState extends State<PaymentPrintPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _paymentData;

  @override
  void initState() {
    super.initState();
    _fetchPaymentData();
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

  Future<void> _fetchPaymentData() async {
    setState(() => _isLoading = true);

    try {
      final data = await ApiService.getPaymentData(
        widget.paymentType,
        widget.paymentId,
      );

      if (!mounted) return;

      setState(() {
        _paymentData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ fetchPaymentData error: $e");

      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Failed to load payment data")),
      );
    }
  }

  Future<Uint8List> _generatePdf(Map<String, dynamic> paymentData) async {
    final pdf = pw.Document();

    // ============================================================
    // COMPANY DATA
    // ============================================================

    final company = Map<String, dynamic>.from(paymentData['Company'] ?? {});

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

    // ============================================================
    // PAYMENT DATA
    // ============================================================

    final customerName = paymentData['Name']?.toString() ?? '-';

    final customerContact = paymentData['ContactNo']?.toString() ?? '-';

    final paymentNo = paymentData['RefNo']?.toString() ?? '-';

    final remark = paymentData['Remark']?.toString().trim() ?? '';

    final amount =
        double.tryParse(paymentData['Amount']?.toString() ?? '0') ?? 0;

    final discount =
        double.tryParse(paymentData['Discount']?.toString() ?? '0') ?? 0;

    // ============================================================
    // DATE
    // ============================================================

    String formattedDate = '';

    try {
      if (paymentData['Date'] != null &&
          paymentData['Date'].toString().isNotEmpty) {
        formattedDate = DateFormat(
          'dd-MM-yyyy',
        ).format(DateTime.parse(paymentData['Date'].toString()));
      }
    } catch (_) {
      formattedDate = paymentData['Date']?.toString() ?? '';
    }

    // ============================================================
    // LOGO
    // ============================================================

    pw.MemoryImage? logoImage;

    try {
      final logoValue = company['Logo']?.toString() ?? '';

      if (logoValue.isNotEmpty && logoValue != 'null') {
        String logoUrl;

        if (logoValue.startsWith('http://') ||
            logoValue.startsWith('https://')) {
          logoUrl = logoValue;
        } else {
          logoUrl = 'https://gst.billcare.in/storage/media/company/$logoValue';
        }

        debugPrint('Payment Logo URL => $logoUrl');

        logoImage = (await networkImage(logoUrl)) as pw.MemoryImage?;
      }
    } catch (e) {
      debugPrint('Payment logo error => $e');
    }

    // ============================================================
    // COLORS
    // ============================================================

    final primary = PdfColor.fromInt(0xff173F5F);

    final blue = PdfColor.fromInt(0xff20639B);

    final lightBlue = PdfColor.fromInt(0xffEAF3F8);

    final border = PdfColor.fromInt(0xffC9D2D9);

    // ============================================================
    // INFO ROW
    // ============================================================

    pw.Widget infoLabel(String label, String value) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
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

    // ============================================================
    // AMOUNT ROW
    // ============================================================

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

                    // COMPANY DETAILS
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyName,
                            maxLines: 2,
                            style: pw.TextStyle(
                              fontSize: 16,
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

                          pw.SizedBox(height: 2),

                          pw.Text(
                            'Email: $companyEmail',
                            style: const pw.TextStyle(fontSize: 7),
                          ),
                        ],
                      ),
                    ),

                    // PAYMENT BADGE
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
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
              // PAYMENT INFORMATION
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
                          infoLabel('Payment No.', paymentNo),
                          pw.SizedBox(height: 4),
                          infoLabel('Payment Date', formattedDate),
                        ],
                      ),
                    ),

                    pw.Container(width: 1, height: 30, color: border),

                    pw.SizedBox(width: 10),

                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [infoLabel('Status', 'Received')],
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

              // ==================================================
              // REMARK - ONLY IF AVAILABLE
              // ==================================================
              if (remark.isNotEmpty) ...[
                pw.SizedBox(height: 10),

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
              ],

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
                child: pw.SizedBox(
                  width: 130,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'For, $companyName',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 8,
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
                      paymentNo,
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
      appBar: AppBar(title: const Text('Print Payment')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _paymentData != null
            ? PdfPreview(
                build: (format) => _generatePdf(_paymentData!),
                allowPrinting: true,
                allowSharing: true,
                canChangeOrientation: false,
                canChangePageFormat: false,
              )
            : const Text(
                'Failed to load payment data.',
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }
}
