import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/job.dart';
import '../../models/vehicle.dart';
import '../../models/customer.dart';

class JobDetailsScreen extends StatefulWidget {
  final String jobId;
  const JobDetailsScreen({super.key, required this.jobId});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  String? selectedMechanicName;
  final Map<String, String> mechanicIdToName = {};
  Set<String> busyMechanicIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final jobDoc = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .get();
    if (!jobDoc.exists) return;

    final jobData = jobDoc.data()!;
    final date = jobData['scheduledDate'] as String? ?? '';
    final time = jobData['scheduledTime'] as String? ?? '';
    final currentMechId = jobData['mechanicId'] as String?;

    final DateTime? thisJobDT = _combineDateTime(date, time);

    final clashSnap = await FirebaseFirestore.instance
        .collection('jobs')
        .where('scheduledDate', isEqualTo: date)
        .get();

    final busy = <String>{};
    for (var d in clashSnap.docs) {
      if (d.id == widget.jobId) continue;
      final otherTime = d['scheduledTime'] as String?;
      final otherMech = d['mechanicId'] as String?;
      if (otherTime == null || otherMech == null) continue;

      final otherDT = _combineDateTime(date, otherTime);
      if (thisJobDT != null &&
          otherDT != null &&
          (thisJobDT.difference(otherDT).inMinutes).abs() <= 60) {
        busy.add(otherMech);
      }
    }

    final mechSnap =
    await FirebaseFirestore.instance.collection('mechanics').get();
    final map = <String, String>{};
    for (var d in mechSnap.docs) {
      map[d.id] = (d.data()['name'] ?? '') as String;
    }

    setState(() {
      mechanicIdToName
        ..clear()
        ..addAll(map);
      busyMechanicIds = busy.difference({currentMechId ?? ''});
    });
  }

  DateTime? _combineDateTime(String date, String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dateParts = date.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _updateMechanic(String jobId) async {
    if (selectedMechanicName == null) return;

    final mechId = mechanicIdToName.entries
        .firstWhere((e) => e.value == selectedMechanicName)
        .key;

    await FirebaseFirestore.instance
        .collection('jobs')
        .doc(jobId)
        .update({'mechanicId': mechId});

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Technician updated')));
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobRef =
    FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);

    return Scaffold(
      appBar: AppBar(title: Text('${widget.jobId}')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: jobRef.snapshots(),
        builder: (context, jobSnap) {
          if (jobSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!jobSnap.hasData || !jobSnap.data!.exists) {
            return const Center(child: Text('Job not found'));
          }

          final job = Job.fromMap(jobSnap.data!.id, jobSnap.data!.data()!);

          final currentMechName = (job.mechanicId != null && job.mechanicId!.isNotEmpty)
              ? (mechanicIdToName[job.mechanicId] ?? 'Unknown')
              : null; // null means “no selection”

          final dropdownValue = selectedMechanicName ?? currentMechName;


          final futures = <Future<DocumentSnapshot>>[];
          if (job.customerId?.isNotEmpty == true) {
            futures.add(FirebaseFirestore.instance
                .collection('customers')
                .doc(job.customerId!)
                .get());
          }
          if (job.vehicleId.isNotEmpty) {
            futures.add(FirebaseFirestore.instance
                .collection('vehicles')
                .doc(job.vehicleId)
                .get());
          }

          return FutureBuilder<List<DocumentSnapshot>>(
            future: Future.wait(futures),
            builder: (context, detailsSnap) {
              Customer? customer;
              Vehicle? vehicle;

              if (detailsSnap.hasData) {
                if (job.customerId?.isNotEmpty == true && detailsSnap.data!.isNotEmpty) {
                  customer = Customer.fromMap(
                    job.customerId!,
                    detailsSnap.data![0].data() as Map<String, dynamic>,
                  );
                }
                if (job.vehicleId.isNotEmpty) {
                  final idx = job.customerId?.isNotEmpty == true ? 1 : 0;
                  if (detailsSnap.data!.length > idx) {
                    vehicle = Vehicle.fromMap(
                      job.vehicleId,
                      detailsSnap.data![idx].data() as Map<String, dynamic>,
                    );
                  }
                }
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _readOnlyField('Customer Name', customer?.name ?? ''),
                    _readOnlyField('Phone', customer?.phone ?? ''),
                    _readOnlyField('Model', vehicle?.model ?? ''),
                    _readOnlyField('Plate Number', vehicle?.plateNumber ?? ''),
                    _readOnlyField('Task', job.description),
                    _readOnlyField(
                      'Date',
                      job.scheduledDate != null
                          ? '${job.scheduledDate!.year}-${job.scheduledDate!.month.toString().padLeft(2, '0')}-${job.scheduledDate!.day.toString().padLeft(2, '0')}'
                          : '',
                    ),
                    _readOnlyField(
                      'Time',
                      job.scheduledTime != null
                          ? TimeOfDay.fromDateTime(job.scheduledTime!)
                          .format(context)
                          : '',
                    ),
                    _readOnlyField('Status', job.status),
                    _readOnlyField(
                      'Completion Date',
                      job.completionDate != null
                          ? '${job.completionDate!.year}-${job.completionDate!.month.toString().padLeft(2, '0')}-${job.completionDate!.day.toString().padLeft(2, '0')}'
                          : '',
                    ),



                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Mechanic',
                        border: OutlineInputBorder(),
                      ),
                      value: dropdownValue,
                      items: mechanicIdToName.entries
                          .where((e) => !busyMechanicIds.contains(e.key))
                          .map((e) => DropdownMenuItem(
                        value: e.value,
                        child: Text(e.value),
                      ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedMechanicName = v),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: job.status.toLowerCase() == 'completed'
                          ? null                    // disables the button
                          : () => _updateMechanic(widget.jobId),
                      child: const Text('Update Mechanic'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(value.isNotEmpty ? value : '—'),
      ),
    );
  }
}
