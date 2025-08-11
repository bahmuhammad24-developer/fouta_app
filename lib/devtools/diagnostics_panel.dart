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
  final List<Story> stories;
  final String currentUserId;
  final Future<void> Function()? onRefresh;
  const DiagnosticsPanel({
    super.key,
    required this.stories,
    required this.currentUserId,
    this.onRefresh,
  });

  static Future<void> show(BuildContext context, String uid,
      {Future<void> Function()? onRefresh}) async {
    if (!kDebugMode) return;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: DiagnosticsPanel(
          stories: StoryDiagnostics.instance.owners,
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
    buffer.writeln('appId: $APP_ID');
    buffer.writeln('currentUser: ${widget.currentUserId}');
    buffer.writeln('ownersPath: ${FirestorePaths.stories()}');
    buffer.writeln('ownersLoaded: ${widget.stories.length}');
    for (final o in widget.stories.take(3)) {
      buffer.writeln('  owner: ${o.authorId} updatedAt: ${o.postedAt}');
    }
    final me =
        widget.stories.firstWhere((o) => o.authorId == widget.currentUserId,
            orElse: () => const Story(
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

