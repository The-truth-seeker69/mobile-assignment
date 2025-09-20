import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/customer.dart';
import '../../services/firestore_service.dart';
import '../../widgets/bottom_navigation.dart';
import 'customer_profile_screen.dart';

class CrmListScreen extends StatefulWidget {
  const CrmListScreen({super.key});

  @override
  State<CrmListScreen> createState() => _CrmListScreenState();
}

class _CrmListScreenState extends State<CrmListScreen> {
  final FirestoreCrmService _service = FirestoreCrmService();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        backgroundColor: const Color(0xfff5f5f5),
        elevation: 0,
        centerTitle: true,
        title: const Text('Customer'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xfff2f3fb),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: _service.streamCustomers(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!
                    .where((c) => _query.isEmpty || c.name.toLowerCase().contains(_query) || c.id.toLowerCase().contains(_query))
                    .toList();
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final c = list[i];
                    return _CustomerTile(customer: c, onView: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CustomerProfileScreen(customerId: c.id)),
                      );
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onView;
  const _CustomerTile({required this.customer, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildAvatar(customer.imagePath, 56),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(customer.id.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(customer.name, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text('View'),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildAvatar(String path, double size) {
  final assetPath = path.isNotEmpty ? 'assets/images/crm/$path' : '';
  return Container(
    width: size,
    height: size,
    color: const Color(0xffe6e6e6),
    child: assetPath.isEmpty
        ? const Icon(Icons.person, color: Colors.grey)
        : Image.asset(
            assetPath,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey),
          ),
  );
}


