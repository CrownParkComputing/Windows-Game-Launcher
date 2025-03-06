import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

/// A singleton helper class to manage video resources and handle common video operations
class VideoManager {
  static final VideoManager _instance = VideoManager._internal();

  factory VideoManager() {
    return _instance;
  }

  VideoManager._internal();

  // Map to keep track of player instances
  final Map<String, Player> _players = {};

  /// Initialize the media kit if needed
  Future<void> initialize() async {
    // This is already called in main.dart, but including here for safety
    try {
      // Fix: Don't use await inside the try block with void return type
      MediaKit.ensureInitialized();
    } catch (e) {
      // Removed debugPrint statement
    }
  }

  /// Get or create a player for a specific key
  Player getPlayer(String key) {
    if (!_players.containsKey(key)) {
      _players[key] = Player();
    }
    return _players[key]!;
  }

  /// Load a video file into the player
  Future<void> loadVideo(String key, String videoPath,
      {bool autoPlay = true, bool loop = true}) async {
    if (!File(videoPath).existsSync()) {
      // Removed debugPrint statement
      return;
    }

    try {
      final player = getPlayer(key);

      // Use compute to move heavy work off the main thread
      await compute((_) async {
        await player.open(
          Media(videoPath),
          play: autoPlay,
        );

        if (loop) {
          player.setPlaylistMode(PlaylistMode.loop);
        }
      }, null);

      // Set volume lower to avoid loud videos
      player.setVolume(70);
    } catch (e) {
      // Removed debugPrint statement
    }
  }

  /// Stop a player by key
  void stopPlayer(String key) {
    if (_players.containsKey(key)) {
      _players[key]?.stop();
    }
  }

  /// Dispose of a player by key
  void disposePlayer(String key) {
    if (_players.containsKey(key)) {
      _players[key]?.dispose();
      _players.remove(key);
    }
  }

  /// Dispose of all players
  void disposeAll() {
    for (final player in _players.values) {
      player.dispose();
    }
    _players.clear();
  }

  /// Toggle mute state for a player
  bool toggleMute(String key) {
    if (!_players.containsKey(key)) return false;

    final player = _players[key]!;
    final isMuted = player.state.volume == 0;

    if (isMuted) {
      player.setVolume(70); // Restore to 70% volume
    } else {
      player.setVolume(0); // Mute
    }

    return !isMuted; // Return the new state (true = now muted)
  }
}
