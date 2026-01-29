import 'dart:convert';
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
      const SnackBar(
        content: Text("Session expired. Please login again."),
      ),
    );

    Navigator.pop(context);
    return null;
  }

  return token;
}


  Future<void> _fetchPrintData() async {
    final token = await _getToken();
    if (token == null) return;

    final url = Uri.parse("https://gst.billcare.in/api/quick/receipt/print");
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
    final company = data["Company"];
    final date = DateFormat(
      "dd MMM yyyy",
    ).format(DateFormat("yyyy-MM-dd").parse(data["Date"]));

    // ✅ Logo URL
    final String? logoPath = company?["Logo"];
    final String logoUrl =
        "https://gst.billcare.in/storage/media/company/${logoPath ?? ""}";

    pw.MemoryImage? logoImage;
    if (logoPath != null && logoPath.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(logoUrl));
        if (res.statusCode == 200) {
          logoImage = pw.MemoryImage(res.bodyBytes);
        }
      } catch (e) {
        print("⚠️ Logo load error: $e");
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 🔹 Company Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(logoImage, height: 60),
                        pw.SizedBox(height: 8),
                      ],
                      pw.Text(
                        company?["Name"] ?? "",
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text(
                        company?["Address"] ?? "",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        "Phone: ${company?["ContactNo"] ?? ""} | Email: ${company?["Email"] ?? ""}",
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),
                pw.Divider(thickness: 2, color: PdfColors.blue),

                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    "PAYMENT RECEIPT",
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red800,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // 🔹 Receipt Details Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey700, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                "Received From:",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(data["Name"] ?? "-"),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                "Cheque No:",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(data["ChequeNo"]?.toString() ?? "-"),
                              pw.SizedBox(height: 8),
                              pw.Text(
                                "Description:",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(data["Remark"] ?? ""),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              
                              pw.Text(
                                "Date:",
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(date),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // 🔹 Amount Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue800, width: 1),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "Amount Received:",
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        "Rs ${data["Amount"]}",
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 40),

                // 🔹 Signature Section
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text("Received By"),
                        pw.SizedBox(height: 30),
                        pw.Text("____________________"),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("For, ${company?["Name"] ?? ""}"),
                        pw.SizedBox(height: 30),
                        pw.Text(
                          "Authorized Signatory",
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.Spacer(),
                pw.Center(
                  child: pw.Text(
                    "Thank you for your business!",
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey700,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
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
