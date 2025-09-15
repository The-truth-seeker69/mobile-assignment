import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

class FirestoreInvoiceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _invoicesCol =>
      _db.collection('invoices');

  Stream<List<Invoice>> streamInvoices() {
    return _invoicesCol.snapshots().map((snap) {
      return snap.docs.map((d) => Invoice.fromMap(d.id, d.data())).toList();
    });
  }

  Future<void> approveInvoice(String invoiceId) async {
    await _invoicesCol.doc(invoiceId).set({
      'approved': true,
      'approvalDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> markInvoicePaid(String invoiceId) async {
    await _invoicesCol.doc(invoiceId).set({
      'status': 'paid',
      'paymentDate': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Customer?> getCustomer(String customerId) async {
    if (customerId.isEmpty) return null;
    final snap = await _db.collection('customers').doc(customerId).get();
    if (!snap.exists) return null;
    return Customer.fromMap(snap.id, snap.data()!);
  }

  Future<Job?> getJob(String jobId) async {
    if (jobId.isEmpty) return null;
    final snap = await _db.collection('jobs').doc(jobId).get();
    if (!snap.exists) return null;
    return Job.fromMap(snap.id, snap.data()!);
  }

  Future<Vehicle?> getVehicle(String vehicleId) async {
    if (vehicleId.isEmpty) return null;
    final snap = await _db.collection('vehicles').doc(vehicleId).get();
    if (!snap.exists) return null;
    return Vehicle.fromMap(snap.id, snap.data()!);
  }
}

class InvoiceView {
  final Invoice invoice;
  final Customer? customer;
  final Job? job;
  final Vehicle? vehicle;

  const InvoiceView({
    required this.invoice,
    required this.customer,
    required this.job,
    required this.vehicle,
  });
}