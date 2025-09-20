class Customer {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String imagePath;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.imagePath = '',
  });

  factory Customer.fromMap(String id, Map<String, dynamic> data) => Customer(
    id: id,
    name: data['name'] ?? '',
    phone: data['phone'] ?? '',
    email: data['email'] ?? '',
    address: data['address'] ?? '',
    imagePath: data['imagePath'] ?? '',
  );
}