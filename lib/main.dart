import 'package:flutter/material.dart';
import 'screens/inventory_control/inventory_main.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workshop Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const InventoryScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
