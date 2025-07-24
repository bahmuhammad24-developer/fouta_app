// lib/services/video_player_manager.dart
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

class VideoPlayerManager with ChangeNotifier {
  final int _poolSize = 3; // A pool of 3 players is a good balance.
  late final List<Player> _playerPool;
  final Map<String, Player> _activePlayers = {};
  final List<String> _playerRequestQueue = [];

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
    if (_activePlayers.containsKey(videoId)) {
      return _activePlayers[videoId];
    }
    
    // Find an available player that is not currently in use
    Player? availablePlayer;
    for (final p in _playerPool) {
      if (!_activePlayers.containsValue(p)) {
        availablePlayer = p;
        break;
      }
    }

    if (availablePlayer != null) {
      _activePlayers[videoId] = availablePlayer;
      debugPrint('Assigned player for videoId: $videoId. Active players: ${_activePlayers.length}');
      return availablePlayer;
    }
    
    // If no player is available, we could implement logic to steal the least recently used one.
    // For now, we simply deny the request if the pool is full.
    debugPrint('No available players in the pool for videoId: $videoId');
    return null;
  }

  void releasePlayer(String videoId) {
    if (_activePlayers.containsKey(videoId)) {
      final playerToRelease = _activePlayers[videoId];
      playerToRelease?.stop(); // Stop playback
      _activePlayers.remove(videoId);
      debugPrint('Released player for videoId: $videoId. Active players: ${_activePlayers.length}');
    }
  }
}