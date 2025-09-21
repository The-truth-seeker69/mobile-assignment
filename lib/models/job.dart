class Job {
  final String id;
  final String? customerId;
  final String vehicleId;
  final String? mechanicId;
  final String status;
  final DateTime? scheduledDate;
  final DateTime? scheduledTime;
  final DateTime? completionDate;
  final String description;
  final List<String> partsUsed;
  final int? mileage;
  final String? notes;

  const Job({
    required this.id,
    this.customerId,
    required this.vehicleId,
    this.mechanicId,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.completionDate,
    required this.description,
    required this.partsUsed,
    this.mileage,
    this.notes,
  });

  factory Job.fromMap(String id, Map<String, dynamic> data) =>
      Job(
        id: id,
        customerId: data['customerId'] ?? '',
        vehicleId: data['vehicleId'] ?? '',
        mechanicId: data['mechanicId'] as String?,
        status: data['status'] ?? '',
        scheduledDate: _parseDate(data['scheduledDate']),
        scheduledTime: _parseDate(data['scheduledTime']),
        completionDate: _parseDate(data['completionDate']),
        description: data['description'] ?? '',
        partsUsed: (data['partsUsed'] as List?)?.cast<String>() ?? const [],
        mileage: data['mileage'] as int?,
        notes: data['notes'] as String?,
      );

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'vehicleId': vehicleId,
      'mechanicId': mechanicId,
      'status': status,
      'scheduledDate': scheduledDate?.toIso8601String(),
      'scheduledTime': scheduledTime?.toIso8601String(),
      'completionDate': completionDate?.toIso8601String(),
      'description': description,
      'partsUsed': partsUsed,
      'mileage': mileage,
      'notes': notes,
    };
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;

    if (v is String) {
      // Try to parse as ISO string first
      final isoDate = DateTime.tryParse(v);
      if (isoDate != null) return isoDate;
      
      // Try to parse as "YYYY-MM-DD" format
      final parts = v.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
      
      // Expecting "HH:mm" string
      final timeParts = v.split(':');
      if (timeParts.length == 2) {
        final now = DateTime.now();
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        // use today's date with given time
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    }

    return null;
  }

}