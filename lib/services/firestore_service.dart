import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:async/async.dart';
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

/// CRM-specific queries and chat helpers
class FirestoreCrmService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _customersCol =>
      _db.collection('customers');
  CollectionReference<Map<String, dynamic>> get _vehiclesCol =>
      _db.collection('vehicles');
  CollectionReference<Map<String, dynamic>> get _jobsCol =>
      _db.collection('jobs');

  Stream<List<Customer>> streamCustomers() {
    return _customersCol.orderBy('name').snapshots().map((s) =>
        s.docs.map((d) => Customer.fromMap(d.id, d.data())).toList());
  }

  Future<Customer?> getCustomer(String id) async {
    final snap = await _customersCol.doc(id).get();
    if (!snap.exists) return null;
    return Customer.fromMap(snap.id, snap.data()!);
  }

  Stream<List<Vehicle>> streamVehiclesForCustomer(String customerId) {
    return _vehiclesCol
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((s) => s.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Job>> streamJobsForVehicles(List<String> vehicleIds) {
    if (vehicleIds.isEmpty) {
      return const Stream.empty();
    }
    final chunks = <List<String>>[];
    for (var i = 0; i < vehicleIds.length; i += 10) {
      chunks.add(vehicleIds.sublist(i, i + 10 > vehicleIds.length ? vehicleIds.length : i + 10));
    }
    final streams = chunks.map((chunk) => _jobsCol.where('vehicleId', whereIn: chunk).snapshots().map(
          (s) => s.docs.map((d) => Job.fromMap(d.id, d.data())).toList(),
        ));
    return StreamZip<List<Job>>(streams).map((lists) => lists.expand((e) => e).toList());
  }

  /// Chat collections: chats/{customerId}/messages/documents/items/{messageId}
  CollectionReference<Map<String, dynamic>> _chatMessages(String customerId) =>
      _db.collection('chats').doc(customerId).collection('messages').doc('documents');

  Stream<List<Map<String, dynamic>>> streamChatMessages(String customerId) {
    return _chatMessages(customerId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => {...d.data(), 'id': d.id}).toList());
  }

  Future<void> sendTextMessage({
    required String customerId,
    required String sender,
    required String text,
  }) async {
    await _chatMessages(customerId).add({
      'type': 'text',
      'text': text,
      'sender': sender,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendAttachmentMessage({
    required String customerId,
    required String sender,
    required String url,
    required String fileName,
    required String mimeType,
    String messageType = 'file', // 'image' | 'file'
  }) async {
    await _chatMessages(customerId).add({
      'type': messageType,
      'url': url,
      'fileName': fileName,
      'mimeType': mimeType,
      'sender': sender,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
