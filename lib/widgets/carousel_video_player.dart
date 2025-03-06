import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

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
  late final player = Player();
  late final controller = VideoController(player);

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() async {
    await player.open(
      Media(widget.videoPath),
      play: true,
    );
    player.setPlaylistMode(PlaylistMode.loop);
  }

  @override
  void didUpdateWidget(CarouselVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If video path changed, update the player
    if (oldWidget.videoPath != widget.videoPath) {
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
