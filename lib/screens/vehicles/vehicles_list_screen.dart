import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/firestore_vehicle_service.dart';
import '../../widgets/bottom_navigation.dart';
import 'vehicles_detail_screen.dart';

class VehiclesListScreen extends StatefulWidget {
  const VehiclesListScreen({super.key});

  @override
  State<VehiclesListScreen> createState() => _VehiclesListScreenState();
}

class _VehiclesListScreenState extends State<VehiclesListScreen> {
  final FirestoreVehicleService _service = FirestoreVehicleService();
  String _query = '';
  String _filter = 'All'; // All, Make, Year

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Vehicles', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _SearchBar(
              onChanged: (v) => setState(() => _query = v),
              onFilterTap: () async {
                final choice = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => _FilterSheet(current: _filter),
                );
                if (choice != null) setState(() => _filter = choice);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Vehicle>>(
                stream: _service.streamVehicles(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    final err = snapshot.error;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Failed to load vehicles.\n\n${err ?? 'Unknown error'}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  List<Vehicle> list = (snapshot.data ?? const <Vehicle>[]);
                  if (_query.isNotEmpty) {
                    list = list.where((v) {
                      final text = '${v.make} ${v.model} ${v.plateNo} ${v.vin}'.toLowerCase();
                      return text.contains(_query.toLowerCase());
                    }).toList();
                  }
                  // Simple filter demo
                  if (_filter == 'Make') {
                    list.sort((a, b) => a.make.compareTo(b.make));
                  } else if (_filter == 'Year') {
                    list.sort((a, b) => b.year.compareTo(a.year));
                  }
                  if (list.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No vehicles found.\n\nChecks:\n- Collection: vehicles\n- Read rules allow this user\n- Fields: customerId, make, model, year, vin',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final v = list[index];
                      return _VehicleCard(
                        vehicle: v,
                        onView: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => VehicleDetailScreen(vehicle: v),
                          ));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;
  const _SearchBar({required this.onChanged, required this.onFilterTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Search by VIN, Plate or Model',
                border: InputBorder.none,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onFilterTap,
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
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onView;
  const _VehicleCard({required this.vehicle, required this.onView});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: const Color(0xFFE8EBF3),
              width: 72,
              height: 72,
              child: vehicle.imagePath != null && vehicle.imagePath!.isNotEmpty
                  ? Image.asset('assets/images/vehicles/${vehicle.imagePath}', fit: BoxFit.cover)
                  : const Icon(Icons.directions_car, size: 32, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${vehicle.make} ${vehicle.model} ${vehicle.year}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(vehicle.plateNo, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          TextButton(
            onPressed: onView,
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF1F3F8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('View', style: TextStyle(color: Colors.black87)),
          )
        ],
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  final String current;
  const _FilterSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    final options = ['All', 'Make', 'Year'];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) => ListTile(
          title: Text(o),
          trailing: current == o ? const Icon(Icons.check) : null,
          onTap: () => Navigator.of(context).pop(o),
        )).toList(),
      ),
    );
  }
}


