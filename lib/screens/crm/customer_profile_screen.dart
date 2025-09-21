import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Customer Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<Customer?>(
        stream: _crm.getCustomer(widget.customerId).asStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final customer = snap.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // Customer ID Header
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      customer.id,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Customer Details Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Header Row
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _buildAvatar(customer.imagePath, 32),
                            ),
                            const SizedBox(width: 8),
                            const Text('Customer Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff29c26c),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ChatScreen(customerId: customer.id, customerName: customer.name)),
                                );
                              },
                              child: const Text('Chat Customer', style: TextStyle(fontSize: 12, color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () => _callNumber(customer.phone),
                              icon: const Icon(Icons.phone, color: Colors.black, size: 20),
                            ),
                          ],
                        ),
                      ),
                      // Details
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          children: [
                            _detailRow('Owner', customer.name),
                            const SizedBox(height: 8),
                            _detailRow('Phone No', customer.phone),
                            const SizedBox(height: 8),
                            _detailRow('Email', customer.email),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Cars Owned and Service History
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Cars Owned Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_car, color: Colors.black, size: 20),
                            const SizedBox(width: 8),
                            const Text('Cars Owned', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ),
                      // Vehicles List
                      StreamBuilder<List<Vehicle>>(
                        stream: _crm.streamVehiclesForCustomer(customer.id),
                        builder: (context, vsnap) {
                          if (!vsnap.hasData) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final vehicles = vsnap.data!;
                          return Column(
                            children: [
                              for (var i = 0; i < vehicles.length; i++) _vehicleItem(i + 1, vehicles[i]),
                              const SizedBox(height: 16),
                              _serviceHistory(vehicles),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
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

  Widget _detailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label : ',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ],
    );
  }


  Widget _vehicleItem(int idx, Vehicle v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$idx. ${v.make} ${v.model} ${v.year}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Plate No: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: v.plateNumber),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  children: [
                    const TextSpan(text: 'VIN: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: v.vin),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _serviceHistory(List<Vehicle> vehicles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Service History Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.miscellaneous_services_outlined, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              const Text('Service History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: _openFilter,
                icon: const Icon(Icons.filter_list, size: 16), 
                label: const Text('Filter'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        // Divider
        Container(
          height: 1,
          color: Colors.grey[300],
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        // Service History Items
        FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
          future: _queryJobs(vehicles.map((e) => e.id).toList()),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: LinearProgressIndicator());
            }
            final jobs = snap.data!.docs.map((d) => Job.fromMap(d.id, d.data())).toList()
              ..sort((a, b) => (b.scheduledDate ?? DateTime(0)).compareTo(a.scheduledDate ?? DateTime(0)));
            if (jobs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: Text(
                    'No service history available',
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                ),
              );
            }
            return Column(
              children: [
                for (var i = 0; i < _filteredJobs(jobs).length; i++) ...[
                  _jobTile(_filteredJobs(jobs)[i]),
                  if (i < _filteredJobs(jobs).length - 1)
                    Container(
                      height: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  String _jobFilter = 'All'; // All, Upcoming, Completed

  List<Job> _filteredJobs(List<Job> jobs) {
    List<Job> list = List.of(jobs);
    if (_jobFilter == 'Upcoming') {
      list = list.where((j) => j.status.toLowerCase() != 'completed').toList();
    } else if (_jobFilter == 'Completed') {
      list = list.where((j) => j.status.toLowerCase() == 'completed').toList();
    }
    list.sort((a, b) => (b.scheduledDate ?? DateTime(1900)).compareTo(a.scheduledDate ?? DateTime(1900)));
    return list;
  }

  Future<void> _openFilter() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['All', 'Upcoming', 'Completed']
              .map((o) => ListTile(
            title: Text(o),
            trailing: _jobFilter == o ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(context).pop(o),
          ))
              .toList(),
        ),
      ),
    );
    if (choice != null && mounted) setState(() => _jobFilter = choice);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _queryJobs(List<String> vehicleIds) {
    final col = FirebaseFirestore.instance.collection('jobs');
    if (vehicleIds.isEmpty) return col.where('vehicleId', isEqualTo: '__none__').get();
    final limit = vehicleIds.length > 10 ? vehicleIds.sublist(0, 10) : vehicleIds;
    return col.where('vehicleId', whereIn: limit).get();
  }

  Widget _jobTile(Job j) {
    return FutureBuilder<Mechanic?>(
      future: j.mechanicId != null ? _crm.getMechanic(j.mechanicId!) : Future.value(null),
      builder: (context, mechSnap) {
        final mechanicName = mechSnap.hasData ? mechSnap.data!.name : 'Unknown';
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and Service Type
              Row(
                children: [
                  Text(
                    j.scheduledDate != null ? _formatDate(j.scheduledDate!) : '-',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const Text(' | ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  Text(
                    j.description,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Mechanic and Mileage
              Row(
                children: [
                  Text(
                    'Mechanic: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    mechanicName,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const Text(' | ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                  Text(
                    'Mileage: ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                  Text(
                    '${j.mileage?.toStringAsFixed(0) ?? '-'} km',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Notes
              if (j.notes != null && j.notes!.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      'Notes: ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                    ),
                    Expanded(
                      child: Text(
                        j.notes!,
                        style: const TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              // Invoice
              Row(
                children: [
                  Text(
                    'IN 001', // This should be fetched from invoice data
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
                  ),
                  const Text(' - ', style: TextStyle(fontSize: 12, color: Colors.black87)),
                  Text(
                    'Debit Card', // This should be fetched from payment method
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const Spacer(),
                  const Icon(Icons.description, size: 16, color: Colors.black54),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }


  Future<void> _callNumber(String phone) async {
    if (phone.isEmpty) return;
    try {
      final uri = Uri(scheme: 'tel', path: phone);
      final can = await canLaunchUrl(uri);
      if (!can) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open dialer on this device')),
        );
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to launch dialer: $e')),
      );
    }
  }
}


