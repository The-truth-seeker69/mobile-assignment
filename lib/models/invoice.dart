class InvoiceItem {
  final String description;
  final int quantity;
  final double price;

  const InvoiceItem({
    required this.description,
    required this.quantity,
    required this.price,
  });

  double get amount => quantity * price;

  factory InvoiceItem.fromMap(Map<String, dynamic> m) => InvoiceItem(
    description: m['description'] ?? '',
    quantity: (m['quantity'] ?? 0) is int
        ? m['quantity']
        : int.tryParse('${m['quantity']}') ?? 0,
    price: (m['price'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'description': description,
    'quantity': quantity,
    'price': price,
  };
}

class Invoice {
  final String id;
  final String jobId;
  final String customerId;
  final DateTime dateIssued;
  final List<InvoiceItem> items;
  final double totalAmount;
  final String status; // 'paid' | 'unpaid'
  final DateTime? paymentDate;
  final bool approved;
  final DateTime? approvalDate;

  const Invoice({
    required this.id,
    required this.jobId,
    required this.customerId,
    required this.dateIssued,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentDate,
    required this.approved,
    required this.approvalDate,
  });

  factory Invoice.fromMap(String id, Map<String, dynamic> data) => Invoice(
    id: id,
    jobId: data['jobId'] ?? '',
    customerId: data['customerId'] ?? '',
    dateIssued: _toDate(data['dateIssued']) ?? DateTime.now(),
    items: (data['items'] as List? ?? [])
        .map((e) => InvoiceItem.fromMap(Map<String, dynamic>.from(e)))
        .toList(),
    totalAmount: (data['totalAmount'] ?? 0).toDouble(),
    status: data['status'] ?? 'unpaid',
    paymentDate: _toDate(data['paymentDate']),
    approved: data['approved'] == true,
    approvalDate: _toDate(data['approvalDate']),
  );

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    try {
      // Support Firestore Timestamp
      if (v is dynamic && v.toString().contains('Timestamp')) {
        final milliseconds = v.millisecondsSinceEpoch as int?;
        return milliseconds != null
            ? DateTime.fromMillisecondsSinceEpoch(milliseconds)
            : null;
      }
    } catch (_) {}
    return DateTime.tryParse('$v');
  }
}