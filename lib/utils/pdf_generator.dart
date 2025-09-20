import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../controller/invoice_controller.dart';
import 'formatters.dart';
import '../services/firestore_service.dart';

class InvoicePdfGenerator {
  static Future<Uint8List> buildInvoice(InvoiceView v) async {
    final pdf = pw.Document();
    // ✅ Load your image bytes from assets
    final Uint8List logoBytes = await rootBundle
        .load('assets/Logo_white.png')
        .then((data) => data.buffer.asUint8List());

    // ✅ Convert image bytes into a pw.MemoryImage
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(margin: const pw.EdgeInsets.all(24)),
        build: (ctx) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            children: [
              pw.Text(
                'Invoice',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.SizedBox(
                height: 120,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          pw.SizedBox(height: 16),
          // Customer Information
          pw.Text(
            'Bill To:',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Name: ${v.customer?.name ?? 'Unknown'}'),
                pw.Text('Email: ${v.customer?.email ?? ''}'),
                pw.Text('Phone: ${v.customer?.phone ?? ''}'),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Invoice Info
          pw.Text(
            'Invoice Information:',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Invoice ID: ${v.invoice.id.toUpperCase()}'),
                pw.Text('Issue Date: ${dateLong.format(v.invoice.dateIssued)}'),
                pw.Text(
                  'Status: ${toBeginningOfSentenceCase(v.invoice.status)}',
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Job & Vehicle
          pw.Text(
            'Job & Vehicle Details:',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(v.job?.description ?? ''),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${v.vehicle?.make ?? ''} ${v.vehicle?.model ?? ''} (${v.vehicle?.year ?? ''}) - ${v.vehicle!.id.toUpperCase()}',
                ),
                pw.SizedBox(height: 2),
                pw.Text('VIN: ${v.vehicle?.vin ?? ''}'),
              ],
            ),
          ),

          pw.SizedBox(height: 16),

          // Items Table
          pw.Text(
            'Itemized Charges',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table.fromTextArray(
            headers: ['Description', 'Qty', 'Price', 'Amount'],
            cellStyle: pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.black),
            cellAlignment: pw.Alignment.centerLeft,
            data: v.invoice.items
                .map(
                  (i) => [
                    i.description,
                    '${i.quantity}',
                    rmCurrency.format(i.price),
                    rmCurrency.format(i.amount),
                  ],
                )
                .toList(),
          ),

          pw.SizedBox(height: 12),

          // Total Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                rmCurrency.format(v.invoice.totalAmount),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return pdf.save();
  }

  static Future<Uint8List> buildSummary(
    InvoiceController c, {
    int? selectedYear,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();

    // Allow selecting a year, default to current year
    final year = selectedYear ?? now.year;

    // Filter invoices by selected year
    final yearInvoices = c.invoices
        .where((v) => v.invoice.dateIssued.year == year)
        .toList();

    // Calculate totals
    final totalInvoices = yearInvoices.length;
    final paidInvoices = yearInvoices
        .where((v) => v.invoice.status == 'paid')
        .toList();
    final unpaidInvoices = yearInvoices
        .where((v) => v.invoice.status != 'paid')
        .toList();
    final totalAmountInvoiced = yearInvoices.fold(
      0.0,
      (s, v) => s + v.invoice.totalAmount,
    );
    final totalAmountPaid = paidInvoices.fold(
      0.0,
      (s, v) => s + v.invoice.totalAmount,
    );
    final totalOutstanding = unpaidInvoices.fold(
      0.0,
      (s, v) => s + v.invoice.totalAmount,
    );

    // Payment completion rate
    final completionRate = totalInvoices > 0
        ? (paidInvoices.length / totalInvoices * 100)
        : 0.0;

    // ✅ Load your image bytes from assets
    final Uint8List logoBytes = await rootBundle
        .load('assets/Logo_white.png')
        .then((data) => data.buffer.asUint8List());

    // ✅ Convert image bytes into a pw.MemoryImage
    final pw.MemoryImage logoImage = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(margin: pw.EdgeInsets.all(24)),
        build: (ctx) => [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.SizedBox(
                  height: 120,
                  child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                ),
                pw.Text(
                  'Invoice Summary Report',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 12),

          pw.Text(
            'Date Generated: ${DateFormat.yMMMMd().format(now)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Report Period: $year',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 16),

          // Table: List all invoices
          pw.Text(
            'Invoices for $year',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Table.fromTextArray(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey700),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // ID
              1: const pw.FlexColumnWidth(3), // Customer
              2: const pw.FlexColumnWidth(2), // Date
              3: const pw.FlexColumnWidth(2), // Status
              4: const pw.FlexColumnWidth(2), // Amount
            },
            headers: [
              'Invoice ID',
              'Customer',
              'Date',
              'Status',
              'Amount (RM)',
            ],
            data: yearInvoices.map((v) {
              return [
                v.invoice.id.toUpperCase(),
                v.customer?.name ?? 'Unknown',
                DateFormat.yMMMd().format(v.invoice.dateIssued),
                v.invoice.status == 'paid' ? 'Paid' : 'Unpaid',
                rmCurrency.format(v.invoice.totalAmount),
              ];
            }).toList(),
          ),

          pw.SizedBox(height: 20),

          // Summary Table
          pw.Text(
            'Summary',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey700),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            children: [
              _tableRow('Total Invoices', '$totalInvoices'),
              _tableRow('Paid Invoices', '${paidInvoices.length}'),
              _tableRow('Unpaid Invoices', '${unpaidInvoices.length}'),
              _tableRow(
                'Total Amount Invoiced',
                rmCurrency.format(totalAmountInvoiced),
              ),
              _tableRow(
                'Total Amount Paid',
                rmCurrency.format(totalAmountPaid),
              ),
              _tableRow(
                'Total Outstanding',
                rmCurrency.format(totalOutstanding),
              ),
              _tableRow(
                'Payment Completion Rate',
                '${completionRate.toStringAsFixed(1)} %',
              ),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.TableRow _tableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(value),
          ),
        ),
      ],
    );
  }

}
