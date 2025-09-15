import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../controller/invoice_controller.dart';
import '../models/models.dart';
import 'formatters.dart';
import '../services/firestore_service.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> buildInvoice(InvoiceView v) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (ctx) => [
          pw.Text('Invoice', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text('Invoice ID: ${v.invoice.id}'),
              pw.Text('Date: ${dateLong.format(v.invoice.dateIssued)}'),
              pw.Text('Status: ${toBeginningOfSentenceCase(v.invoice.status)}'),
              pw.Text('Approved: ${v.invoice.approved ? 'Yes' : 'No'}'),
            ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(v.customer?.name ?? 'Unknown'),
              pw.Text(v.customer?.email ?? ''),
              pw.Text(v.customer?.phone ?? ''),
            ]),
          ]),
          pw.SizedBox(height: 16),
          pw.Text('Job & Vehicle', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text(v.job?.description ?? ''),
          pw.Text('${v.vehicle?.make ?? ''} ${v.vehicle?.model ?? ''} (${v.vehicle?.year ?? ''}) • VIN ${v.vehicle?.vin ?? ''}'),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: ['Description', 'Qty', 'Price', 'Amount'],
            data: v.invoice.items
                .map((i) => [i.description, '${i.quantity}', rmCurrency.format(i.price), rmCurrency.format(i.amount)])
                .toList(),
          ),
          pw.SizedBox(height: 8),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text('Total', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text(rmCurrency.format(v.invoice.totalAmount), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ]),
          ]),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> buildSummary(InvoiceController c) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Invoice Summary Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text('Date Generated: ${DateFormat.yMMMMd().format(DateTime.now())}'),
            pw.SizedBox(height: 16),
            _metric('Total Invoices', '${c.totalInvoices}'),
            _metric('Paid Invoices', '${c.paidInvoices}'),
            _metric('Unpaid Invoices', '${c.unpaidInvoices}'),
            _metric('Total Amount Invoiced', rmCurrency.format(c.totalInvoiced)),
            _metric('Total Amount Paid', rmCurrency.format(c.totalPaid)),
            _metric('Total Outstanding (Unpaid)', rmCurrency.format(c.totalOutstanding)),
          ],
        ),
      ),
    );
    return pdf.save();
  }

  static pw.Widget _metric(String label, String value) => pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [pw.Text(label), pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))],
    ),
  );
}