import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import '/controller/invoice_controller.dart';
import 'main_menu.dart'; // NEW
import 'login_screen.dart';

Future<void> main() async {
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InvoiceController()..load()),
      ],
      child: MaterialApp(
        title: 'Workshop Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme, // ✅ Using custom theme (see below)
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData) {
              return const MainMenuScreen(); // go to your main menu with bottom nav
            }
            return const LoginScreen(); // show login page
          },
        ),
      ),
    );
  }
}
