import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../theme/app_colors.dart';
import 'booking_invoice_pdf.dart';

Future<void> openBookingInvoicePdf(
  BuildContext context,
  Map<String, dynamic> invoiceData,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Generating invoice PDF...'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final invoice = BookingInvoiceData.fromApi(invoiceData);
    final bytes = await BookingInvoicePdf.build(invoiceData);
    if (!context.mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: 'Glowvax_Invoice_${invoice.invoiceNo}.pdf',
    );
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not generate invoice PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
