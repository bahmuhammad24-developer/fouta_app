import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../main.dart' show APP_ID;
import 'log_buffer.dart';

/// Handles screenshot capture and bug report submission.
class BugReporter {
  BugReporter._();

  /// Root repaint boundary used to capture screenshots.
  static final GlobalKey repaintBoundaryKey = GlobalKey();

  /// Capture the current app as a PNG screenshot.
  static Future<Uint8List?> capturePng(BuildContext context) async {
    try {
      await Future.delayed(const Duration(milliseconds: 16));
      final buildContext = repaintBoundaryKey.currentContext;
      if (buildContext == null) return null;
      final renderObject = buildContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) return null;
      final boundary = renderObject as RenderRepaintBoundary;
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
      }
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e, st) {
      debugPrint('BUG_REPORT capture error: $e\n$st');
      return null;
    }
  }

  /// Gather environment details about the running app & device.
  static Future<Map<String, dynamic>> environment(BuildContext context) async {
    final map = <String, dynamic>{};
    try {
      final info = await PackageInfo.fromPlatform();
      map['appVersion'] = '${info.version}+${info.buildNumber}';
    } catch (_) {
      map['appVersion'] = 'unknown';
    }
    map['platform'] = Platform.operatingSystem;
    map['osVersion'] = Platform.operatingSystemVersion;
    map['route'] = ModalRoute.of(context)?.settings.name;
    map['userId'] = FirebaseAuth.instance.currentUser?.uid;
    return map;
  }

  /// Submit a bug report with optional screenshot & extra fields.
  static Future<void> submit(
    BuildContext context, {
    required String description,
    Uint8List? screenshot,
    Map<String, dynamic>? extra,
  }) async {
    final env = await environment(context);
    final logs = LogBuffer.instance.dump();
    final reportId = FirebaseFirestore.instance.collection('tmp').doc().id;
    final docRef = FirebaseFirestore.instance.doc(
      'artifacts/$APP_ID/public/data/bug_reports/$reportId',
    );

    if (screenshot != null) {
      await FirebaseStorage.instance
          .ref('bug_reports/$reportId/screenshot.png')
          .putData(screenshot, SettableMetadata(contentType: 'image/png'));
    }

    final logsText = logs.join('\n');
    final data = <String, dynamic>{
      'createdAt': FieldValue.serverTimestamp(),
      'userId': env['userId'],
      'description': description,
      'environment': env,
      'hasScreenshot': screenshot != null,
      'logsCount': logs.length,
      if (extra != null) ...extra,
    };
    if (logsText.length < 10000) {
      data['logs'] = logsText;
    } else {
      final ref = FirebaseStorage.instance
          .ref('bug_reports/$reportId/logs.txt');
      await ref.putString(logsText, metadata: SettableMetadata(contentType: 'text/plain'));
      data['logsUrl'] = await ref.getDownloadURL();
    }

    await docRef.set(data);
  }
}

