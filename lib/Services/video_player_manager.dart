// lib/services/video_player_manager.dart
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

class VideoPlayerManager with ChangeNotifier {
  final int _poolSize = 3; // A pool of 3 players is a good balance.
  late final List<Player> _playerPool;
  final Map<String, Player> _activePlayers = {};
  // Maintain LRU order of video IDs that have been assigned players.
  final List<String> _lruOrder = [];

  VideoPlayerManager() {
    _playerPool = List.generate(
      _poolSize,
      (index) => Player(
        configuration: const PlayerConfiguration(
          logLevel: MPVLogLevel.warn, // Reduce console logs
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final player in _playerPool) {
      player.dispose();
    }
    super.dispose();
  }

  Player? requestPlayer(String videoId) {
    // If this video is already using a player, update its position in the LRU order
    if (_activePlayers.containsKey(videoId)) {
      _lruOrder.remove(videoId);
      _lruOrder.add(videoId);
      return _activePlayers[videoId];
    }

    // Try to find a free player in the pool
    Player? availablePlayer;
    for (final p in _playerPool) {
      if (!_activePlayers.containsValue(p)) {
        availablePlayer = p;
        break;
      }
    }

    if (availablePlayer == null) {
      // No free player: release the least recently used video player
      if (_lruOrder.isNotEmpty) {
        final lruVideoId = _lruOrder.removeAt(0);
        releasePlayer(lruVideoId);
        // After releasing, there should be a free player
        for (final p in _playerPool) {
          if (!_activePlayers.containsValue(p)) {
            availablePlayer = p;
            break;
          }
        }
      }
    }

    if (availablePlayer != null) {
      _activePlayers[videoId] = availablePlayer;
      // Add to LRU list as most recently used
      _lruOrder.remove(videoId);
      _lruOrder.add(videoId);
      debugPrint('Assigned player for videoId: $videoId. Active players: ${_activePlayers.length}');
      return availablePlayer;
    }

    // Still no player available (should not happen), return null
    debugPrint('No available players in the pool for videoId: $videoId');
    return null;
  }

  void releasePlayer(String videoId) {
    if (_activePlayers.containsKey(videoId)) {
      final playerToRelease = _activePlayers[videoId];
      playerToRelease?.stop(); // Stop playback
      _activePlayers.remove(videoId);
      _lruOrder.remove(videoId);
      debugPrint('Released player for videoId: $videoId. Active players: ${_activePlayers.length}');
    }
  }
}