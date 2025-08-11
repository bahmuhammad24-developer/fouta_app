import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper for requesting runtime media access on Android.
class Permissions {
  /// Requests the appropriate media read permission depending on the
  /// device's SDK level. Returns `true` if all requested permissions are
  /// granted.
  static Future<bool> requestMediaAccess() async {
    if (!Platform.isAndroid) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    final info = await DeviceInfoPlugin().androidInfo;
    if (info.version.sdkInt >= 33) {
      final statuses = await [Permission.photos, Permission.videos].request();
      final photosGranted = statuses[Permission.photos]?.isGranted ?? false;
      final videosGranted = statuses[Permission.videos]?.isGranted ?? false;
      return photosGranted && videosGranted;
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }
}
