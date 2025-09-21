import 'package:flutter/material.dart';
import 'screens/inventory_control/inventory_main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'package:assignment/controller/invoice_controller.dart';
import 'main_menu.dart'; // NEW
import 'login_screen.dart';


Future<void> _initializeFirebase() async {
  try {
    // Initialize Firebase only if not already initialized
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // If Firebase is already initialized, continue
    print('Firebase already initialized: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InvoiceController()..load()),
      ],
      child: MaterialApp(
        title: 'Workshop Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: FutureBuilder<void>(
          future: _initializeFirebase(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Initializing app...'),
                    ],
                  ),
                ),
              );
            }
            
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: ${snapshot.error}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Restart the app
                          main();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            return StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, authSnapshot) {
                if (authSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (authSnapshot.hasData) {
                  return const MainMenuScreen();
                }
                return const LoginScreen();
              },
            );
          },
        ),
      ),
    );
  }
}
