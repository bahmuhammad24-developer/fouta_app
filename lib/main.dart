// lib/main.dart
import 'dart:async';

import 'package:fouta_app/screens/splash_screen.dart';
import 'package:fouta_app/services/video_player_manager.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fouta_app/services/push_notification_service.dart';
import 'package:fouta_app/screens/auth_screen.dart';
import 'package:fouta_app/screens/home_screen.dart';
import 'package:media_kit/media_kit.dart';
import 'package:provider/provider.dart';
import 'package:fouta_app/services/connectivity_provider.dart';
import 'package:fouta_app/theme/theme_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Use the Diaspora Connection theme instead of the original Baobab theme
import 'package:fouta_app/theme/app_theme.dart';
import 'package:fouta_app/services/playback_route_observer.dart';
import 'firebase_options.dart';
import 'utils/log_buffer.dart';
import 'utils/bug_reporter.dart';
import 'dev/panic_dismiss.dart';
import 'package:fouta_app/config/feature_flags.dart';
import 'package:fouta_app/features/challenges/challenges_feed_screen.dart'
    show ChallengesFeedScreen;
import 'routes.dart' show appRoutes, challengesRoute;

// Define a global constant for the app ID.
const String APP_ID = 'fouta-app';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Required for media_kit to work
  MediaKit.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Capture logs for bug reports
  LogBuffer.instance.init();

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

  final themeController = ThemeController();
  await themeController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (context) => VideoPlayerManager()),
        ChangeNotifierProvider.value(value: themeController),
      ],
      child: const MyApp(),
    ),
  );

  // Initialize push notifications without blocking startup to avoid a white
  // screen on iOS if the call hangs.
  unawaited(PushNotificationService.initialize());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, controller, __) {
          return MaterialApp(
            title: 'Fouta',

            // Use the Material 3 themed definitions for light and dark modes
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: controller.themeMode,
            navigatorObservers: [PlaybackRouteObserver()],
            routes: {
              ...appRoutes(),
              if (CHALLENGES_ENABLED)
                challengesRoute: (_) => const ChallengesFeedScreen(),
            },

            builder: (context, child) => PanicDismiss(
              child: RepaintBoundary(
                key: BugReporter.repaintBoundaryKey,
                child: child!,
              ),
            ),

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