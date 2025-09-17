import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart'; // ✅ Add this
import '../../controller/invoice_controller.dart';
import '../../utils/formatters.dart';
import '../../utils/pdf_generator.dart';

class InvoiceReportScreen extends StatefulWidget {
  const InvoiceReportScreen({super.key});

  @override
  State<InvoiceReportScreen> createState() => _InvoiceReportScreenState();
}

class _InvoiceReportScreenState extends State<InvoiceReportScreen> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InvoiceController>();

    final filteredInvoices = c.invoices
        .where((v) => v.invoice.dateIssued.year == _selectedYear)
        .toList();

    final totalInvoices = filteredInvoices.length;
    final paidInvoices =
        filteredInvoices.where((v) => v.invoice.status == 'paid').length;
    final unpaidInvoices = totalInvoices - paidInvoices;
    final totalInvoiced = filteredInvoices.fold(0.0, (s, v) => s + v.invoice.totalAmount);
    final totalPaid = filteredInvoices
        .where((v) => v.invoice.status == 'paid')
        .fold(0.0, (s, v) => s + v.invoice.totalAmount);
    final totalOutstanding = totalInvoiced - totalPaid;

    final String dateGenerated = dateLong.format(DateTime.now());

    Widget tile(String title, String value) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    );

    Widget rowOfTiles(Widget left, Widget right) => Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );

    Widget pieChart() {
      if (totalInvoices == 0) {
        return const Text(
          'No invoices for this year',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        );
      }

      return SizedBox(
        height: 200,
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 40,
            sections: [
              PieChartSectionData(
                value: paidInvoices.toDouble(),
                color: Colors.green,
                title: '${((paidInvoices / totalInvoices) * 100).toStringAsFixed(0)}%',
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              PieChartSectionData(
                value: unpaidInvoices.toDouble(),
                color: Colors.red,
                title: '${((unpaidInvoices / totalInvoices) * 100).toStringAsFixed(0)}%',
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Summary Report')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(
              'AutoFix Garage',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // YEAR SELECTOR
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Year:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              DropdownButton<int>(
                value: _selectedYear,
                items: List.generate(
                  5,
                      (i) {
                    final year = DateTime.now().year - i;
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  },
                ),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedYear = value);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Date Generated', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(dateGenerated),
              const SizedBox(height: 8),
              Text('Report Period', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(_selectedYear.toString()),
              const SizedBox(height: 20),
            ],
          ),

          // PIE CHART
          Center(child: pieChart()),
          const SizedBox(height: 16),

          // METRICS
          rowOfTiles(
            tile('Total Invoices', '$totalInvoices'),
            tile('Paid Invoices', '$paidInvoices'),
          ),
          const SizedBox(height: 12),
          tile('Unpaid Invoices', '$unpaidInvoices'),

          const SizedBox(height: 12),

          rowOfTiles(
            tile('Total Amount Invoiced', rmCurrency.format(totalInvoiced)),
            tile('Total Amount Received', rmCurrency.format(totalPaid)),
          ),

          const SizedBox(height: 12),
          tile('Total Outstanding (Unpaid)', rmCurrency.format(totalOutstanding)),

          const SizedBox(height: 20),

          // EXTRA INSIGHTS
          if (totalInvoices > 0) ...[
            Text(
              'Payment Completion Rate: ${(paidInvoices / totalInvoices * 100).toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Average Invoice Amount: RM ${(totalInvoiced / totalInvoices).toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
          ],

          FilledButton(
            onPressed: () async {
              final Uint8List bytes = await InvoicePdfGenerator.buildSummary(
                c,
                selectedYear: _selectedYear,
              );
              await Printing.layoutPdf(onLayout: (format) async => bytes);
            },
            child: const Text('Download PDF'),
          ),
        ],
      ),
    );
  }
}
