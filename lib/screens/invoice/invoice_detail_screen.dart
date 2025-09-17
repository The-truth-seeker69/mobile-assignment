import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../controller/invoice_controller.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_generator.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';
import '../../utils/send_inv_email.dart';

class InvoiceDetailScreen extends StatelessWidget {
  final InvoiceView view;
  final InvoiceController controller;

  const InvoiceDetailScreen({
    super.key,
    required this.view,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final inv = view.invoice;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _kv(
            'INV-${inv.id.toUpperCase()}',
            DateFormat.yMMMMd().format(inv.dateIssued),
          ),
          _kv('Status', inv.approved == true ? 'Approved' : 'Unapproved'),
          const SizedBox(height: 12),
          _sectionTitle('Customer'),
          _box(
            children: [
              _kv('Customer Name', view.customer?.name ?? ''),
              _kv('Phone', view.customer?.phone ?? ''),
              _kv('Email', view.customer?.email ?? ''),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle('Job Details'),
          _box(
            children: [
              _kv('Job Description', view.job?.description ?? ''),
              _kv(
                'Vehicle',
                '${view.vehicle?.make ?? ''} ${view.vehicle?.model ?? ''} ${view.vehicle?.year != null ? '• ${view.vehicle!.year}' : ''}',
              ),
              _kv(
                'Service Date',
                view.job?.completionDate != null
                    ? dateLong.format(view.job!.completionDate!)
                    : '-',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _sectionTitle('Charges'),
          _box(
            children: [
              ...inv.items.map(
                (i) => _kv(
                  i.description,
                  '${i.quantity} x ${rmCurrency.format(i.price)}',
                ),
              ),
              const Divider(),
              _kv(
                'Total Amount',
                rmCurrency.format(inv.totalAmount),
                isBold: true,
              ),
              _kv('Payment Status', inv.status == 'paid' ? 'Paid' : 'Unpaid'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    final Uint8List bytes =
                        await InvoicePdfGenerator.buildInvoice(view);
                    await Printing.layoutPdf(onLayout: (format) async => bytes);
                  },
                  child: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: (inv.approved != true || view.customer?.email == null || view.customer!.email.isEmpty)
                      ? null
                      : () async {
                    final scaffold = ScaffoldMessenger.of(context);
                    try {
                      scaffold.showSnackBar(const SnackBar(content: Text('Generating PDF...')));
                      final pdfBytes = await InvoicePdfGenerator.buildInvoice(view);

                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(const SnackBar(content: Text('Sending invoice email...')));

                      await EmailService.sendInvoiceEmail(
                        to: view.customer!.email,
                        pdfBytes: pdfBytes,
                        invoiceId: inv.id,
                      );

                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(const SnackBar(content: Text('Invoice sent successfully')));
                    } catch (e) {
                      scaffold.hideCurrentSnackBar();
                      scaffold.showSnackBar(SnackBar(content: Text('Failed to send invoice: $e')));
                    }
                  },
                  style: FilledButton.styleFrom(backgroundColor: scheme.primary),
                  child: const Text('Send Invoice'),
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
    t,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  );

  Widget _box({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.black12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(children: children),
  );

  Widget _kv(String k, String v, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(k)),
        const SizedBox(width: 12),
        Text(
          v,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    ),
  );
}
