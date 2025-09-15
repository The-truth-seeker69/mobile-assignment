import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../controller/invoice_controller.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_generator.dart';

class InvoiceReportScreen extends StatelessWidget {
  const InvoiceReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InvoiceController>();

    Widget tile(String title, String value) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ]),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Summary Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: 180, child: tile('Total Invoices', '${c.totalInvoices}')),
              SizedBox(width: 180, child: tile('Paid Invoices', '${c.paidInvoices}')),
              SizedBox(width: 180, child: tile('Unpaid Invoices', '${c.unpaidInvoices}')),
              SizedBox(width: 220, child: tile('Total Amount Invoiced', rmCurrency.format(c.totalInvoiced))),
              SizedBox(width: 220, child: tile('Total Amount Paid', rmCurrency.format(c.totalPaid))),
              SizedBox(width: 220, child: tile('Total Outstanding (Unpaid)', rmCurrency.format(c.totalOutstanding))),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () async {
              final Uint8List bytes = await InvoicePdfGenerator.buildSummary(c);
              await Printing.layoutPdf(onLayout: (format) async => bytes);
            },
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }
}