import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../api/api_method.dart';
import '../models/invoice_list_model.dart';
import '../utility/change_value.dart';
import '../utility/global_function.dart';
import '../utility/image_manager.dart';

/// Builds the invoice PDF. Same content as the previous app's PDF
/// (company, VAT number, bill to, dates, items table, notes, total, bank
/// details) with the new look.
class PdfInvoiceApi {
  PdfInvoiceApi._();

  static const _ink = PdfColor.fromInt(0xFF1A1530);
  static const _muted = PdfColor.fromInt(0xFF6B6582);
  static const _primary = PdfColor.fromInt(0xFF5B2FC9);
  static const _soft = PdfColor.fromInt(0xFFF6F4FB);
  static const _line = PdfColor.fromInt(0xFFE6E1F0);
  static const _rainbow = [
    PdfColor.fromInt(0xFFE53935),
    PdfColor.fromInt(0xFFFB8C00),
    PdfColor.fromInt(0xFFFDD835),
    PdfColor.fromInt(0xFF43A047),
    PdfColor.fromInt(0xFF1E88E5),
    PdfColor.fromInt(0xFF7E57C2),
  ];

  static pw.ThemeData? _theme;

  /// Manrope is bundled in assets/fonts, so the PDF looks the same online
  /// or offline and supports characters like – and é.
  static Future<pw.ThemeData> _loadTheme() async {
    if (_theme != null) return _theme!;
    try {
      Future<pw.Font> font(String name) async => pw.Font.ttf(await rootBundle.load('assets/fonts/$name.ttf'));
      _theme = pw.ThemeData.withFont(
        base: await font('Manrope-Regular'),
        bold: await font('Manrope-Bold'),
        boldItalic: await font('Manrope-ExtraBold'),
      );
    } catch (e) {
      kLog(title: "PDF FONT", content: e);
      return pw.ThemeData.base();
    }
    return _theme!;
  }

  static String _money(num v) => "${ChangeValue.currencySymbol}${v.toStringAsFixed(2)}";

  static Future<Uint8List> generate(InvoiceData invoice) async {
    final theme = await _loadTheme();
    final logo = pw.MemoryImage((await rootBundle.load(ImageAsset.logo)).buffer.asUint8List());
    final customer = invoice.customer ?? Customer();
    final items = invoice.items;

    final pdf = pw.Document(
      title: invoice.invoiceNumber,
      author: ChangeValue.companyFullName,
      creator: ChangeValue.appName,
    );

    pw.Widget label(String t) => pw.Text(
      t,
      style: pw.TextStyle(fontSize: 8, color: _muted, fontWeight: pw.FontWeight.bold, letterSpacing: 1),
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 0, 36, 36),
        header: (context) => context.pageNumber == 1
            ? pw.Row(
                children: [for (final c in _rainbow) pw.Expanded(child: pw.Container(height: 6, color: c))],
              )
            : pw.SizedBox(),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            "${invoice.invoiceNumber ?? ''}  ·  Page ${context.pageNumber} of ${context.pagesCount}",
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 24),
          // ---- Header -------------------------------------------------------
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(logo, width: 90),
                  pw.SizedBox(height: 14),
                  pw.Text(
                    "Invoice",
                    style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: _primary),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    "VAT Registration Number : ${ChangeValue.companyNumber}",
                    style: const pw.TextStyle(fontSize: 10, color: _muted),
                  ),
                ],
              ),
              pw.Spacer(),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    ChangeValue.companyFullName,
                    style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _ink),
                  ),
                  pw.SizedBox(height: 4),
                  for (final line in [
                    ChangeValue.companyAddress1Line,
                    ChangeValue.companyAddress2Line,
                    ChangeValue.companyAddress3Line,
                    ChangeValue.companyAddress4Line,
                    "Tel: ${ChangeValue.companyTelPhone}",
                  ])
                    pw.Text(line, style: const pw.TextStyle(fontSize: 10, color: _ink)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          // ---- Bill to + meta -------------------------------------------------
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(color: _soft, borderRadius: pw.BorderRadius.circular(10)),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      label("BILL TO"),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        cleanText(customer.name),
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _ink),
                      ),
                      for (final line in [
                        cleanText(customer.address),
                        cleanText(customer.city),
                        cleanText(customer.country),
                        cleanText(customer.postalCode),
                      ].where((e) => e.isNotEmpty))
                        pw.Text(line, style: const pw.TextStyle(fontSize: 10, color: _ink)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    for (final (k, v) in [
                      ("INVOICE NO", cleanText(invoice.invoiceNumber)),
                      if (cleanText(invoice.referenceNumber).isNotEmpty)
                        ("REFERENCE NO", cleanText(invoice.referenceNumber)),
                      ("INVOICE DATE", formatDatePdf(invoice.date)),
                      ("INVOICE DUE DATE", formatDatePdf(invoice.dueDate)),
                    ]) ...[
                      label(k),
                      pw.SizedBox(height: 1),
                      pw.Text(
                        v,
                        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _ink),
                      ),
                      pw.SizedBox(height: 6),
                    ],
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          // ---- Items ------------------------------------------------------------
          pw.TableHelper.fromTextArray(
            headers: const ['DATE', 'DESCRIPTION', 'VEHICLE', 'QTY', 'PRICE', 'AMOUNT'],
            data: [
              for (final i in items)
                [
                  formatDatePdf(i.date),
                  cleanText(i.description),
                  i.vehicle,
                  "${i.quantity ?? ''}",
                  _money(i.priceValue),
                  _money(i.amountValue),
                ],
            ],
            border: null,
            headerDecoration: const pw.BoxDecoration(color: _ink),
            headerStyle: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            cellStyle: const pw.TextStyle(fontSize: 9.5, color: _ink),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: _line)),
            ),
            columnWidths: const {
              0: pw.FixedColumnWidth(62),
              1: pw.FlexColumnWidth(3),
              2: pw.FixedColumnWidth(58),
              3: pw.FixedColumnWidth(30),
              4: pw.FixedColumnWidth(62),
              5: pw.FixedColumnWidth(68),
            },
            cellAlignments: const {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 18),
          // ---- Notes + total ------------------------------------------------------
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: cleanText(invoice.notes).isEmpty
                    ? pw.SizedBox()
                    : pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          label("NOTES"),
                          pw.SizedBox(height: 4),
                          pw.Text(cleanText(invoice.notes), style: const pw.TextStyle(fontSize: 10, color: _ink)),
                        ],
                      ),
              ),
              pw.SizedBox(width: 20),
              pw.Container(
                width: 170,
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: pw.BoxDecoration(color: _ink, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      "TOTAL",
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: const PdfColor.fromInt(0xFFC9BEF3),
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      _money(invoice.total),
                      style: pw.TextStyle(fontSize: 20, color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 28),
          // ---- Bank details -----------------------------------------------------------
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.only(top: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: _line)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                label("PAYMENT DETAILS"),
                pw.SizedBox(height: 4),
                pw.Text(
                  ChangeValue.companyFullName,
                  style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _ink),
                ),
                pw.Text(ChangeValue.bankName, style: const pw.TextStyle(fontSize: 10, color: _ink)),
                pw.Text(ChangeValue.bankAccount, style: const pw.TextStyle(fontSize: 10, color: _ink)),
              ],
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }
}

class FileHandleApi {
  FileHandleApi._();

  /// RLL/2026/00142 -> RLL202600142.pdf (same naming as before)
  static String fileName(InvoiceData invoice) {
    final base = (invoice.invoiceNumber ?? 'invoice').replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return "$base.pdf";
  }

  static Future<File> saveDocument({required String name, required Uint8List bytes}) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<File> saveInvoice(InvoiceData invoice, {Uint8List? bytes}) async =>
      saveDocument(name: fileName(invoice), bytes: bytes ?? await PdfInvoiceApi.generate(invoice));

  static Future<bool> openFile(File file) async {
    final result = await OpenFilex.open(file.path);
    return result.type == ResultType.done;
  }

  static Future<void> shareFile(File file, InvoiceData invoice) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: "Invoice ${invoice.invoiceNumber ?? ''} — ${ChangeValue.companyFullName}",
        text: "Please find attached invoice ${invoice.invoiceNumber ?? ''} for ${formatMoney(invoice.total)}.",
      ),
    );
  }

  static Future<void> printInvoice(InvoiceData invoice, Uint8List bytes) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: fileName(invoice));
}
