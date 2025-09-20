import 'package:flutter/material.dart';
import '../widgets/bottom_navigation.dart';
import 'screens/inventory_control/inventory_main.dart';
import 'screens/invoice/invoice_list_screen.dart';
import 'screens/vehicles/vehicles_list_screen.dart';
// import your other modules here

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _currentIndex = 2; // start at Vehicles tab per module focus

  final List<Widget> _pages = const [
    InventoryScreen(),
    Placeholder(), // SchedulerScreen()
    VehiclesListScreen(),
    InvoicesListScreen(),
    Placeholder(), // CRMScreen()
  ];

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onNavTap,
      ),
    );
  }
}
