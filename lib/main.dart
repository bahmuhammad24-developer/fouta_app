// lib/main.dart
import 'package:fouta_app/services/connectivity_provider.dart';
import 'package:fouta_app/screens/splash_screen.dart';
import 'package:fouta_app/services/video_player_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouta_app/screens/auth_screen.dart';
import 'package:fouta_app/screens/home_screen.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// Define a global constant for the app ID.
const String APP_ID = 'fouta-app';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required for media_kit to work
  MediaKit.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => VideoPlayerManager()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fouta',
      theme: ThemeData(
        primaryColor: const Color(0xFF2D5A2D),
        scaffoldBackgroundColor: const Color(0xFFF2F0E6), // UPDATED: Alabaster
        fontFamily: 'Inter',
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF2D5A2D), // Primary Green
          secondary: Color(0xFFF7B731), // Accent Gold
          surface: Color(0xFFFFFFFF), // Card/Surface White
          background: Color(0xFFF2F0E6), // UPDATED: Alabaster
          error: Color(0xFFD9534F), // Alert Red
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onSurface: Color(0xFF333333), // Primary Text
          onBackground: Color(0xFF333333),
          onError: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          foregroundColor: Color(0xFF2D5A2D),
          elevation: 2,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF7B731), // Accent Gold
          foregroundColor: Colors.black,
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Color(0xFFF5F5F5),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF7B731), // Accent Gold
            foregroundColor: Colors.black, // Black text on gold buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(color: Color(0xFF2D5A2D), width: 2.0), // Green focus
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5A2D)),
          titleLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF333333)),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF333333)),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary, // Accent Gold
              ),
            ),
          );
        }
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}