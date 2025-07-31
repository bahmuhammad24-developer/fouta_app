// lib/main.dart
import 'package:fouta_app/screens/splash_screen.dart';
import 'package:fouta_app/services/video_player_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouta_app/screens/auth_screen.dart';
import 'package:fouta_app/screens/home_screen.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:fouta_app/services/connectivity_provider.dart';
import 'package:fouta_app/services/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fouta_app/theme/fouta_theme.dart';
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
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'Fouta',
          // Use the central FoutaTheme definitions for light and dark modes
          theme: FoutaTheme.lightTheme,
          darkTheme: FoutaTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
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