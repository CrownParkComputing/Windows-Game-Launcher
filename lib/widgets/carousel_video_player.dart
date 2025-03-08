import 'package:flutter/material.dart';
import 'dart:io';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter/foundation.dart' show compute;

class CarouselVideoPlayer extends StatefulWidget {
  final String videoPath;
  final double width;
  final double height;
  final Color backgroundColor;

  const CarouselVideoPlayer({
    Key? key,
    required this.videoPath,
    required this.width,
    required this.height,
    this.backgroundColor = Colors.black45,
  }) : super(key: key);

  @override
  _CarouselVideoPlayerState createState() => _CarouselVideoPlayerState();
}

class _CarouselVideoPlayerState extends State<CarouselVideoPlayer> {
  late final Player player;
  late final VideoController controller;
  bool isInitialized = false;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    _initializePlayer();
  }

  // This function initializes the player off the main thread
  Future<void> _initializePlayer() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // First check if the file exists
      if (!File(widget.videoPath).existsSync()) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        return;
      }

      // Initialize media off the main thread to prevent UI freezing
      await compute(_initializeMediaOffThread, widget.videoPath)
          .then((_) async {
        // Back on main thread
        await player.open(
          Media(widget.videoPath),
          play: true,
        );
        player.setPlaylistMode(PlaylistMode.loop);
        player.setVolume(70); // Lower volume to avoid loud videos

        if (mounted) {
          setState(() {
            isInitialized = true;
            isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        debugPrint('Error initializing video player: $e');
      }
    }
  }

  // Static method to run in a separate isolate
  static Future<void> _initializeMediaOffThread(String path) async {
    // This runs on a separate thread - do any heavy media parsing here
    final file = File(path);
    if (!file.existsSync()) {
      throw Exception('Video file does not exist: $path');
    }
    
    // Check basic file details (non-blocking operations)
    final fileSize = await file.length();
    if (fileSize <= 0) {
      throw Exception('Invalid video file size');
    }
  }

  @override
  void didUpdateWidget(CarouselVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If video path changed, reinitialize the player
    if (oldWidget.videoPath != widget.videoPath) {
      _releaseResources();
      _initializePlayer();
    }
  }

  void _releaseResources() async {
    try {
      await player.stop();
    } catch (e) {
      debugPrint('Error stopping player: $e');
    }
  }

  @override
  void dispose() {
    _releaseResources();
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (hasError) {
      return Container(
        width: widget.width,
        height: widget.height,
        color: widget.backgroundColor,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 40, color: Colors.white),
              SizedBox(height: 12),
              Text(
                'Failed to load video',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox.expand(
      child: Video(
        controller: controller,
        controls: NoVideoControls,
        fit: BoxFit.cover,
        width: widget.width,
        height: widget.height,
      ),
    );
  }
}
