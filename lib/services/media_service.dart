// lib/services/media_service.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import 'permissions.dart';

/// Represents a locally selected media file with extracted metadata.
class MediaAttachment {
  MediaAttachment({
    required this.file,
    required this.type,
    this.bytes,
    this.aspectRatio,
    this.durationMs,
    this.width,
    this.height,
  });

  final XFile file;
  final String type; // 'image' or 'video'
  final Uint8List? bytes; // useful for web image previews
  final double? aspectRatio;
  final int? durationMs;
  final int? width;
  final int? height;
}

/// Result of uploading a [MediaAttachment].
class UploadedMedia {
  UploadedMedia({
    required this.url,
    required this.type,
    this.thumbUrl,
    this.aspectRatio,
    this.durationMs,
    this.width,
    this.height,
  });

  final String url;
  final String type;
  final String? thumbUrl;
  final double? aspectRatio;
  final int? durationMs;
  final int? width;
  final int? height;
}

/// Service responsible for picking & uploading media across the app.
class MediaService {
  MediaService({
    ImagePicker? picker,
    Future<bool> Function()? requestPermission,
    Future<String> Function(Uint8List data, String path, String contentType)? uploadBytes,
    Future<String> Function(File file, String path, String contentType)? uploadFile,
    Future<Uint8List?> Function(String path)? generateThumb,
  })  : _picker = picker ?? ImagePicker(),
        _requestPermission = requestPermission ?? Permissions.requestMediaAccess,
        _uploadBytes = uploadBytes ?? _firebaseUploadBytes,
        _uploadFile = uploadFile ?? _firebaseUploadFile,
        _generateThumb = generateThumb ?? _defaultVideoThumbnail;

  final ImagePicker _picker;
  final Future<bool> Function() _requestPermission;
  final Future<String> Function(Uint8List data, String path, String contentType) _uploadBytes;
  final Future<String> Function(File file, String path, String contentType) _uploadFile;
  final Future<Uint8List?> Function(String path) _generateThumb;

  static const int _maxVideoFileSize = 500 * 1024 * 1024; // 500 MB

  /// Pick an image from the given [source].
  Future<MediaAttachment?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final granted = await _requestPermission();
    if (!granted) return null;
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked == null) return null;

    Uint8List? bytes;
    int? width;
    int? height;

    try {
      bytes = await picked.readAsBytes();
      final decoded = img.decodeImage(bytes);
      width = decoded?.width;
      height = decoded?.height;
      if (!kIsWeb) {
        // For non‑web platforms we don't keep raw bytes to save memory.
        bytes = null;
      }
    } catch (_) {}

    return MediaAttachment(
      file: picked,
      type: 'image',
      bytes: bytes,
      width: width,
      height: height,
    );
  }

  /// Pick a video from the given [source]. Performs size validation and extracts
  /// duration/aspect ratio metadata when possible.
  Future<MediaAttachment?> pickVideo({ImageSource source = ImageSource.gallery}) async {
    final granted = await _requestPermission();
    if (!granted) return null;
    final XFile? picked = await _picker.pickVideo(source: source);
    if (picked == null) return null;

    if (!kIsWeb) {
      final fileSize = File(picked.path).lengthSync();
      if (fileSize > _maxVideoFileSize) return null;
    }

    double? aspect;
    int? durationMs;
    if (!kIsWeb) {
      final player = Player();
      final uri = Uri.file(picked.path).toString();
      await player.open(Media(uri), play: false);
      await player.stream.width.firstWhere((w) => w != null);
      final width = player.state.width;
      final height = player.state.height;
      if (width != null && height != null && height > 0) {
        aspect = width / height;
      }
      final d = await player.stream.duration.firstWhere((d) => d != null);
      durationMs = d?.inMilliseconds;
      await player.dispose();
    }

    return MediaAttachment(
      file: picked,
      type: 'video',
      aspectRatio: aspect,
      durationMs: durationMs,
    );
  }

  /// Uploads the given [attachment] to storage. Optionally provide a
  /// [pathPrefix] to customize the destination folder.
  Future<UploadedMedia> upload(MediaAttachment attachment, {String? pathPrefix}) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'anonymous';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final basePath = pathPrefix != null
        ? '$pathPrefix/'
        : attachment.type == 'video'
            ? 'videos/$uid/'
            : 'images/$uid/';

    if (attachment.type == 'image') {
      Uint8List data = attachment.bytes ?? await attachment.file.readAsBytes();
      if (!kIsWeb) {
        final decoded = img.decodeImage(data);
        if (decoded != null) {
          data = Uint8List.fromList(img.encodeJpg(decoded, quality: 80));
        }
      }
      final url = await _uploadBytes(data, '$basePath$timestamp.jpg', 'image/jpeg');
      return UploadedMedia(
        url: url,
        type: 'image',
        width: attachment.width,
        height: attachment.height,
      );
    } else if (attachment.type == 'video') {
      // Preserve the original file extension & MIME type to avoid upload
      // mismatches (e.g. iOS .mov files stored as .mp4).
      final name = attachment.file.name;
      final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'mp4';
      final contentType = switch (ext) {
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        'mkv' => 'video/x-matroska',
        'avi' => 'video/x-msvideo',
        _ => 'video/mp4',
      };
      final path = '$basePath$timestamp.$ext';

      String videoUrl;
      if (kIsWeb) {
        final data = await attachment.file.readAsBytes();
        videoUrl = await _uploadBytes(data, path, contentType);
      } else {
        videoUrl = await _uploadFile(File(attachment.file.path), path, contentType);
      }
      String? thumbUrl;
      final thumbData = await _generateThumb(attachment.file.path);
      if (thumbData != null) {
        thumbUrl = await _uploadBytes(thumbData, '$basePath${timestamp}_thumb.jpg', 'image/jpeg');
      }
      return UploadedMedia(
        url: videoUrl,
        type: 'video',
        thumbUrl: thumbUrl,
        aspectRatio: attachment.aspectRatio,
        durationMs: attachment.durationMs,
      );
    } else {
      throw UnsupportedError('Unsupported media type: ${attachment.type}');
    }
  }

  // Default helpers using Firebase Storage & video_thumbnail
  static Future<String> _firebaseUploadBytes(Uint8List data, String path, String contentType) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putData(data, metadata);
    return ref.getDownloadURL();
  }

  static Future<String> _firebaseUploadFile(File file, String path, String contentType) async {
    final ref = FirebaseStorage.instance.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    await ref.putFile(file, metadata);
    return ref.getDownloadURL();
  }

  static Future<Uint8List?> _defaultVideoThumbnail(String path) {
    return VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.JPEG,
      quality: 75,
    );
  }
}

