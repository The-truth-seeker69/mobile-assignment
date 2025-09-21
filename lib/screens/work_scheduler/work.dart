import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../firebase_options.dart';
import 'workshop.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../models/job.dart'; // <-- import your Job model
import 'worker_summary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Work Schedule',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Arial'),
      home: const WorkScheduleScreen(),
    );
  }
}

class WorkScheduleScreen extends StatefulWidget {
  const WorkScheduleScreen({super.key});
  @override
  State<WorkScheduleScreen> createState() => _WorkScheduleScreenState();
}

class _WorkScheduleScreenState extends State<WorkScheduleScreen> {
  DateTime? selectedDate;
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  String selectedStatus = 'All';
  final List<String> statusFilters = ['All', 'Unassigned',  'Assigned', 'In Progress', 'Completed'];


  List<Job> jobsList = [];
  Map<String, String> vehiclePlates = {};
  Map<String, String> mechanicNames = {};
  Map<String, Map<String, String>> customerInfo = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobs();
  }

  Future<void> _loadJobs() async {
    setState(() => isLoading = true);
    try {
      final jobsSnapshot = await FirebaseFirestore.instance.collection('jobs').get();
      final vehiclesSnapshot = await FirebaseFirestore.instance.collection('vehicles').get();
      final mechanicsSnapshot = await FirebaseFirestore.instance.collection('mechanics').get();
      final customersSnapshot = await FirebaseFirestore.instance.collection('customers').get();

      // Build helper maps
      vehiclePlates = {
        for (var v in vehiclesSnapshot.docs)
          v.id: (v.data()['plateNo'] ?? 'Unknown') as String
      };
      mechanicNames = {
        for (var m in mechanicsSnapshot.docs)
          m.id: (m.data()['name'] ?? 'Unassigned') as String
      };
      customerInfo = {
        for (var c in customersSnapshot.docs)
          c.id: {
            'name': (c.data()['name'] ?? 'Unknown') as String,
            'phone': (c.data()['phone'] ?? 'Unknown') as String,
          }
      };

      jobsList = jobsSnapshot.docs
          .map((doc) => Job.fromMap(doc.id, doc.data()))
          .toList();

    } catch (e) {
      debugPrint('Error loading jobs: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredJobs = jobsList.where((job) {
      bool matchesDate = true;
      if (selectedDate != null && job.scheduledDate != null) {
        final d = job.scheduledDate!;
        final picked = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
        matchesDate = DateTime(d.year, d.month, d.day) == picked;
      }

      final query = searchQuery.toLowerCase();
      bool matchesSearch = query.isEmpty ||
          job.id.toLowerCase().contains(query) ||
          mechanicNames[job.mechanicId]?.toLowerCase().contains(query) == true;

      bool matchesStatus = true;
      if (selectedStatus != 'All') {
        final jobStatus = job.status.toLowerCase(); // e.g. "", "assigned", "in-progress", "completed"

        if (selectedStatus == 'Unassigned') {
          // Empty string means unassigned
          matchesStatus = jobStatus.isEmpty;
        } else if (selectedStatus == 'In Progress') {
          // Firestore stores it as "in-progress"
          matchesStatus = jobStatus == 'in-progress';
        } else if (selectedStatus == 'Completed') {
          matchesStatus = jobStatus == 'completed';
        } else if (selectedStatus == 'Assigned') {
          matchesStatus = jobStatus == 'assigned';
        }
      }

      return matchesDate && matchesSearch && matchesStatus;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        // 👇 Leading icon on the LEFT of the title
        leading: IconButton(
          icon: const Icon(Icons.bar_chart, color: Colors.blue),
          tooltip: 'Technician Summary',
          onPressed: () {
            // Navigate to the summary page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MechanicJobSummaryPage(),
              ),
            );
          },
        ),


        centerTitle: true,
        title: const Text(
          "Work Schedule",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => selectedDate = picked);
            },
          ),
          if (selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.red),
              onPressed: () => setState(() => selectedDate = null),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              itemCount: statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final status = statusFilters[index];
                final isSelected = selectedStatus == status;
                return ChoiceChip(
                  label: Text(status),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) {
                    setState(() => selectedStatus = status);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search Job ID or Technician",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => searchQuery = v),
            ),
          ),
          Expanded(
            child: filteredJobs.isEmpty
                ? const Center(
              child: Text("No jobs found",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: filteredJobs.length,
              itemBuilder: (context, i) {
                final job = filteredJobs[i];
                final plate = vehiclePlates[job.vehicleId] ?? 'Unknown';
                final mechanic = mechanicNames[job.mechanicId] ?? 'Unassigned';
                final customer = customerInfo[job.customerId]?['name'] ?? 'Unknown';
                final date = job.scheduledDate?.toIso8601String().split('T').first ?? '';
                final time = job.scheduledTime != null
                    ? TimeOfDay.fromDateTime(job.scheduledTime!).format(context)
                    : '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text("${job.id.toUpperCase()} $date $time"),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Plate Number: $plate"),
                        Text("Task: ${job.description}"),
                        Text("Mechanic: $mechanic",
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              JobDetailsScreen(jobId: job.id),
                        ),
                      );
                      if (updated == true) _loadJobs();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
