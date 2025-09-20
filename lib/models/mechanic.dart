class Mechanic {
  final String id;
  final String name;
  final String specialization;
  final bool availability;

  const Mechanic({
    required this.id,
    required this.name,
    required this.specialization,
    required this.availability,
  });

  factory Mechanic.fromMap(String id, Map<String, dynamic> data) => Mechanic(
    id: id,
    name: data['name'] ?? '',
    specialization: data['specialization'] ?? '',
    availability: data['availability'] == true,
  );
}







