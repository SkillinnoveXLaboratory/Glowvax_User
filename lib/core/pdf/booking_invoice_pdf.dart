import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_constants.dart';

class BookingInvoiceData {
  final String invoiceNo;
  final DateTime? date;
  final String customerName;
  final String customerPhone;
  final String partnerName;
  final String partnerAddress;
  final String serviceName;
  final int? durationMinutes;
  final double amount;
  final double platformFee;
  final double partnerEarning;
  final String paymentStatus;
  final String paymentMethod;

  const BookingInvoiceData({
    required this.invoiceNo,
    this.date,
    required this.customerName,
    required this.customerPhone,
    required this.partnerName,
    required this.partnerAddress,
    required this.serviceName,
    this.durationMinutes,
    required this.amount,
    required this.platformFee,
    required this.partnerEarning,
    required this.paymentStatus,
    required this.paymentMethod,
  });

  factory BookingInvoiceData.fromApi(Map<String, dynamic> data) {
    final invoice = (data['invoice'] as Map<String, dynamic>?) ?? data;
    final customer = invoice['customer'] as Map<String, dynamic>?;
    final partner = invoice['partner'] as Map<String, dynamic>?;
    final service = invoice['service'] as Map<String, dynamic>?;
    final partnerAddress = partner?['address'] as Map<String, dynamic>?;

    return BookingInvoiceData(
      invoiceNo: invoice['invoiceNo']?.toString() ?? '—',
      date: DateTime.tryParse(invoice['date']?.toString() ?? ''),
      customerName: customer?['name']?.toString() ?? '—',
      customerPhone: customer?['phone']?.toString() ?? '—',
      partnerName: partner?['businessName']?.toString() ?? '—',
      partnerAddress: partnerAddress != null
          ? '${partnerAddress['line1'] ?? ''}, ${partnerAddress['city'] ?? ''} - ${partnerAddress['pincode'] ?? ''}'
          : '—',
      serviceName: service?['name']?.toString() ?? '—',
      durationMinutes: (service?['duration'] as num?)?.toInt(),
      amount: (invoice['amount'] as num?)?.toDouble() ?? 0,
      platformFee: (invoice['platformFee'] as num?)?.toDouble() ?? 0,
      partnerEarning: (invoice['partnerEarning'] as num?)?.toDouble() ?? 0,
      paymentStatus: invoice['paymentStatus']?.toString() ?? 'pending',
      paymentMethod: invoice['paymentMethod']?.toString() ?? '',
    );
  }

  bool get isPaid => paymentStatus == 'paid';

  String get formattedDate {
    if (date == null) return '—';
    return DateFormat('dd MMM yyyy, hh:mm a').format(date!.toLocal());
  }
}

class BookingInvoicePdf {
  BookingInvoicePdf._();

  static final _currency = NumberFormat.currency(
    locale: 'en_IN',
    symbol: 'Rs. ',
    decimalDigits: 0,
  );

  static String _money(double value) => _currency.format(value);

  static Future<Uint8List> build(Map<String, dynamic> apiData) async {
    final invoice = BookingInvoiceData.fromApi(apiData);
    final regular = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: regular, bold: bold),
    );

    final gold = PdfColor.fromHex('#D4AF37');
    final dark = PdfColor.fromHex('#1A1A1A');
    final muted = PdfColor.fromHex('#666666');
    final border = PdfColor.fromHex('#E0E0E0');
    final paidGreen = PdfColor.fromHex('#4CAF50');
    final pendingOrange = PdfColor.fromHex('#E6A817');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: dark,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          AppConstants.appName.toUpperCase(),
                          style: pw.TextStyle(
                            font: bold,
                            fontSize: 22,
                            color: gold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Beauty & Wellness Marketplace',
                          style: pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'BOOKING INVOICE',
                        style: pw.TextStyle(
                          font: bold,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        '#${invoice.invoiceNo}',
                        style: pw.TextStyle(fontSize: 11, color: gold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        invoice.formattedDate,
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey300,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _partyBox(
                    title: 'BILL TO',
                    name: invoice.customerName,
                    lines: ['Phone: ${invoice.customerPhone}'],
                    border: border,
                    titleColor: gold,
                  ),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: _partyBox(
                    title: 'SERVICE PROVIDER',
                    name: invoice.partnerName,
                    lines: [invoice.partnerAddress],
                    border: border,
                    titleColor: gold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: invoice.isPaid ? paidGreen : pendingOrange,
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(6),
                  topRight: pw.Radius.circular(6),
                ),
              ),
              child: pw.Text(
                invoice.isPaid ? 'PAYMENT RECEIVED' : 'PAYMENT PENDING',
                style: pw.TextStyle(
                  font: bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.Table(
              border: pw.TableBorder.all(color: border, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F5F5F5'),
                  ),
                  children: [
                    _tableHeader('Description', bold),
                    _tableHeader('Duration', bold),
                    _tableHeader('Amount', bold, align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _tableCell(invoice.serviceName),
                    _tableCell(
                      invoice.durationMinutes != null
                          ? '${invoice.durationMinutes} min'
                          : '—',
                    ),
                    _tableCell(
                      _money(invoice.amount),
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Payment Details',
                        style: pw.TextStyle(font: bold, fontSize: 11),
                      ),
                      pw.SizedBox(height: 8),
                      _detailLine(
                        'Method',
                        invoice.paymentMethod.isEmpty
                            ? '—'
                            : invoice.paymentMethod.toUpperCase(),
                      ),
                      _detailLine(
                        'Status',
                        invoice.isPaid ? 'Paid' : 'Pending',
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: 24),
                pw.Container(
                  width: 220,
                  padding: const pw.EdgeInsets.all(14),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: border),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Column(
                    children: [
                      _summaryRow('Subtotal', _money(invoice.amount)),
                      if (invoice.platformFee > 0)
                        _summaryRow(
                          'Platform fee',
                          _money(invoice.platformFee),
                        ),
                      pw.Divider(color: border),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total',
                            style: pw.TextStyle(font: bold, fontSize: 12),
                          ),
                          pw.Text(
                            _money(invoice.amount),
                            style: pw.TextStyle(
                              font: bold,
                              fontSize: 14,
                              color: gold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.Spacer(),
            pw.Divider(color: border),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Thank you for booking with ${AppConstants.appName}!',
                style: pw.TextStyle(fontSize: 10, color: muted),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                'This is a computer-generated invoice and does not require a signature.',
                style: pw.TextStyle(fontSize: 8, color: muted),
              ),
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static pw.Widget _partyBox({
    required String title,
    required String name,
    required List<String> lines,
    required PdfColor border,
    required PdfColor titleColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: border),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 9,
              color: titleColor,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            name,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          ...lines.map(
            (line) => pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                line,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _tableHeader(
    String text,
    pw.Font bold, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(font: bold, fontSize: 10),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Text(
        text,
        textAlign: align,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _detailLine(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 60,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ),
          pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
