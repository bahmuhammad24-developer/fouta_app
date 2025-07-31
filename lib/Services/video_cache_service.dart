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

  // Maximum cache size in bytes (e.g. 100 MB)
  static const int _maxCacheSizeBytes = 100 * 1024 * 1024;

  final Set<String> _precacheJobs = {};

  /// Directory where video files are cached. Ensures the directory exists.
  Future<Directory> _getCacheDir() async {
    final tmpDir = await getTemporaryDirectory();
    final cacheDir = Directory('${tmpDir.path}/video_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Calculates the total size of cached files and removes the oldest
  /// files until the cache size is under the configured limit.
  Future<void> _pruneCache() async {
    final cacheDir = await _getCacheDir();
    final files = await cacheDir.list().where((f) => f is File).cast<File>().toList();
    if (files.isEmpty) return;
    // Sort files by last modified time (oldest first)
    files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    int totalSize = files.fold(0, (prev, f) => prev + f.lengthSync());
    for (final file in files) {
      if (totalSize <= _maxCacheSizeBytes) break;
      try {
        final fileSize = file.lengthSync();
        await file.delete();
        totalSize -= fileSize;
        debugPrint('Removed cached video: ${file.path}');
      } catch (_) {
        // Ignore individual deletion errors and continue
      }
    }
  }

  Future<File> getFile(String url) async {
    final cacheDir = await _getCacheDir();
    final fileName = '${url.hashCode}.mp4';
    final file = File('${cacheDir.path}/$fileName');
    if (await file.exists()) {
      // Touch the file to update its modified time for LRU tracking
      try {
        await file.setLastModified(DateTime.now());
      } catch (_) {}
      debugPrint('Video loaded from cache: ${file.path}');
      return file;
    }
    debugPrint('Video not in cache. Downloading from: $url');
    try {
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        debugPrint('Video downloaded and saved to cache: ${file.path}');
        // Prune cache after adding new file
        await _pruneCache();
        return file;
      } else {
        throw Exception('Failed to download video: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading video: $e');
      throw Exception('Error downloading video: $e');
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
      // If not, it will download and save it and prune the cache.
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