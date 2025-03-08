import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

/// A singleton helper class to manage video resources and handle common video operations
class VideoManager {
  static final VideoManager _instance = VideoManager._internal();
  
  // Flag to avoid duplicate initialization
  bool _isInitialized = false;
  
  // Maximum number of players to keep in memory simultaneously
  final int _maxCachedPlayers = 3;
  
  // LRU tracking for players
  final List<String> _playerUsageOrder = [];

  factory VideoManager() {
    return _instance;
  }

  VideoManager._internal();

  // Map to keep track of player instances
  final Map<String, Player> _players = {};
  
  // Map to track which keys are currently initializing
  final Map<String, Completer<Player>> _initializingPlayers = {};

  /// Initialize the media kit if needed
  Future<void> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized) return;
    
    try {
      // MediaKit.ensureInitialized can be called multiple times safely
      MediaKit.ensureInitialized();
      _isInitialized = true;
      debugPrint('MediaKit initialized successfully');
    } catch (e) {
      debugPrint('Error initializing MediaKit: $e');
    }
  }

  /// Get or create a player for a specific key with deferred initialization
  Future<Player> getPlayerAsync(String key) async {
    // If this key already has a player, mark it as recently used and return it
    if (_players.containsKey(key)) {
      _updatePlayerUsage(key);
      return _players[key]!;
    }
    
    // If this key is currently being initialized, wait for it to complete
    if (_initializingPlayers.containsKey(key)) {
      return _initializingPlayers[key]!.future;
    }
    
    // Create a completer to track initialization
    final completer = Completer<Player>();
    _initializingPlayers[key] = completer;
    
    try {
      // If we've reached the maximum number of cached players, clean up the oldest one
      if (_players.length >= _maxCachedPlayers) {
        await _cleanupOldestPlayer();
      }
      
      // Create and store the new player
      final player = Player();
      _players[key] = player;
      _updatePlayerUsage(key);
      
      // Complete the initialization
      completer.complete(player);
      _initializingPlayers.remove(key);
      
      return player;
    } catch (e) {
      completer.completeError(e);
      _initializingPlayers.remove(key);
      rethrow;
    }
  }
  
  /// Get player synchronously (creates if needed, but prefer async version for better performance)
  Player getPlayer(String key) {
    if (!_players.containsKey(key)) {
      _players[key] = Player();
      _updatePlayerUsage(key);
    } else {
      _updatePlayerUsage(key);
    }
    return _players[key]!;
  }

  /// Load a video file into the player with proper resource management
  Future<bool> loadVideo(String key, String videoPath,
      {bool autoPlay = true, bool loop = true}) async {
    if (!File(videoPath).existsSync()) {
      debugPrint('Video file not found: $videoPath');
      return false;
    }

    try {
      // Get player asynchronously to handle resource constraints
      final player = await getPlayerAsync(key);
      
      // Stop any currently playing content first
      await player.stop();
      
      // Use compute to move heavy work off the main thread
      await compute(_validateVideoFile, videoPath);
      
      // Now open the media on the main thread (safer for player API)
      await player.open(
        Media(videoPath),
        play: autoPlay,
      );

      if (loop) {
        player.setPlaylistMode(PlaylistMode.loop);
      }
      
      // Set volume lower to avoid loud videos
      player.setVolume(70);
      return true;
    } catch (e) {
      debugPrint('Error loading video: $e');
      return false;
    }
  }
  
  // Static method for compute to validate video file
  static Future<void> _validateVideoFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Video file not found: $path');
    }
    
    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw Exception('Empty video file: $path');
    }
  }
  
  /// Mark a player as recently used
  void _updatePlayerUsage(String key) {
    // Remove key if it already exists in the usage order
    _playerUsageOrder.remove(key);
    // Add it to the end (most recently used)
    _playerUsageOrder.add(key);
  }
  
  /// Clean up the least recently used player
  Future<void> _cleanupOldestPlayer() async {
    if (_playerUsageOrder.isEmpty) return;
    
    // Get the oldest used player key
    final oldestKey = _playerUsageOrder.removeAt(0);
    
    // Skip if this player is being initialized
    if (_initializingPlayers.containsKey(oldestKey)) {
      return;
    }
    
    // Get the player and clean it up
    final player = _players[oldestKey];
    if (player != null) {
      try {
        await player.stop();
        player.dispose();
        _players.remove(oldestKey);
        debugPrint('Cleaned up oldest player: $oldestKey');
      } catch (e) {
        debugPrint('Error cleaning up player $oldestKey: $e');
      }
    }
  }

  /// Stop a player by key
  Future<void> stopPlayer(String key) async {
    if (_players.containsKey(key)) {
      try {
        await _players[key]?.stop();
      } catch (e) {
        debugPrint('Error stopping player $key: $e');
      }
    }
  }
  
  /// Release all resources - call when switching media types or on app exit
  Future<void> releaseAllResources() async {
    // Create a copy of keys to avoid concurrent modification
    final keys = List<String>.from(_players.keys);
    
    for (final key in keys) {
      try {
        final player = _players[key];
        if (player != null) {
          await player.stop();
          player.dispose();
        }
      } catch (e) {
        debugPrint('Error disposing player $key: $e');
      }
    }
    
    _players.clear();
    _playerUsageOrder.clear();
    debugPrint('Released all video player resources');
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
  
  /// Dispose of a player by key
  void disposePlayer(String key) {
    if (_players.containsKey(key)) {
      try {
        final player = _players[key];
        if (player != null) {
          player.dispose();
        }
        _players.remove(key);
        _playerUsageOrder.remove(key);
        debugPrint('Disposed player: $key');
      } catch (e) {
        debugPrint('Error disposing player $key: $e');
      }
    }
  }
}
