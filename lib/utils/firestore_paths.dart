import 'package:fouta_app/main.dart';

/// Centralized definitions for Firestore collection paths used across the app.
/// Keeping these in one place avoids repeated string literals and makes future
/// schema changes easier.
class FirestorePaths {
  FirestorePaths._();

  static String users([String appId = APP_ID]) =>
      'artifacts/$appId/public/data/users';
  static String posts([String appId = APP_ID]) =>
      'artifacts/$appId/public/data/posts';
  static String chats([String appId = APP_ID]) =>
      'artifacts/$appId/public/data/chats';
  static String events([String appId = APP_ID]) =>
      'artifacts/$appId/public/data/events';
  static String stories([String appId = APP_ID]) =>
      'artifacts/$appId/public/data/stories';
  static String hashtags([String appId = APP_ID]) =>
      'artifacts/$appId/public/data/hashtags';
  static String profileImages([String appId = APP_ID]) =>
      'artifacts/$appId/public/data/profile_images';
}

