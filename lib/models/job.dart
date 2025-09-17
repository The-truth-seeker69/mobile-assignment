class Job {
  final String id;
  final String vehicleId;
  final String mechanicId;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? completionDate;
  final String description;
  final List<String> partsUsed;

  const Job({
    required this.id,
    required this.vehicleId,
    required this.mechanicId,
    required this.status,
    required this.scheduledDate,
    required this.completionDate,
    required this.description,
    required this.partsUsed,
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
  );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse('$v');
    // Firestore Timestamp will come through as Timestamp -> handle in service
  }
}