import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../models/mechanic.dart';
import '../../services/firestore_vehicle_service.dart';
import '../../utils/formatters.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    ? Image.asset('assets/images/vehicles/${v.imagePath}', fit: BoxFit.cover)
                    : const Icon(Icons.directions_car, size: 64, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 12),
            Text('${v.make} ${v.model} ${v.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Plate No: ${v.plateNo}', style: const TextStyle(color: Colors.black87)),
            Text('VIN: ${v.vin}', style: const TextStyle(color: Colors.black87)),
            const SizedBox(height: 16),
            const Text('Owner Details', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.person, color: Colors.black54),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Owner: ${_customer?.name ?? '-'}'),
                        Text('Phone No: ${_customer?.phone ?? '-'}'),
                      ],
                    ),
                  ),
                  Row(children: [
                    InkWell(
                      onTap: () => _callNumber(_customer?.phone),
                      child: const Icon(Icons.phone, size: 18),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.message, size: 18),
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
}

class _JobTile extends StatelessWidget {
  final Job job;
  final Mechanic? mechanic;
  const _JobTile({required this.job, required this.mechanic});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(job.description, style: const TextStyle(color: Colors.black87)),
        const SizedBox(height: 2),
        Text('Mechanic: ${mechanic?.name ?? '-'} | Mileage: ${job.mileage?.toStringAsFixed(0) ?? '-'} km', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 2),
        Text('Scheduled: ' + (job.scheduledDate != null ? dateDmy.format(job.scheduledDate!) : '-'), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 2),
        Text('Completed: ' + (job.completionDate != null ? dateDmy.format(job.completionDate!) : '-'), style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 2),
        Text('Notes: ${job.notes ?? '-'}', style: const TextStyle(color: Colors.black54)),
        const Divider(height: 20),
      ],
    );
  }
}


