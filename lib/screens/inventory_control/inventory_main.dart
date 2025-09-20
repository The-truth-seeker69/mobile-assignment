import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';
import 'inventory_details.dart';
import 'add_inventory.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<File?> getInventoryImage(String? filename) async {
  if (filename == null || filename.isEmpty) return null;

  // If it's an asset, return null (we'll handle in UI)
  if (filename.startsWith("assets/")) return null;

  // Otherwise look inside documents directory
  final appDir = await getApplicationDocumentsDirectory();
  final fullPath = '${appDir.path}/$filename';
  final file = File(fullPath);
  if (await file.exists()) return file;

  return null;
}

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory = "all"; // default

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
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search + Filter Row
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
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search by item name, category, supplier',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          suffixIcon:
                              _selectedCategory != null &&
                                  _selectedCategory != "all"
                              ? Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Chip(
                                    label: Text(
                                      _selectedCategory!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 16,
                                    ),
                                    onDeleted: () {
                                      setState(() => _selectedCategory = "all");
                                    },
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showCategoryFilter(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.filter_list, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),

            // 📦 Inventory List
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                // leave space for FAB
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('inventory')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("No inventory items found"),
                      );
                    }

                    final items = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return InventoryItem(
                        id: doc.id,
                        name: data['name'] ?? '',
                        quantity: data['quantity'] ?? 0,
                        category: data['category'] ?? '',
                        supplier: data['supplier'] ?? '',
                        imagePath: data['imagePath'] ?? '',
                        isLowStock: data['isLowStock'] ?? false,
                        lastRefill: data['lastRefill'] != null
                            ? (data['lastRefill'] as Timestamp).toDate()
                            : null,
                        usageLog: [],
                      );
                    }).toList();

                    // 🔍 Filtering
                    final query = _searchController.text.toLowerCase();
                    List<InventoryItem> filtered = items.where((item) {
                      return item.name.toLowerCase().contains(query) ||
                          item.category.toLowerCase().contains(query) ||
                          item.supplier.toLowerCase().contains(query);
                    }).toList();

                    if (_selectedCategory != null &&
                        _selectedCategory != "all") {
                      filtered = filtered
                          .where(
                            (item) =>
                                item.category.toLowerCase() ==
                                _selectedCategory!.toLowerCase(),
                          )
                          .toList();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildInventoryCard(filtered[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),

      // ➕ Add Inventory button
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /// 🔹 Show category filter modal
  void _showCategoryFilter(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        final categories = [
          "All",
          "Brake",
          "Engine",
          "Transmission",
          "Electrical",
          "Suspension",
          "Body",
          "Interior",
          "Other",
        ];
        return SafeArea(
          child: ListView(
            shrinkWrap: true, // ✅ only take needed height
            children: categories.map((cat) {
              return ListTile(
                title: Text(
                  cat[0].toUpperCase() + cat.substring(1),
                  style: TextStyle(
                    fontWeight: _selectedCategory == cat
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                trailing: _selectedCategory == cat
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
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
          // 📷 Item Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),

            child: item.imagePath.startsWith("assets/")
                ? Image.asset(
                    item.imagePath,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : FutureBuilder<File?>(
                    future: getInventoryImage(item.imagePath),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.file(
                          snapshot.data!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        );
                      }
                      return const Icon(
                        Icons.inventory_2,
                        color: Colors.grey,
                        size: 30,
                      );
                    },
                  ),
          ),
          const SizedBox(width: 16),

          // 📝 Item Details
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
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                if (item.isLowStock) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: const [
                      Icon(Icons.warning, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text(
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

          // 🔍 View Button
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
