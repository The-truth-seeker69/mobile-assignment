class Job {
  final String id;
  final String customerId;
  final String vehicleId;
  final String mechanicId;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? scheduledTime;
  final DateTime? completionDate;
  final String description;
  final List<String> partsUsed;

  const Job({
    required this.id,
    required this.customerId,
    required this.vehicleId,
    required this.mechanicId,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.completionDate,
    required this.description,
    required this.partsUsed,
  });

  factory Job.fromMap(String id, Map<String, dynamic> data) =>
      Job(
        id: id,
        customerId: data['customerId'] ?? '',
        vehicleId: data['vehicleId'] ?? '',
        mechanicId: data['mechanicId'] ?? '',
        status: data['status'] ?? '',
        scheduledDate: _parseDate(data['scheduledDate']),
        scheduledTime: _parseDate(data['scheduledTime']),
        completionDate: _parseDate(data['completionDate']),
        description: data['description'] ?? '',
        partsUsed: (data['partsUsed'] as List?)?.cast<String>() ?? const [],
      );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;

    if (v is String) {
      // Expecting "HH:mm" string
      final parts = v.split(':');
      if (parts.length == 2) {
        final now = DateTime.now();
        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;
        // use today's date with given time
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
      // Fallback for full ISO strings
      return DateTime.tryParse(v);
    }

    return null;
  }

}