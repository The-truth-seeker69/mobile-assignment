class Job {
  final String id;
  final String vehicleId;
  final String mechanicId;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? completionDate;
  final String description;
  final List<String> partsUsed;
  final int? mileage; // km
  final String? notes;

  const Job({
    required this.id,
    required this.vehicleId,
    required this.mechanicId,
    required this.status,
    required this.scheduledDate,
    required this.completionDate,
    required this.description,
    required this.partsUsed,
    this.mileage,
    this.notes,
  });

  factory Job.fromMap(String id, Map<String, dynamic> data) => Job(
    id: id,
    vehicleId: data['vehicleId'] ?? '',
    mechanicId: data['mechanicId'] ?? '',
    status: data['status'] ?? '',
    scheduledDate: _parseDate(data['scheduledDate']),
    completionDate: _parseDate(data['completionDate']),
    description: data['description'] ?? '',
    partsUsed: (data['partsUsed'] as List?)?.cast<String>() ?? const [],
    mileage: _parseInt(data['mileage']),
    notes: data['notes'],
  );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse('$v');
    // Firestore Timestamp will come through as Timestamp -> handle in service
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse('$v');
  }
}