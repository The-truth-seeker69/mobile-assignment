import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_vehicle_service.dart';
import '../../utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';
import '../crm/chat_screen.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  const VehicleDetailScreen({super.key, required this.vehicle});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final FirestoreVehicleService _service = FirestoreVehicleService();
  Customer? _customer;
  List<Job> _jobs = const [];
  Map<String, Mechanic> _mechanics = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final customer = await _service.getCustomerById(widget.vehicle.customerId);
      final jobs = await _service.getJobsForVehicle(widget.vehicle.id);
      final Map<String, Mechanic> m = {};
      for (final j in jobs) {
        final mech = await _service.getMechanicById(j.mechanicId);
        if (mech != null) m[mech.id] = mech;
      }
      setState(() {
        _customer = customer;
        _jobs = jobs;
        _mechanics = m;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text('Vehicle Details'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: const Color(0xFFE8EBF3),
                height: 180,
                child: v.imagePath != null && v.imagePath!.isNotEmpty
                    ? Image.asset(
                        'assets/images/vehicles/${v.imagePath}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Image load error for ${v.imagePath}: $error');
                          return const Icon(Icons.directions_car, size: 64, color: Colors.black54);
                        },
                      )
                    : const Icon(Icons.directions_car, size: 64, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            Text('${v.make} ${v.model} ${v.year}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                children: [
                  const TextSpan(text: 'Plate No: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: v.plateNumber),
                ],
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                children: [
                  const TextSpan(text: 'VIN: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: v.vin),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Owner Details', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildAvatar(_customer?.imagePath, 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 16),
                            children: [
                              const TextSpan(text: 'Owner: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: _customer?.name ?? '-'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black87, fontSize: 16),
                            children: [
                              const TextSpan(text: 'Phone No: ', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: _customer?.phone ?? '-'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(children: [
                    InkWell(
                      onTap: () => _callNumber(_customer?.phone),
                      child: const Icon(Icons.phone, size: 18),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () => _openChat(),
                      child: const Icon(Icons.message, size: 18),
                    ),
                  ])
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(children: [
                  Icon(Icons.build, size: 18),
                  SizedBox(width: 8),
                  Text('Service History', style: TextStyle(fontWeight: FontWeight.w700)),
                ]),
                TextButton.icon(
                  onPressed: _openFilter,
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Filter'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: _filteredJobs().isEmpty
                    ? [
                        const SizedBox(height: 8),
                        const Text('No service history yet', style: TextStyle(color: Colors.black54)),
                        const SizedBox(height: 8),
                      ]
                    : _filteredJobs().map((j) => _JobTile(job: j, mechanic: _mechanics[j.mechanicId])).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _jobFilter = 'All'; // All, Upcoming, Completed

  List<Job> _filteredJobs() {
    List<Job> list = List.of(_jobs);
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

  Future<void> _callNumber(String? phone) async {
    if (phone == null || phone.isEmpty) return;
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

  Future<void> _openChat() async {
    if (_customer == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          customerId: _customer!.id,
          customerName: _customer!.name,
        ),
      ),
    );
  }

  Widget _buildAvatar(String? path, double size) {
    final assetPath = path != null && path.isNotEmpty ? 'assets/images/crm/$path' : '';
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
}

class _JobTile extends StatelessWidget {
  final Job job;
  final Mechanic? mechanic;
  const _JobTile({required this.job, required this.mechanic});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job.description,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      const TextSpan(text: 'Mechanic: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: mechanic?.name ?? '-'),
                    ],
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Mileage: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: '${job.mileage?.toStringAsFixed(0) ?? '-'} km'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                    children: [
                      const TextSpan(text: 'Scheduled: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextSpan(text: job.scheduledDate != null ? dateDmy.format(job.scheduledDate!) : '-'),
                    ],
                  ),
                ),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                  children: [
                    const TextSpan(text: 'Completed: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: job.completionDate != null ? dateDmy.format(job.completionDate!) : '-'),
                  ],
                ),
              ),
            ],
          ),
          if (job.notes != null && job.notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black54, fontSize: 14),
                children: [
                  const TextSpan(text: 'Notes: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: job.notes!),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}


