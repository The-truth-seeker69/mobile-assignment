import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';
import '../../widgets/bottom_navigation.dart';
import 'inventory_details.dart';
import 'add_inventory.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<InventoryItem> _inventoryItems = [];
  List<InventoryItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _loadInventoryItems();
  }

  void _loadInventoryItems() {
    // Sample data based on the screenshots
    _inventoryItems = [
      InventoryItem(
        id: '1',
        name: 'Brake Pad',
        partCode: 'BRK123',
        quantity: 5,
        category: 'Brake Components',
        supplier: 'AutoParts Co.',
        imagePath: 'assets/images/brake_pad.png',
        isLowStock: true,
        lastRefill: DateTime(2025, 7, 10),
        usageLog: [
          UsageLog(
            date: DateTime(2025, 7, 20),
            jobId: '1054',
            description: 'Used in Job #1054',
          ),
          UsageLog(
            date: DateTime(2025, 7, 15),
            jobId: '1043',
            description: 'Used in Job #1043',
          ),
          UsageLog(
            date: DateTime(2025, 7, 2),
            jobId: '1039',
            description: 'Used in Job #1039',
          ),
        ],
      ),
      InventoryItem(
        id: '2',
        name: 'Air Filter',
        partCode: 'AF456',
        quantity: 69,
        category: 'Engine Components',
        supplier: 'FilterPro Inc.',
        imagePath: 'assets/images/air_filter.png',
        isLowStock: false,
        lastRefill: DateTime(2025, 6, 15),
        usageLog: [],
      ),
    ];
    _filteredItems = List.from(_inventoryItems);
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = List.from(_inventoryItems);
      } else {
        _filteredItems = _inventoryItems
            .where((item) =>
        item.name.toLowerCase().contains(query.toLowerCase()) ||
            item.partCode.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Inventory',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterItems,
                      decoration: const InputDecoration(
                        hintText: 'Search by part name, code',
                        hintStyle: TextStyle(color: Colors.grey),
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.filter_list,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Inventory List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return _buildInventoryCard(item);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddInventoryScreen(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Add Inventory',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Colors.grey,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                if (item.isLowStock) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: Colors.red,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Low Stock',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // View Button
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => InventoryDetailsScreen(item: item),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }
}
