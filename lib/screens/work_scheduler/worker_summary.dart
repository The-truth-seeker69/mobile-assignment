import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MechanicJobSummaryPage extends StatefulWidget {
  const MechanicJobSummaryPage({super.key});

  @override
  State<MechanicJobSummaryPage> createState() => _MechanicJobSummaryPageState();
}

class _MechanicJobSummaryPageState extends State<MechanicJobSummaryPage> {
  DateTime? selectedDate;
  bool loading = false;
  Map<String, int> mechanicJobCount = {};

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked;
        mechanicJobCount.clear();
      });
      _loadCountsForDate(picked);
    }
  }

  Future<void> _loadCountsForDate(DateTime date) async {
    setState(() => loading = true);
    try {
      final formatted =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      final jobsSnap = await FirebaseFirestore.instance
          .collection('jobs')
          .where('scheduledDate', isEqualTo: formatted)
          .get();

      // Count jobs grouped by mechanicId
      final counts = <String, int>{};
      for (var doc in jobsSnap.docs) {
        final mechId = doc['mechanicId'] as String? ?? '';
        if (mechId.isNotEmpty) {
          counts[mechId] = (counts[mechId] ?? 0) + 1;
        }
      }

      // Optional: load mechanic names
      final mechSnap =
      await FirebaseFirestore.instance.collection('mechanics').get();
      final nameCounts = <String, int>{};
      for (var m in mechSnap.docs) {
        final name = (m.data()['name'] ?? 'Unknown') as String;
        // Use the count if exists, else 0
        nameCounts[name] = counts[m.id] ?? 0;
      }

      setState(() => mechanicJobCount = nameCounts);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mechanic Job Summary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: selectedDate == null
            ? const Center(child: Text('Select a date to view mechanics'))
            : loading
            ? const Center(child: CircularProgressIndicator())
            : mechanicJobCount.isEmpty
            ? const Center(child: Text('No jobs for this date'))
            : ListView(
          children: mechanicJobCount.entries
              .where((e) => e.key != 'Unassigned')   // <-- filter it out
              .map((e) => ListTile(
            leading: const Icon(Icons.engineering),
            title: Text(e.key),
            trailing: Text('${e.value} jobs'),
          ))
              .toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickDate,
        child: const Icon(Icons.date_range),
      ),
    );
  }
}
