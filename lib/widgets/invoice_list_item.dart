import 'package:flutter/material.dart';
import '../controller/invoice_controller.dart';
import '../models/models.dart';
import '../utils/formatters.dart';
import '../screens/invoice/invoice_detail_screen.dart';
import '../services/firestore_service.dart';

class InvoiceListItem extends StatelessWidget {
  final InvoiceView view;
  final InvoiceController controller;

  const InvoiceListItem({super.key, required this.view, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleText =
    '${view.vehicle?.make ?? ''} ${view.vehicle?.model ?? ''}'.trim();
    final isApproved = view.invoice.approved;
    final isPaid = view.invoice.status == 'paid';

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: Text(
                (view.customer?.name.isNotEmpty ?? false)
                    ? view.customer!.name.substring(0, 1).toUpperCase()
                    : 'V',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(view.customer?.name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${view.invoice.id} • $vehicleText', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
              ]),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => InvoiceDetailScreen(view: view, controller: controller))),
              child: const Text('View'),
            ),
            const SizedBox(width: 8),
            if (!isApproved)
              FilledButton(
                onPressed: () => controller.approve(view.invoice.id),
                child: const Text('Approve'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(.12),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(.4)),
    ),
    child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}