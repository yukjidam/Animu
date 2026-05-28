import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home/home_screen.dart'; // ← make sure this import path is correct

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AnimuApp());
}

class AnimuApp extends StatelessWidget {
  const AnimuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // ── Still connecting to Firebase ──
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // ── Logged in → go to HomeScreen ──
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // ── Not logged in → show AuthScreen ──
          return const AuthScreen();
        },
      ),
    );
  }
}
