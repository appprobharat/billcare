import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class BillPdfService {

  /// 🔥 DOWNLOAD PDF
  static Future<String> generateAndSavePdf({
    required Map<String, dynamic> billData,
  }) async {

    try {

      final Uint8List pdfBytes =
          await _generatePdfDocument(billData);

      final baseDirectory =
          await getApplicationDocumentsDirectory();

      final invoiceNo =
          billData['invoice_no'].toString();

      final file = File(
        '${baseDirectory.path}/Bill_$invoiceNo.pdf',
      );

      await file.writeAsBytes(pdfBytes);

      return file.path;

    } catch (e) {

      print("PDF ERROR : $e");

      return '';
    }
  }

  /// 🔥 PRINT PDF
  static Future<void> printDocument({
    required Map<String, dynamic> billData,
  }) async {

    final Uint8List pdfBytes =
        await _generatePdfDocument(billData);

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async =>
          pdfBytes,
    );
  }

  /// 🔥 PDF UI
  static Future<Uint8List> _generatePdfDocument(
    Map<String, dynamic> billData,
  ) async {

    final pdf = pw.Document();

    final List items =
        billData["items"] ?? [];

    final String invoiceNo =
        billData["invoice_no"].toString();

    final String date =
        billData["date"].toString();

    final String clientName =
        billData["client_name"].toString();

    final String contact =
        billData["contact_no"].toString();

    final double totalAmount =
        double.tryParse(
          billData["total_amount"].toString(),
        ) ??
        0;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,

        build: (context) {

          return pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,

            children: [

              /// 🔥 HEADER
              pw.Row(
                mainAxisAlignment:
                    pw.MainAxisAlignment.spaceBetween,

                children: [

                  pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start,

                    children: [

                      pw.Text(
                        "BillCare",

                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight:
                              pw.FontWeight.bold,
                        ),
                      ),

                      pw.Text(
                        "Invoice Bill",
                      ),
                    ],
                  ),

                  pw.Text(
                    "INVOICE",

                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight:
                          pw.FontWeight.bold,

                      color: PdfColors.orange,
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              /// 🔥 CLIENT DETAILS
              pw.Container(
                padding: const pw.EdgeInsets.all(10),

                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.grey400,
                  ),
                ),

                child: pw.Row(
                  children: [

                    /// LEFT
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.start,

                        children: [

                          pw.Text(
                            "Bill To",

                            style: pw.TextStyle(
                              fontWeight:
                                  pw.FontWeight.bold,
                            ),
                          ),

                          pw.SizedBox(height: 5),

                          pw.Text(clientName),

                          pw.Text(contact),
                        ],
                      ),
                    ),

                    /// RIGHT
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment:
                            pw.CrossAxisAlignment.end,

                        children: [

                          pw.Text(
                            "Invoice No : $invoiceNo",
                          ),

                          pw.Text(
                            "Date : $date",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              /// 🔥 TABLE
              pw.Table.fromTextArray(
                border: pw.TableBorder.all(),

                headerStyle: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight:
                      pw.FontWeight.bold,
                ),

                headerDecoration:
                    const pw.BoxDecoration(
                  color: PdfColors.orange,
                ),

                headers: [
                  "#",
                  "Item",
                  "Qty",
                  "Rate",
                  "GST",
                  "Amount",
                ],

                data: items
                    .asMap()
                    .entries
                    .map<List<String>>((entry) {

                  final item = entry.value;

                  return [

                    (entry.key + 1).toString(),

                    item["item_name"]
                        .toString(),

                    item["qty"]
                        .toString(),

                    item["rate"]
                        .toString(),

                    "${item["gst"]}%",

                    item["amount"]
                        .toString(),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 25),

              /// 🔥 TOTAL
              pw.Align(
                alignment:
                    pw.Alignment.centerRight,

                child: pw.Container(
                  width: 220,

                  padding:
                      const pw.EdgeInsets.all(12),

                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(),
                  ),

                  child: pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment
                            .spaceBetween,

                    children: [

                      pw.Text(
                        "Grand Total",

                        style: pw.TextStyle(
                          fontWeight:
                              pw.FontWeight.bold,
                        ),
                      ),

                      pw.Text(
                        "Rs.${totalAmount.toStringAsFixed(2)}",

                        style: pw.TextStyle(
                          fontWeight:
                              pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.SizedBox(height: 30),

              /// 🔥 FOOTER
              pw.Text(
                "Thank you for your business.",

                style: const pw.TextStyle(
                  fontSize: 11,
                ),
              ),

              pw.Spacer(),

              pw.Align(
                alignment:
                    pw.Alignment.bottomRight,

                child: pw.Column(
                  children: [

                    pw.Text(
                      "Authorized Signatory",
                    ),

                    pw.SizedBox(height: 40),

                    pw.Container(
                      width: 150,
                      height: 1,

                      color: PdfColors.black,
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