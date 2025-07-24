// lib/services/video_cache_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class VideoCacheService {
  // Singleton pattern
  static final VideoCacheService _instance = VideoCacheService._internal();
  factory VideoCacheService() {
    return _instance;
  }
  VideoCacheService._internal();

  final Set<String> _precacheJobs = {};

  Future<File> getFile(String url) async {
    final fileName = '${url.hashCode}.mp4';
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');

    if (await file.exists()) {
      debugPrint('Video loaded from cache: ${file.path}');
      return file;
    } else {
      debugPrint('Video not in cache. Downloading from: $url');
      try {
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
          debugPrint('Video downloaded and saved to cache: ${file.path}');
          return file;
        } else {
          throw Exception('Failed to download video: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error downloading video: $e');
        throw Exception('Error downloading video: $e');
      }
    }
  }

  Future<void> precacheVideo(String url) async {
    // If a precache job for this URL is already running, do nothing.
    if (_precacheJobs.contains(url)) {
      return;
    }

    try {
      // Add the URL to the set of running jobs.
      _precacheJobs.add(url);
      debugPrint('Starting precache for: $url');
      // Use the existing getFile logic. If the file exists, it will return quickly.
      // If not, it will download and save it.
      await getFile(url);
      debugPrint('Precache finished for: $url');
    } catch (e) {
      debugPrint('Precache failed for $url: $e');
    } finally {
      // When the job is done (success or fail), remove it from the set.
      _precacheJobs.remove(url);
    }
  }
}