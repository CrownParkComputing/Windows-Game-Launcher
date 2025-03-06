import 'package:flutter/material.dart';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class GameVideoPlayer extends StatelessWidget {
  final String? selectedGame;
  final String artworkPath;
  final Player player;
  final VideoController controller;
  final bool isMuted;
  final VoidCallback onToggleMute;

  const GameVideoPlayer({
    super.key,
    required this.selectedGame,
    required this.artworkPath,
    required this.player,
    required this.controller,
    required this.isMuted,
    required this.onToggleMute,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedGame == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[800]!, width: 10),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Video player
              Video(
                controller: controller,
                controls:
                    NoVideoControls, // Use NoVideoControls to completely hide controls
                fill: Colors.black, // Fill background with black
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to load a game video
  static void loadGameVideo(String? videoPath, Player player) {
    if (videoPath != null && videoPath.isNotEmpty) {
      final videoFile = File(videoPath);
      if (videoFile.existsSync()) {
        try {
          // Set looping to true when opening the media
          player.open(
            Media(videoFile.path),
            play: true,
          );

          // Configure for continuous playback
          player.setPlaylistMode(PlaylistMode.loop);

          // Monitor playback position and loop when needed
          _startPlaybackMonitoring(player);
        } catch (e) {
          // Removed print statement
        }
      } else {
        // Removed print statement
      }
    }
  }

  // Helper method to ensure video keeps playing
  static void _startPlaybackMonitoring(Player player) {
    // Listen to playback position stream
    player.stream.position.listen((position) {
      if (player.state.duration.inSeconds > 0 &&
          position >= player.state.duration - const Duration(seconds: 1)) {
        // Near the end of the video, seek back to start
        player.seek(Duration.zero);
      }
    });

    // Use a periodic timer as a fallback to ensure looping
    Future.delayed(const Duration(seconds: 5), () => _checkPlayback(player));
  }

  static void _checkPlayback(Player player) {
    // Only continue monitoring if player has media loaded
    if (player.state.playlist.medias.isNotEmpty) {
      // Check if we're near the end or playback stopped
      if (!player.state.playing ||
          (player.state.duration.inSeconds > 0 &&
              player.state.position >=
                  player.state.duration - const Duration(seconds: 1))) {
        player.seek(Duration.zero);
        player.play();
      }

      // Continue monitoring
      Future.delayed(const Duration(seconds: 5), () => _checkPlayback(player));
    }
  }
}
