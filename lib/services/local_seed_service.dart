import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/models.dart';
import '../models/mechanic.dart';

class LocalSeedService {
  Map<String, dynamic>? _cache;

  Future<Map<String, dynamic>> _load() async {
    if (_cache != null) return _cache!;
    final String jsonStr = await rootBundle.loadString('lib/db/seed.json');
    _cache = json.decode(jsonStr) as Map<String, dynamic>;
    return _cache!;
  }

  Future<List<Vehicle>> getVehicles() async {
    final data = await _load();
    final Map<String, dynamic> vehicles = (data['vehicles'] as Map).cast<String, dynamic>();
    return vehicles.entries
        .map((e) => Vehicle.fromMap(e.key, (e.value as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final data = await _load();
    final Map<String, dynamic> customers = (data['customers'] as Map).cast<String, dynamic>();
    final Map<String, dynamic>? map = customers[id]?.cast<String, dynamic>();
    if (map == null) return null;
    return Customer.fromMap(id, map);
  }

  Future<List<Job>> getJobsForVehicle(String vehicleId) async {
    final data = await _load();
    final Map<String, dynamic> jobs = (data['jobs'] as Map).cast<String, dynamic>();
    return jobs.entries
        .map((e) => Job.fromMap(e.key, (e.value as Map).cast<String, dynamic>()))
        .where((j) => j.vehicleId == vehicleId)
        .toList();
  }

  Future<Mechanic?> getMechanicById(String id) async {
    final data = await _load();
    final Map<String, dynamic> mechanics = (data['mechanics'] as Map).cast<String, dynamic>();
    final Map<String, dynamic>? map = mechanics[id]?.cast<String, dynamic>();
    if (map == null) return null;
    return Mechanic.fromMap(id, map);
  }
}







