class Vehicle {
  final String id;
  final String customerId;
  final String make;
  final String model;
  final int year;
  final String vin;

  const Vehicle({
    required this.id,
    required this.customerId,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
  });

  factory Vehicle.fromMap(String id, Map<String, dynamic> data) {
    final dynamic y = data['year'];
    final int year = y is int ? y : int.tryParse('$y') ?? 0;
    return Vehicle(
      id: id,
      customerId: data['customerId'] ?? '',
      make: data['make'] ?? '',
      model: data['model'] ?? '',
      year: year,
      vin: data['vin'] ?? '',
    );
  }
}