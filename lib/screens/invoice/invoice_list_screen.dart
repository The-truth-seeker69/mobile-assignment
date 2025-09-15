import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controller/invoice_controller.dart';
import '../../widgets/invoice_list_item.dart';
import 'invoice_report_screen.dart';
import '../../widgets/bottom_navigation.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState  extends State<InvoicesListScreen> {

  int _selectedIndex = 3; // ✅ Invoices tab is selected by default

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);

    // Navigate based on index
    switch (index) {
      case 0:
      // Go to Inventory page
        Navigator.pushNamed(context, '/inventory');
        break;
      case 1:
      // Go to Scheduler page
        Navigator.pushNamed(context, '/scheduler');
        break;
      case 2:
      // Go to Vehicles page
        Navigator.pushNamed(context, '/vehicles');
        break;
      case 3:
      // Already on Invoices page (do nothing)
        break;
      case 4:
      // Go to CRM page
        Navigator.pushNamed(context, '/crm');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<InvoiceController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SearchBar(
                hintText: 'Search by ID, Name, Plate or Model',
                leading: const Icon(Icons.search),
                onChanged: c.setSearch,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Status:'),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      side: BorderSide.none,
                      label: const Text('All'),
                      selected: c.statusFilter == StatusFilter.all,
                      onSelected: (_) => c.setStatus(StatusFilter.all),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      side: BorderSide.none,
                      label: const Text('Paid'),
                      selected: c.statusFilter == StatusFilter.paid,
                      onSelected: (_) => c.setStatus(StatusFilter.paid),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      side: BorderSide.none,
                      label: const Text('Unpaid'),
                      selected: c.statusFilter == StatusFilter.unpaid,
                      onSelected: (_) => c.setStatus(StatusFilter.unpaid),
                    ),
                    const SizedBox(width: 16),
                    const Text('Approval:'),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      side: BorderSide.none,
                      label: const Text('Unapproved'),
                      selected: c.approvalFilter == ApprovalFilter.unapproved,
                      onSelected: (_) => c.setApproval(ApprovalFilter.unapproved),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      side: BorderSide.none,
                      label: const Text('Approved'),
                      selected: c.approvalFilter == ApprovalFilter.approved,
                      onSelected: (_) => c.setApproval(ApprovalFilter.approved),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: c.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: c.invoices.length,
                itemBuilder: (ctx, i) => InvoiceListItem(view: c.invoices[i], controller: c),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00B050)),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InvoiceReportScreen())),
                  child: const Text('Generate Report'),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            ),

          ],
        ),
      ),
    );
  }
}