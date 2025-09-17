import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/firestore_service.dart';

enum StatusFilter { paid, unpaid }
enum ApprovalFilter { approved, unapproved }

class InvoiceController extends ChangeNotifier {
  final FirestoreInvoiceService _svc = FirestoreInvoiceService();

  StreamSubscription? _sub;
  List<InvoiceView> _all = [];
  String _search = '';
  StatusFilter? _status;       // <-- nullable
  ApprovalFilter? _approval;   // <-- nullable
  bool _loading = false;

  List<InvoiceView> get invoices => _filtered();
  bool get isLoading => _loading;
  String get search => _search;
  StatusFilter? get statusFilter => _status;
  ApprovalFilter? get approvalFilter => _approval;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _sub?.cancel();
    _sub = _svc.streamInvoices().listen((list) async {
      final views = <InvoiceView>[];
      for (final inv in list) {
        final job = await _svc.getJob(inv.jobId);
        final vehicle = await _svc.getVehicle(job?.vehicleId ?? '');
        final customer = await _svc.getCustomer(inv.customerId);
        views.add(InvoiceView(
          invoice: inv,
          customer: customer,
          job: job,
          vehicle: vehicle,
        ));
      }
      _all = views;
      _loading = false;
      notifyListeners();
    });
  }

  void setSearch(String v) {
    _search = v.trim();
    notifyListeners();
  }

  void toggleStatus(StatusFilter f) {
    // Clicking same filter again -> remove filter
    if (_status == f) {
      _status = null;
    } else {
      _status = f;
    }
    notifyListeners();
  }

  void toggleApproval(ApprovalFilter f) {
    if (_approval == f) {
      _approval = null;
    } else {
      _approval = f;
    }
    notifyListeners();
  }

  Future<void> approve(String id) async {
    await _svc.approveInvoice(id);
  }

  List<InvoiceView> _filtered() {
    Iterable<InvoiceView> it = _all;

    if (_status != null) {
      it = it.where((v) =>
      _status == StatusFilter.paid ? v.invoice.status == 'paid' : v.invoice.status != 'paid');
    }

    if (_approval != null) {
      it = it.where((v) =>
      _approval == ApprovalFilter.approved ? v.invoice.approved : !v.invoice.approved);
    }

    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      it = it.where((v) {
        final name = v.customer?.name.toLowerCase() ?? '';
        final invId = v.invoice.id.toLowerCase();
        final veh = '${v.vehicle?.make} ${v.vehicle?.model}'.toLowerCase();
        final plate = v.vehicle?.id.toLowerCase() ?? ''; // vehicle plate number
        return name.contains(q) || invId.contains(q) || veh.contains(q) || plate.contains(q);
      });
    }

    return it.toList()..sort((a, b) => b.invoice.dateIssued.compareTo(a.invoice.dateIssued));
  }

  // Aggregates for report
  int get totalInvoices => _all.length;
  int get paidInvoices => _all.where((v) => v.invoice.status == 'paid').length;
  int get unpaidInvoices => _all.where((v) => v.invoice.status != 'paid').length;
  double get totalInvoiced =>
      _all.fold(0.0, (s, v) => s + v.invoice.totalAmount);
  double get totalPaid => _all
      .where((v) => v.invoice.status == 'paid')
      .fold(0.0, (s, v) => s + v.invoice.totalAmount);
  double get totalOutstanding => totalInvoiced - totalPaid;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
