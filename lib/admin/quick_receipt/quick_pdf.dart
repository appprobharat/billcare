import 'dart:convert';
import 'package:billcare/api/api_service.dart';
import 'package:billcare/api/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class QuickReceiptPdfPage extends StatefulWidget {
  final int receiptId;
  const QuickReceiptPdfPage({super.key, required this.receiptId});

  @override
  State<QuickReceiptPdfPage> createState() => _QuickReceiptPdfPageState();
}

class _QuickReceiptPdfPageState extends State<QuickReceiptPdfPage> {
  Map<String, dynamic>? receiptData;

  @override
  void initState() {
    super.initState();
    _fetchPrintData();
  }

  Future<String?> _getToken() async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      if (!mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired. Please login again.")),
      );

      Navigator.pop(context);
      return null;
    }

    return token;
  }

  Future<void> _fetchPrintData() async {
    final token = await _getToken();
    if (token == null) return;

    final url = Uri.parse("${ApiService.baseUrl}/quick/receipt/print");
    try {
      final res = await http.post(
        url,
        headers: {"Authorization": "Bearer $token"},
        body: {"ReceiptId": widget.receiptId.toString()},
      );

      if (res.statusCode == 200) {
        setState(() {
          receiptData = jsonDecode(res.body);
        });
      } else {
        print("❌ Print API failed: ${res.body}");
      }
    } catch (e) {
      print("⚠️ Error fetching print data: $e");
    }
  }

  Future<pw.Document> _generatePdf(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // ============================================================
    // COMPANY
    // ============================================================

    final company = Map<String, dynamic>.from(data['Company'] ?? {});

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
        : '';

    // ============================================================
    // RECEIPT DATA
    // ============================================================

    final customerName = data['Name']?.toString() ?? '-';

    final contactNo = data['ContactNo']?.toString() ?? '-';

    final chequeNo = data['ChequeNo']?.toString().trim() ?? '';

    final remark = data['Remark']?.toString().trim() ?? '';

    final receiptNo = data['RefNo']?.toString() ?? '';

    final amount = double.tryParse(data['Amount']?.toString() ?? '0') ?? 0;

    // ============================================================
    // DATE
    // ============================================================

    String formattedDate = '';

    try {
      if (data['Date'] != null && data['Date'].toString().isNotEmpty) {
        formattedDate = DateFormat(
          'dd-MM-yyyy',
        ).format(DateTime.parse(data['Date'].toString()));
      }
    } catch (_) {
      formattedDate = data['Date']?.toString() ?? '';
    }

    // ============================================================
    // LOGO
    // ============================================================

    pw.MemoryImage? logoImage;

    final logoPath = company['Logo']?.toString().trim() ?? '';

    if (logoPath.isNotEmpty && logoPath != 'null') {
      try {
        final logoUrl =
            logoPath.startsWith('http://') || logoPath.startsWith('https://')
            ? logoPath
            : 'https://gst.billcare.in/storage/media/company/$logoPath';

        debugPrint('Quick Receipt Logo => $logoUrl');

        final response = await http.get(Uri.parse(logoUrl));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          logoImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        debugPrint('Quick Receipt Logo Error => $e');
      }
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

    pw.Widget infoRow(String label, String value) {
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
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    // ============================================================
    // PDF
    // ============================================================

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),

        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ==================================================
              // COMPANY HEADER
              // ==================================================
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 12),
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
                      width: 65,
                      height: 65,
                      padding: const pw.EdgeInsets.all(4),
                      child: logoImage != null
                          ? pw.Image(logoImage, fit: pw.BoxFit.contain)
                          : pw.Container(),
                    ),

                    pw.SizedBox(width: 10),

                    // COMPANY DETAILS
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            companyName,
                            maxLines: 1,
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: primary,
                            ),
                          ),

                          pw.SizedBox(height: 3),

                          pw.Text(
                            companyAddress,
                            maxLines: 2,
                            style: const pw.TextStyle(
                              fontSize: 8,
                              color: PdfColors.grey700,
                            ),
                          ),

                          pw.SizedBox(height: 3),

                          pw.Text(
                            'Phone: $companyContact',
                            style: const pw.TextStyle(fontSize: 8),
                          ),

                          if (companyEmail.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Email: $companyEmail',
                              style: const pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // RECEIPT BADGE
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: pw.BoxDecoration(
                        color: primary,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Text(
                        'PAYMENT\nRECEIPT',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 15),

              // ==================================================
              // RECEIPT INFO
              // ==================================================
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
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
                          infoRow(
                            'Receipt No.',
                            receiptNo.isEmpty ? '-' : receiptNo,
                          ),
                          pw.SizedBox(height: 5),
                          infoRow('Receipt Date', formattedDate),
                        ],
                      ),
                    ),

                    pw.Container(width: 1, height: 35, color: border),

                    pw.SizedBox(width: 15),

                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          infoRow('Status', 'Received'),
                          pw.SizedBox(height: 5),
                          infoRow('Payment Type', 'Payment'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // ==================================================
              // RECEIVED FROM
              // ==================================================
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: border, width: 0.7),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RECEIVED FROM',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: primary,
                      ),
                    ),

                    pw.SizedBox(height: 7),

                    pw.Text(
                      customerName,
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),

                    pw.SizedBox(height: 4),

                    pw.Text(
                      'Contact: $contactNo',
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

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
                        horizontal: 10,
                        vertical: 7,
                      ),
                      color: primary,
                      child: pw.Text(
                        'PAYMENT DETAILS',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),

                    pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Column(
                        children: [
                          // CHEQUE NUMBER
                          if (chequeNo.isNotEmpty)
                            pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'Cheque No.',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.Text(
                                  chequeNo,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),

                          if (chequeNo.isNotEmpty) pw.SizedBox(height: 6),

                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Amount Received',
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  color: PdfColors.grey700,
                                ),
                              ),

                              pw.Text(
                                'Rs ${amount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),

                          pw.Divider(color: border, thickness: 0.6),

                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 9,
                            ),
                            color: lightBlue,
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'TOTAL RECEIVED',
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primary,
                                  ),
                                ),

                                pw.Text(
                                  'Rs ${amount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    fontSize: 12,
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
              // REMARK
              // ==================================================
              if (remark.isNotEmpty) ...[
                pw.SizedBox(height: 12),

                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: border, width: 0.7),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DESCRIPTION / REMARK',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: primary,
                        ),
                      ),

                      pw.SizedBox(height: 5),

                      pw.Text(remark, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
              ],

              pw.SizedBox(height: 18),

              // ==================================================
              // SIGNATURE
              // ==================================================
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.SizedBox(
                  width: 160,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'For, $companyName',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 6,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),

                      pw.SizedBox(height: 28),

                      pw.Container(
                        width: double.infinity,
                        height: 1,
                        color: border,
                      ),

                      pw.SizedBox(height: 5),

                      pw.Text(
                        'Authorised Signatory',
                        style: const pw.TextStyle(
                          fontSize: 7,
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
                  horizontal: 12,
                  vertical: 9,
                ),
                color: primary,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Thank you for your payment!',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),

                    if (receiptNo.isNotEmpty)
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

    return pdf;
  }

  @override
  Widget build(BuildContext context) {
    if (receiptData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Quick Receipt PDF")),
      body: PdfPreview(
        build: (format) async {
          final pdf = await _generatePdf(receiptData!);
          return pdf.save();
        },
      ),
    );
  }
}
