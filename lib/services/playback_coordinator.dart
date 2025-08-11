import 'package:media_kit/media_kit.dart';

/// Coordinates audio/video playback so that only one [Player] is active
/// at a time across the app.
class PlaybackCoordinator {
  PlaybackCoordinator._();
  static final PlaybackCoordinator instance = PlaybackCoordinator._();

  final Set<Player> _players = {};
  Player? _active;

  /// Registers a [Player] with the coordinator.
  void register(Player player) {
    _players.add(player);
  }

  /// Unregisters a [Player].
  void unregister(Player player) {
    _players.remove(player);
    if (_active == player) {
      _active = null;
    }
  }

  /// Sets the given [player] as active and pauses any previously active player.
  void setActive(Player player) {
    if (_active == player) return;
    _active?.pause();
    _active = player;
  }

  /// Pause all registered players.
  void pauseAll() {
    for (final p in _players) {
      try {
        p.pause();
      } catch (_) {
        // ignore errors from disposed players
      }
    }
    _active = null;
  }
}
