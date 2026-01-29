import 'package:billcare/api/auth_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:billcare/api/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<void> _fetchReceiptData() async {
    setState(() {
      _isLoading = true;
    });

   final authToken = await AuthStorage.getToken();

if (authToken == null || authToken.isEmpty) {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("Session expired. Please login again."),
    ),
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
    final String formattedDate = receiptData['Date'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(receiptData['Date']))
        : '';
    final company = receiptData['Company'];
    final logoUrl =
        "https://gst.billcare.in/storage/media/company/${company['Logo']}";
    final logoImage = await networkImage(logoUrl);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Image(logoImage, width: 60, height: 60),
                  pw.Column(
                    children: [
                      pw.Text(
                        company['Name'] ?? '',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.red,
                        ),
                      ),
                      pw.Text(
                        company['Address'] ?? '',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "Phone: ${company['ContactNo'] ?? ''} | Email: ${company['Email'] ?? ''}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),

              pw.Center(
                child: pw.Text(
                  "Receipt",
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Received From: ${receiptData['Name'] ?? ''}"),
                      pw.Text("Contact No: ${receiptData['ContactNo'] ?? ''}"),
                      pw.Text("Date: $formattedDate"),
                    ],
                  ),

                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Receipt No: ${receiptData['RefNo'] ?? ''}"),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              pw.Divider(thickness: 1),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Description: ${receiptData['Remark'] ?? ''}"),
                  pw.Text(
                    "Received: Rs ${receiptData['Amount'] ?? ''}",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
              pw.SizedBox(height: 40),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Column(
                  children: [
                    pw.Text(
                      "For, ${company['Name'] ?? ''}",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text("Authorized Signatory"),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  "Thank you for your business!",
                  style: const pw.TextStyle(fontSize: 10),
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
