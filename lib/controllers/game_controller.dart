import 'dart:io';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import '../models/game_config.dart';
import '../utils/video_manager.dart';

class GameController {
  final List<GameConfig> games;
  GameConfig? selectedGame;
  int selectedGameIndex;
  final Player player;
  final String _videoPlayerKey = 'main_player';
  bool isMuted = false;

  GameController({
    required this.games,
    this.selectedGameIndex = 0,
    required this.player,
  }) {
    if (games.isNotEmpty) {
      selectedGame = games[selectedGameIndex];
    }
  }

  void selectNextGame() {
    if (games.isEmpty) return;
    selectedGameIndex = (selectedGameIndex + 1) % games.length;
    selectedGame = games[selectedGameIndex];
    loadGameMedia();
  }

  void selectPreviousGame() {
    if (games.isEmpty) return;
    selectedGameIndex = (selectedGameIndex - 1 + games.length) % games.length;
    selectedGame = games[selectedGameIndex];
    loadGameMedia();
  }

  void selectGameByIndex(int index) {
    if (games.isEmpty || index < 0 || index >= games.length) return;
    selectedGameIndex = index;
    selectedGame = games[index];
    loadGameMedia();
  }

  void loadGameMedia() {
    if (selectedGame != null) {
      if (selectedGame!.videoPath.isNotEmpty &&
          File(selectedGame!.videoPath).existsSync()) {
        // Use the VideoManager to handle the video loading
        VideoManager().loadVideo(
          _videoPlayerKey,
          selectedGame!.videoPath,
          autoPlay: true,
          loop: true,
        );

        // Set mute state
        if (isMuted) {
          player.setVolume(0);
        } else {
          player.setVolume(70); // 70% volume
        }
      } else {
        VideoManager().stopPlayer(_videoPlayerKey);
      }
    }
  }

  void toggleMute() {
    isMuted = VideoManager().toggleMute(_videoPlayerKey);
  }

  Future<bool> launchGame(BuildContext context) async {
    if (selectedGame != null && selectedGame!.executablePath.isNotEmpty) {
      if (File(selectedGame!.executablePath).existsSync()) {
        await Process.run(selectedGame!.executablePath, [], runInShell: true);
        return true;
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Game executable not found!')),
          );
        }
        return false;
      }
    }
    return false;
  }

  void dispose() {
    VideoManager().disposePlayer(_videoPlayerKey);
  }
}
