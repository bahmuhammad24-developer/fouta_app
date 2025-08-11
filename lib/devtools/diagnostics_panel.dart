import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/story.dart';
import '../utils/firestore_paths.dart';
import '../main.dart';

/// Stores debug info about the last story publish.
class StoryDiagnostics {
  StoryDiagnostics._();
  static final StoryDiagnostics instance = StoryDiagnostics._();
  PublishResult? lastPublish;
  List<Story> owners = [];
}

class PublishResult {
  final String type;
  final String url;
  final String? thumbUrl;
  final int? durationMs;
  PublishResult({
    required this.type,
    required this.url,
    this.thumbUrl,
    this.durationMs,
  });
}

/// Simple in-app panel showing diagnostics for stories/video.
class DiagnosticsPanel extends StatefulWidget {
  final List<dynamic> stories;
  final String? currentUserId;
  final Future<void> Function()? onRefresh;
  const DiagnosticsPanel({
    super.key,
    this.stories = const [],
    this.currentUserId,
    this.onRefresh,
  });

  static Future<void> show(BuildContext context,
      {String? uid,
      List<dynamic> stories = const [],
      Future<void> Function()? onRefresh}) async {
    if (!kDebugMode) return;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: DiagnosticsPanel(
          stories: stories,
          currentUserId: uid,
          onRefresh: onRefresh,
        ),
      ),
    );
  }

  @override
  State<DiagnosticsPanel> createState() => _DiagnosticsPanelState();
}

class _DiagnosticsPanelState extends State<DiagnosticsPanel> {
  String _buildDiagnostics() {
    final buffer = StringBuffer();
    final providedStoriesCount = widget.stories.length;
    buffer.writeln('Provided stories: $providedStoriesCount');
    buffer.writeln('appId: $APP_ID');
    if (widget.currentUserId != null) {
      buffer.writeln('currentUser: ${widget.currentUserId}');
    }
    buffer.writeln('ownersPath: ${FirestorePaths.stories()}');
    final owners = StoryDiagnostics.instance.owners;
    buffer.writeln('ownersLoaded: ${owners.length}');
    for (final o in owners.take(3)) {
      buffer.writeln('  owner: ${o.authorId} updatedAt: ${o.postedAt}');
    }
    if (widget.currentUserId != null) {
      final me = owners.firstWhere(
          (o) => o.authorId == widget.currentUserId,
          orElse: () => Story(
              id: '',
              authorId: '',
              postedAt: DateTime.fromMillisecondsSinceEpoch(0),
              expiresAt: DateTime.fromMillisecondsSinceEpoch(0)));
      buffer.writeln(
          'mySlides: ${me.items.length}${me.items.isNotEmpty ? '' : ''}');
      for (final s in me.items.take(3)) {
        buffer.writeln(
            '  slide: ${s.media.type.name} createdAt:${s.createdAt} expiresAt:${s.expiresAt} thumb:${s.media.thumbUrl != null}');
      }
    }
    final publish = StoryDiagnostics.instance.lastPublish;
    if (publish != null) {
      buffer.writeln(
          'lastPublish: type=${publish.type} url=${publish.url} thumb=${publish.thumbUrl} dur=${publish.durationMs}');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final diagnostics = _buildDiagnostics();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Diagnostics',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Text(diagnostics,
                  style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  await widget.onRefresh?.call();
                  if (mounted) setState(() {});
                },
                child: const Text('Refresh Stories Queries'),
              ),
              TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: diagnostics));
                  Navigator.pop(context);
                },
                child: const Text('Copy Diagnostics'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

