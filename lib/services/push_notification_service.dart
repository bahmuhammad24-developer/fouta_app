import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import '../utils/firestore_paths.dart';

// Mark the handler as an entry point to ensure it's not tree-shaken in release
// builds, which prevents background notifications from being processed when the
// app is terminated. This is critical for receiving push notifications on iOS
// when the application is not running.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received a foreground message: ${message.messageId}');
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification caused app to open: ${message.messageId}');
    });

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<void> enablePush() async {
    await requestPermission();
    await updateDeviceToken();
    FirebaseMessaging.instance.onTokenRefresh.listen(_saveToken);
  }

  static Future<void> disablePush() async {
    await deleteToken();
    await FirebaseMessaging.instance.deleteToken();
  }

  static Future<void> requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  static Future<bool> isPermissionGranted() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  static Future<void> updateDeviceToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _saveToken(token);
    }
  }

  static Future<void> _saveToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.users())
          .doc(user.uid)
          .collection('meta')
          .doc('token')
          .set({'value': token});
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  static Future<void> deleteToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection(FirestorePaths.users())
          .doc(user.uid)
          .collection('meta')
          .doc('token')
          .delete();
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}
