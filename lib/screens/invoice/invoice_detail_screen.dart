import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../controller/invoice_controller.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_generator.dart';
import '../../services/firestore_service.dart';
import 'package:intl/intl.dart';
import '../../utils/send_inv_email.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final InvoiceView view;
  final InvoiceController controller;

  const InvoiceDetailScreen({
    super.key,
    required this.view,
    required this.controller,
  });

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  late InvoiceView view;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    view = widget.view;
  }

  Future<void> _refreshFromController({Duration timeout = const Duration(seconds: 3)}) async {
    // Poll controller.invoices for updated InvoiceView for up to [timeout].
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      try {
        final updated = widget.controller.invoices.firstWhere((v) => v.invoice.id == view.invoice.id);
        setState(() => view = updated);
        return;
      } catch (_) {
        // not found yet
      }
      await Future.delayed(const Duration(milliseconds: 250));
    }
  }

  Future<void> _approveInvoice() async {
    final scaffold = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);

    try {
      scaffold.showSnackBar(const SnackBar(content: Text('Approving invoice...')));

      // Call approve in Firestore
      await widget.controller.approve(view.invoice.id);
      await widget.controller.load();

      // Immediately update state with fresh invoice data
      await _refreshFromController(timeout: const Duration(seconds: 5));

      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(const SnackBar(content: Text('Invoice approved')));
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(content: Text('Failed to approve: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _sendInvoice() async {
    final scaffold = ScaffoldMessenger.of(context);
    setState(() => _isProcessing = true);
    try {
      scaffold.showSnackBar(const SnackBar(content: Text('Generating PDF...')));
      final pdfBytes = await InvoicePdfGenerator.buildInvoice(view);

      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(const SnackBar(content: Text('Sending invoice email...')));

      await EmailService.sendInvoiceEmail(
        to: view.customer!.email,
        pdfBytes: pdfBytes,
        invoiceId: view.invoice.id,
      );

      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(const SnackBar(content: Text('Invoice sent successfully')));
    } catch (e) {
      scaffold.hideCurrentSnackBar();
      scaffold.showSnackBar(SnackBar(content: Text('Failed to send invoice: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = view.invoice;
    final scheme = Theme.of(context).colorScheme;
    final scaffold = ScaffoldMessenger.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isProcessing ? null : () async {
              setState(() => _isProcessing = true);
              await widget.controller.load();
              await _refreshFromController(timeout: const Duration(seconds: 3));
              setState(() => _isProcessing = false);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await widget.controller.load();
          await _refreshFromController(timeout: const Duration(seconds: 3));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(child: _sectionTitle(inv.id.toUpperCase())),
            _kv('Invoice Date', DateFormat.yMMMMd().format(inv.dateIssued)),
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
                  '${view.vehicle?.make ?? ''} ${view.vehicle?.model ?? ''} ${view.vehicle?.year != null ? '(${view.vehicle!.year}) - ${view.vehicle!.id.toUpperCase()}' : ''}',
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
                _kv('Total Amount', rmCurrency.format(inv.totalAmount), isBold: true),
                _kv('Payment Status', inv.status == 'paid' ? 'Paid' : 'Unpaid'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                      final Uint8List bytes =
                      await InvoicePdfGenerator.buildInvoice(view);
                      await Printing.layoutPdf(onLayout: (format) async => bytes);
                    },
                    child: const Text('Download PDF'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: inv.approved != true
                      ? FilledButton(
                    onPressed: _isProcessing ? null : _approveInvoice,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.black,
                    ),
                    child: _isProcessing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Approve'),
                  )
                      : FilledButton(
                    onPressed: (_isProcessing || view.customer?.email == null || view.customer!.email.isEmpty)
                        ? null
                        : _sendInvoice,
                    style: FilledButton.styleFrom(backgroundColor: scheme.primary),
                    child: _isProcessing
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send Invoice'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
