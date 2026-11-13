import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:nasr_isp/core/finance/index.dart';
import 'package:nasr_isp/features/payments/domain/entities/payment_entity.dart';
import 'package:nasr_isp/features/settings/domain/entities/app_settings_entity.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Builds a printable PDF receipt for a payment.
///
/// Customer-facing, so it deliberately shows only what the customer paid:
/// never package cost, margin or internal notes.
class PaymentReceiptPdf {
  const PaymentReceiptPdf._();

  /// Receipt content never gets wider than this, so on A4/Letter it stays a
  /// neat slip at the top-centre instead of stretching across the sheet.
  static const double _maxContentWidth = 380;

  /// e.g. `NASR-A1B2C3`: the Settings invoice prefix plus the last 6
  /// characters of the payment id, so the number is stable across reprints.
  static String receiptNumber(PaymentEntity p, AppSettingsEntity s) {
    final id = p.id.toUpperCase();
    final tail = id.length > 6 ? id.substring(id.length - 6) : id;
    return '${s.invoicePrefix}$tail';
  }

  static String _money(double v, AppSettingsEntity s) {
    final symbol = s.currencySymbol.trim().isEmpty
        ? 'Rs'
        : s.currencySymbol.trim();
    return '$symbol ${NumberFormat('#,##0', 'en_US').format(v.round())}';
  }

  static String _date(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  static String _method(String? m) {
    switch (m) {
      case 'cash':
        return 'Cash';
      case 'bankTransfer':
        return 'Bank Transfer';
      case 'easypaisa':
        return 'EasyPaisa';
      case 'jazzcash':
        return 'JazzCash';
      default:
        return (m == null || m.isEmpty) ? '-' : m;
    }
  }

  static String _description(PaymentEntity p) {
    if (p.type == PaymentType.installation) return 'Installation charges';
    final month = p.billingMonth;
    return month == null || month.isEmpty
        ? 'Internet subscription'
        : 'Internet subscription - ${BillingCycle.formatMonthKey(month)}';
  }

  static pw.Widget _row(
    String label,
    String value, {
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(width: 12),
          pw.Flexible(
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// [format] is the paper the user picked in the print dialog; defaults to A5.
  static Future<Uint8List> build({
    required PaymentEntity payment,
    required AppSettingsEntity settings,
    PdfPageFormat format = PdfPageFormat.a5,
    String? userId,
    String? packageName,
  }) async {
    final number = receiptNumber(payment, settings);
    final companyName = settings.companyName.trim().isEmpty
        ? 'NASR ISP'
        : settings.companyName.trim();
    final contact = [
      settings.companyAddress.trim(),
      settings.companyPhone.trim(),
      settings.companyEmail.trim(),
    ].where((e) => e.isNotEmpty).toList();

    final received = payment.paidAmount;
    final balance = payment.remainingAmount;
    final paidInFull = balance <= 0;
    final receiptDate =
        payment.completedDate ??
        payment.paymentDate ??
        payment.createdAt ??
        DateTime.now();

    final doc = pw.Document(title: 'Receipt $number', author: companyName);

    final content = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Header
        pw.Center(
          child: pw.Text(
            companyName,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        if (contact.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text(
              contact.join('  |  '),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
        ],
        pw.SizedBox(height: 10),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 6),

        // Title + number/date
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'PAYMENT RECEIPT',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Receipt No: $number',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'Date: ${_date(receiptDate)}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 14),

        // Customer + what it was for
        _row('Received from', payment.customerName, bold: true),
        if (userId != null && userId.trim().isNotEmpty)
          _row('User ID', userId.trim()),
        if (packageName != null && packageName.trim().isNotEmpty)
          _row('Current package', packageName.trim()),
        _row('Description', _description(payment)),
        if (payment.periodEnd != null)
          _row('Service valid until', _date(payment.periodEnd!)),
        _row('Payment method', _method(payment.method)),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),

        // Amounts
        _row('Total billed', _money(payment.amount, settings)),
        _row(
          'Amount received',
          _money(received, settings),
          bold: true,
          color: PdfColors.green800,
        ),
        _row(
          'Balance due',
          _money(balance, settings),
          bold: true,
          color: paidInFull ? PdfColors.green800 : PdfColors.red800,
        ),
        pw.SizedBox(height: 14),

        // Status stamp
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: paidInFull ? PdfColors.green800 : PdfColors.orange800,
                width: 1.5,
              ),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              paidInFull ? 'PAID IN FULL' : 'PARTIAL PAYMENT',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: paidInFull ? PdfColors.green800 : PdfColors.orange800,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 40),
        pw.Center(
          child: pw.Text(
            'Thank you for choosing $companyName.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            'This is a computer-generated receipt.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      ],
    );

    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => pw.Align(
          alignment: pw.Alignment.topCenter,
          child: pw.ConstrainedBox(
            constraints: const pw.BoxConstraints(maxWidth: _maxContentWidth),
            child: content,
          ),
        ),
      ),
    );

    return doc.save();
  }

  /// Opens the print / save-as-PDF preview. The receipt is rebuilt for
  /// whichever paper size the user selects in the dialog.
  static Future<void> printOrSave({
    required PaymentEntity payment,
    required AppSettingsEntity settings,
    String? userId,
    String? packageName,
  }) async {
    await Printing.layoutPdf(
      name: 'Receipt-${receiptNumber(payment, settings)}.pdf',
      format: PdfPageFormat.a5,
      onLayout: (format) => build(
        payment: payment,
        settings: settings,
        format: format,
        userId: userId,
        packageName: packageName,
      ),
    );
  }
}
