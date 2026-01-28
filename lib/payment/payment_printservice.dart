import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:billcare/api/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
Future<Uint8List> getPdfFileBytes() async {
  if (_paymentData == null) return Uint8List(0);
  return await _generatePdf(_paymentData!);
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
    final String formattedDate = paymentData['Date'] != null
        ? DateFormat('dd-MM-yyyy').format(DateTime.parse(paymentData['Date']))
        : '';
    final company = paymentData['Company'];
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
                  "Payment Payment",
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
                  // Left-aligned column
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "${paymentData['Name'] ?? ''}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            "Contact No: ${paymentData['ContactNo'] ?? ''}",
                          ),
                          pw.SizedBox(width: 20),
                          pw.Text("Payment No: ${paymentData['RefNo'] ?? ''}"),
                        ],
                      ),

                      pw.Text("Date: $formattedDate"),
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
                  pw.Text("Description: ${paymentData['Remark'] ?? ''}"),
                  pw.Text(
                    "Received: Rs ${paymentData['Amount'] ?? ''}",
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
