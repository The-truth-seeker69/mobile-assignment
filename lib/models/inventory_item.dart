class InventoryItem {
  final String id;
  final String name;
  final String partCode;
  final int quantity;
  final String category;
  final String supplier;
  final String imagePath;
  final bool isLowStock;
  final DateTime lastRefill;
  final List<UsageLog> usageLog;

  InventoryItem({
    required this.id,
    required this.name,
    required this.partCode,
    required this.quantity,
    required this.category,
    required this.supplier,
    required this.imagePath,
    required this.isLowStock,
    required this.lastRefill,
    required this.usageLog,
  });
}

class UsageLog {
  final DateTime date;
  final String jobId;
  final String description;

  UsageLog({
    required this.date,
    required this.jobId,
    required this.description,
  });
}
