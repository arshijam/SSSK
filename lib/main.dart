import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Anonymous sign-in — Firestore rules ke liye
  await FirebaseAuth.instance.signInAnonymously();
  runApp(const SaafSarakApp());
}

class SaafSarakApp extends StatelessWidget {
  const SaafSarakApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saaf Sarak Saaf Karachi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00695C)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}