import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../settings_provider.dart';
import 'spinning_disc.dart';
import '../models/game_config.dart';
import 'carousel_video_player.dart';

class GameCarousel extends StatefulWidget {
  final List<GameConfig> games;
  final String mediaType;
  final double width;
  final double height;
  final bool isCarousel;
  final Alignment alignment;
  final Color backgroundColor;
  final int selectedIndex;
  final Function(int)? onGameSelected;
  final bool isEditMode;
  final SettingsProvider settingsProvider;
  final String sectionKey;

  const GameCarousel({
    Key? key,
    required this.games,
    required this.mediaType,
    required this.width,
    required this.height,
    required this.settingsProvider,
    required this.sectionKey,
    this.isCarousel = true,
    this.alignment = Alignment.center,
    this.backgroundColor = Colors.black45,
    this.selectedIndex = 0,
    this.onGameSelected,
    this.isEditMode = false,
  }) : super(key: key);

  @override
  State<GameCarousel> createState() => _GameCarouselState();
}

class _GameCarouselState extends State<GameCarousel> with SingleTickerProviderStateMixin {
  late ScrollController _tickerController;
  late AnimationController _tickerAnimationController;
  String? _storyText;

  @override
  void initState() {
    super.initState();
    _tickerController = ScrollController();
    _tickerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    _loadStoryText();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryText() async {
    if (widget.games.isEmpty) {
      debugPrint('No games available to load story text');
      return;
    }
    
    final game = widget.games[widget.selectedIndex];
    try {
      debugPrint('Loading story text for game: ${game.name}');
      debugPrint('Current story text: ${game.storyText}');
      
      if (game.storyText.isEmpty) {
        debugPrint('No story text available for game: ${game.name}');
        setState(() {
          _storyText = null;
        });
        return;
      }

      setState(() {
        _storyText = widget.settingsProvider.extractStoryText(game.storyText);
      });
      debugPrint('Story text loaded successfully: $_storyText');
    } catch (e) {
      debugPrint('Error loading story text: $e');
      setState(() {
        _storyText = null;
      });
    }
  }

  @override
  void didUpdateWidget(GameCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex || 
        oldWidget.mediaType != widget.mediaType) {
      _loadStoryText();
      // Reset animation when text changes
      _tickerAnimationController
        ..reset()
        ..repeat();
    }
  }

  String _getMediaPath(GameConfig game, String type) {
    final mediaFolder = widget.settingsProvider.mediaFolderPath ?? SettingsProvider.mediaRootFolder;
    switch (type) {
      case 'logo':
        return '$mediaFolder/logo/${game.name}.png';
      case 'artwork_front':
        return '$mediaFolder/artwork_front/${game.name}.png';
      case 'artwork_3d':
        return '$mediaFolder/artwork_3d/${game.name}.png';
      case 'fanart':
        return '$mediaFolder/fanart/${game.name}.jpg';
      case 'video':
        return '$mediaFolder/video/${game.name}.mp4';
      case 'story':
        return '$mediaFolder/story/${game.name}.txt';
      case 'medium_disc':
        return '$mediaFolder/medium_disc/${game.name}.png';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = widget.width.isFinite ? widget.width : constraints.maxWidth;
        final effectiveHeight = widget.height.isFinite ? widget.height : constraints.maxHeight;
        
        // Adjust height for ticker if it's enabled
        final bool showTicker = widget.settingsProvider.showTicker[widget.sectionKey] ?? false;
        final double tickerHeight = showTicker ? 30.0 : 0.0;
        final double contentHeight = effectiveHeight - tickerHeight;
        final itemWidth = contentHeight * 0.85;

        // Get carousel mode from settings provider
        final shouldUseCarousel = widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? widget.isCarousel;

        return Stack(
          children: [
            Container(
              width: effectiveWidth,
              height: effectiveHeight,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
              ),
              child: Column(
                children: [
                  // Add ticker at top if alignment is 'top'
                  if (showTicker && (widget.settingsProvider.tickerAlignment[widget.sectionKey] ?? 'bottom') == 'top')
                    _buildTicker(),
                    
                  // Main content with adjusted height
                  Expanded(
                    child: widget.isEditMode
                      ? _buildEditModePlaceholder(contentHeight, itemWidth)
                      : (shouldUseCarousel && widget.mediaType != 'video'
                          ? _buildCarouselView(contentHeight, itemWidth)
                          : _buildStaticView(contentHeight, itemWidth)),
                  ),
                  
                  // Add ticker at bottom if alignment is 'bottom'
                  if (showTicker && (widget.settingsProvider.tickerAlignment[widget.sectionKey] ?? 'bottom') == 'bottom')
                    _buildTicker(),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Shader _buildTickerGradient(Rect bounds) {
    return const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
      stops: [0.0, 0.05, 0.95, 1.0],
    ).createShader(bounds);
  }

  Widget _buildTicker() {
    debugPrint('Building ticker for section: ${widget.sectionKey}');
    debugPrint('Story text: $_storyText');
    debugPrint('Show ticker setting: ${widget.settingsProvider.showTicker[widget.sectionKey]}');

    // Early return if ticker is disabled or no text
    if (_storyText == null || _storyText!.isEmpty) {
      debugPrint('Ticker not shown: story text is null or empty');
      return const SizedBox.shrink();
    }

    if (!(widget.settingsProvider.showTicker[widget.sectionKey] ?? false)) {
      debugPrint('Ticker not shown: ticker is disabled for section ${widget.sectionKey}');
      return const SizedBox.shrink();
    }

    final alignment = widget.settingsProvider.tickerAlignment[widget.sectionKey] ?? 'bottom';
    final speed = widget.settingsProvider.tickerSpeed[widget.sectionKey] ?? SettingsProvider.defaultTickerSpeed;
    final adjustedSpeed = speed / 100.0;

    debugPrint('Building ticker with alignment: $alignment, speed: $speed');

    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        border: Border(
          top: alignment == 'bottom' ? const BorderSide(color: Colors.white24) : BorderSide.none,
          bottom: alignment == 'top' ? const BorderSide(color: Colors.white24) : BorderSide.none,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 0) {
            return const SizedBox.shrink();
          }

          const textStyle = TextStyle(
            color: Colors.white,
            fontSize: 14,
          );

          // Add spacing gap at the end of text
          final paddedText = '${_storyText!}                                        ';
          
          // Calculate text width without constraints first
          final textSpan = TextSpan(
            text: paddedText,
            style: textStyle,
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
            maxLines: 1,
          );
          textPainter.layout(maxWidth: double.infinity);
          
          final textWidth = textPainter.width;
          final containerWidth = constraints.maxWidth;
          
          return ShaderMask(
            shaderCallback: _buildTickerGradient,
            blendMode: BlendMode.dstIn,
            child: ClipRect(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: AnimatedBuilder(
                  animation: _tickerAnimationController,
                  builder: (context, child) {
                    final offset = containerWidth - (_tickerAnimationController.value * (textWidth + containerWidth) * adjustedSpeed);
                    
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: SizedBox(
                        width: textWidth,
                        child: Text(
                          paddedText,
                          style: textStyle,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Helper method to create a placeholder in edit mode
  Widget _buildEditModePlaceholder(double effectiveHeight, double itemWidth) {
    final effectiveIndex = widget.selectedIndex < widget.games.length ? widget.selectedIndex : 0;
    final displayName =
        widget.games.isNotEmpty ? widget.games[effectiveIndex].name : "No Game";

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getMediaTypeIcon(),
            size: 36,
            color: Colors.white70,
          ),
          const SizedBox(height: 8),
          Text(
            widget.mediaType.replaceAll('_', ' ').toUpperCase(),
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isCarousel ? "CAROUSEL MODE" : "STATIC MODE",
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }

  // Helper method to get an icon representing the media type
  IconData _getMediaTypeIcon() {
    switch (widget.mediaType) {
      case 'logo':
        return Icons.bookmark;
      case 'artwork_front':
        return Icons.image;
      case 'artwork_3d':
        return Icons.view_in_ar;
      case 'fanart':
        return Icons.wallpaper;
      case 'video':
        return Icons.videocam;
      case 'story':
        return Icons.article;
      case 'medium_disc':
        return Icons.album;
      default:
        return Icons.help_outline;
    }
  }

  // Helper method to get border color based on section and edit mode
  Color _getBorderColor() {
    if (!widget.isEditMode) return Colors.grey[800]!;

    // Different colors for different sections in edit mode
    switch (widget.mediaType) {
      case 'logo':
        return Colors.blue.withOpacity(0.7);
      case 'artwork_front':
        return Colors.red.withOpacity(0.7);
      case 'artwork_3d':
        return Colors.green.withOpacity(0.7);
      case 'fanart':
        return Colors.orange.withOpacity(0.7);
      case 'video':
        return Colors.purple.withOpacity(0.7);
      case 'medium_disc':
        return Colors.cyan.withOpacity(0.7);
      case 'story':
        return Colors.amber.withOpacity(0.7);
      default:
        return Colors.grey[800]!;
    }
  }

  Widget _buildCarouselView(double effectiveHeight, double itemWidth) {
    final controller = ScrollController(
      initialScrollOffset: widget.selectedIndex * (itemWidth + 30),
    );

    return Container(
      alignment: widget.alignment,
      child: ListView.builder(
        controller: controller,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: widget.games.length,
        itemBuilder: (context, index) {
          final isSelected = widget.selectedIndex == index;
          return GestureDetector(
            onTap: () {
              if (widget.onGameSelected != null) {
                widget.onGameSelected!(index);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                transform: isSelected && widget.isCarousel
                    ? Matrix4.identity().scaled(1.1)
                    : Matrix4.identity(),
                child: _buildGameItem(
                    widget.games[index], effectiveHeight, itemWidth, isSelected && widget.isCarousel),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaticView(double effectiveHeight, double itemWidth) {
    if (widget.games.isEmpty) {
      return const SizedBox();
    }

    final effectiveIndex = widget.selectedIndex < widget.games.length ? widget.selectedIndex : 0;

    // For videos, use the full width
    final useFullWidth = widget.mediaType == 'video';
    final effectiveWidth = useFullWidth ? widget.width : itemWidth;

    return Align(
      alignment: widget.alignment,
      child: _buildGameItem(
          widget.games[effectiveIndex], effectiveHeight, effectiveWidth, true),
    );
  }

  Widget _buildGameItem(GameConfig game, double effectiveHeight,
      double itemWidth, bool isSelected) {
    String mediaPath = _getMediaPath(game, widget.mediaType);
    if (!File(mediaPath).existsSync() && widget.mediaType != 'story') {
      return const SizedBox(width: 20);
    }

    final itemHeight = (effectiveHeight - 10)
        .clamp(1.0, double.infinity);

    // For videos, don't add any margins or padding
    final useFullWidth = widget.mediaType == 'video';
    final effectiveWidth = useFullWidth ? widget.width : itemWidth;

    return Container(
      width: effectiveWidth,
      height: itemHeight,
      decoration: (isSelected && widget.isCarousel && widget.mediaType != 'video')
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2)
              ],
            )
          : null,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: effectiveWidth,
            maxHeight: itemHeight,
          ),
          child: _buildMediaWidget(game, mediaPath, effectiveWidth, itemHeight),
        ),
      ),
    );
  }

  Widget _buildMediaWidget(GameConfig game, String mediaPath, double itemWidth, double itemHeight) {
    if (!File(mediaPath).existsSync() && widget.mediaType != 'story') {
      return Container(
        color: widget.backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getMediaTypeIcon(),
                size: 48,
                color: Colors.white54,
              ),
              const SizedBox(height: 8),
              Text(
                'No ${widget.mediaType.replaceAll('_', ' ')} available',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    switch (widget.mediaType) {
      case 'video':
        return CarouselVideoPlayer(
          videoPath: mediaPath,
          width: itemWidth,
          height: itemHeight,
          backgroundColor: widget.backgroundColor,
        );
      case 'story':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(
              game.storyText.isEmpty 
                ? 'No story text available'
                : widget.settingsProvider.extractStoryText(game.storyText),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      case 'medium_disc':
        return SizedBox(
          width: itemWidth,
          height: itemHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Title section with flexible height
              Expanded(
                flex: 1,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      game.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
              // Disc section with fixed size
              SizedBox(
                width: itemWidth,
                height: itemWidth,
                child: ClipOval(
                  child: SpinningDisc(
                    imagePath: mediaPath,
                    size: itemWidth,
                  ),
                ),
              ),
              // Bottom padding space
              const SizedBox(height: 16),
            ],
          ),
        );
      default:
        return Image.file(
          File(mediaPath),
          fit: BoxFit.contain,
        );
    }
  }
}
