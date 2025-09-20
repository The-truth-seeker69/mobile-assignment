import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class FirestoreVehicleService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _vehiclesCol => _db.collection('vehicles');

  Stream<List<Vehicle>> streamVehicles() {
    debugPrint('[FirestoreVehicleService] Subscribing to vehicles collection...');
    return _vehiclesCol.snapshots().map((snap) {
      debugPrint('[FirestoreVehicleService] vehicles snapshot: ${snap.docs.length} docs');
      return snap.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList();
    }).handleError((Object error, StackTrace st) {
      debugPrint('[FirestoreVehicleService] Error streaming vehicles: $error');
      debugPrint(st.toString());
    });
  }

  Future<Customer?> getCustomerById(String customerId) async {
    if (customerId.isEmpty) return null;
    final doc = await _db.collection('customers').doc(customerId).get();
    if (!doc.exists) return null;
    return Customer.fromMap(doc.id, doc.data()!);
  }

  Future<List<Job>> getJobsForVehicle(String vehicleId) async {
    final q = await _db.collection('jobs').where('vehicleId', isEqualTo: vehicleId).get();
    return q.docs.map((d) => Job.fromMap(d.id, d.data())).toList();
  }

  Future<Mechanic?> getMechanicById(String mechanicId) async {
    if (mechanicId.isEmpty) return null;
    final doc = await _db.collection('mechanics').doc(mechanicId).get();
    if (!doc.exists) return null;
    return Mechanic.fromMap(doc.id, doc.data()!);
  }
}


