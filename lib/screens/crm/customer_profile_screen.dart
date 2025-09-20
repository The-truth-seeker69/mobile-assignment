import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_service.dart';
import 'chat_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  final String customerId;
  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final FirestoreCrmService _crm = FirestoreCrmService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Customer Profile'),
      ),
      body: StreamBuilder<Customer?>(
        stream: _crm.getCustomer(widget.customerId).asStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final customer = snap.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildAvatar(customer.imagePath, 44),
                      ),
                      const SizedBox(width: 8),
                      const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff29c26c), shape: StadiumBorder()),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ChatScreen(customerId: customer.id, customerName: customer.name)),
                          );
                        },
                        child: const Text('Chat Customer'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.phone_outlined)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _kv('Owner', customer.name),
                  _kv('Phone No', customer.phone),
                  _kv('Email', customer.email),
                  const SizedBox(height: 16),
                  const Text('Cars Owned', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Vehicle>>(
                    stream: _crm.streamVehiclesForCustomer(customer.id),
                    builder: (context, vsnap) {
                      if (!vsnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final vehicles = vsnap.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < vehicles.length; i++) _vehicleItem(i + 1, vehicles[i]),
                          const SizedBox(height: 8),
                          _serviceHistory(vehicles),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(children: [Text('$k  : '), Expanded(child: Text(v))]),
    );
  }

  Widget _vehicleItem(int idx, Vehicle v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$idx. ${v.make} ${v.model}'),
        _kv('Plate No', v.id.toUpperCase()),
        _kv('VIN', v.vin),
      ]),
    );
  }

  Widget _serviceHistory(List<Vehicle> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.miscellaneous_services_outlined, size: 18),
            const SizedBox(width: 6),
            const Text('Service History', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.filter_list), label: const Text('Filter')),
          ],
        ),
        const SizedBox(height: 8),
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _queryJobs(vehicles.map((e) => e.id).toList()),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: LinearProgressIndicator());
            }
            final jobs = snap.data!.docs.map((d) => Job.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => (b.scheduledDate ?? DateTime(0)).compareTo(a.scheduledDate ?? DateTime(0)));
            if (jobs.isEmpty) return const Text('No history');
            return Column(
              children: jobs.map((j) => _jobTile(j)).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _queryJobs(List<String> vehicleIds) {
    final col = FirebaseFirestore.instance.collection('jobs');
    if (vehicleIds.isEmpty) return col.where('vehicleId', isEqualTo: '__none__').get();
    final limit = vehicleIds.length > 10 ? vehicleIds.sublist(0, 10) : vehicleIds;
    return col.where('vehicleId', whereIn: limit).get();
  }

  Widget _jobTile(Job j) {
    final dateStr = (j.scheduledDate ?? j.completionDate)?.toIso8601String().split('T').first ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('$dateStr | ${j.description}'),
        _kv('Mechanic', j.mechanicId),
        _kv('Status', j.status),
      ]),
    );
  }
}


