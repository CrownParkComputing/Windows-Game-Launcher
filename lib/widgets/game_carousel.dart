import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../settings_provider.dart';
import 'spinning_disc.dart';
import '../models/game_config.dart';
import 'carousel_video_player.dart';

enum ResizeDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight
}

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
  late ScrollController _carouselScrollController;
  String? _storyText;
  int _previousSelectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tickerController = ScrollController();
    _carouselScrollController = ScrollController();
    _tickerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    _loadStoryText();
    _previousSelectedIndex = widget.selectedIndex;
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _carouselScrollController.dispose();
    _tickerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryText() async {
    if (widget.games.isEmpty) {
      return;
    }
    
    final game = widget.games[widget.selectedIndex];
    try {
      if (game.storyText.isEmpty) {
        setState(() {
          _storyText = null;
        });
        return;
      }

      setState(() {
        _storyText = widget.settingsProvider.extractStoryText(game.storyText);
      });
    } catch (e) {
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
      
      // Track the change in selected index for animation
      _previousSelectedIndex = oldWidget.selectedIndex;
      
      // Scroll to center the selected item
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedItem();
      });
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
    // Special handling for static_image
    if (widget.mediaType == 'static_image') {
      final staticImagePath = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
      
      if (staticImagePath != null) {
        final file = File(staticImagePath);
        final exists = file.existsSync();
        if (!exists) {
          return Center(
            child: Container(
              color: widget.backgroundColor,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.broken_image,
                    size: 64,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Image not found',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        // No static image path set
      }
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = constraints.maxWidth;
        final effectiveHeight = constraints.maxHeight;
        
        // Adjust height for ticker if it's enabled
        final bool showTicker = widget.settingsProvider.showTicker[widget.sectionKey] ?? false;
        final double tickerHeight = showTicker ? 30.0 : 0.0;
        final double contentHeight = effectiveHeight - tickerHeight;
        const spacing = 10.0;
        final numItemsToShow = widget.settingsProvider.carouselItemCount[widget.sectionKey] ?? SettingsProvider.defaultCarouselItemCount;
        final itemWidth = (effectiveWidth - (spacing * (numItemsToShow - 1))) / numItemsToShow;

        // Get carousel mode from settings provider
        final shouldUseCarousel = widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? widget.isCarousel;
        final bool isStaticImage = !shouldUseCarousel;

        // Special handling for static_image media type
        if (widget.mediaType == 'static_image') {
          final staticImagePath = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
          
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
                        : _buildStaticImageView(contentHeight, effectiveWidth, staticImagePath),
                    ),
                    
                    // Add ticker at bottom if alignment is 'bottom'
                    if (showTicker && (widget.settingsProvider.tickerAlignment[widget.sectionKey] ?? 'bottom') == 'bottom')
                      _buildTicker(),
                  ],
                ),
              ),
            ],
          );
        }

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
                      : (isStaticImage
                          ? _buildStaticView(contentHeight, effectiveWidth)
                          : _buildCarouselView(contentHeight, effectiveWidth)),
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
    // Early return if ticker is disabled or no text
    if (_storyText == null || _storyText!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (!(widget.settingsProvider.showTicker[widget.sectionKey] ?? false)) {
      return const SizedBox.shrink();
    }

    final alignment = widget.settingsProvider.tickerAlignment[widget.sectionKey] ?? 'bottom';
    final speed = widget.settingsProvider.tickerSpeed[widget.sectionKey] ?? SettingsProvider.defaultTickerSpeed;
    final adjustedSpeed = speed / 100.0;

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
    
    // Check if this section is in carousel mode
    final isCarouselMode = widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? widget.isCarousel;
    
    // Get display text for media type
    String mediaTypeDisplay = widget.mediaType;
    if (widget.mediaType == 'static_image') {
      final staticImagePath = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
      if (staticImagePath != null) {
        // Extract just the filename from the path
        final fileName = staticImagePath.split(Platform.pathSeparator).last;
        mediaTypeDisplay = "STATIC IMAGE: $fileName";
      } else {
        mediaTypeDisplay = "STATIC IMAGE";
      }
    } else {
      mediaTypeDisplay = widget.mediaType.replaceAll('_', ' ').toUpperCase();
    }

    return Stack(
      children: [
        Center(
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
                mediaTypeDisplay,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCarouselMode ? "CAROUSEL MODE" : "STATIC MODE",
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
        ),
        
        // Only show carousel item count control in edit mode AND when carousel mode is enabled
        if (widget.isEditMode && isCarouselMode)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text(
                    "ITEMS: ",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // Decrease carousel items (minimum 1)
                      final currentCount = widget.settingsProvider.carouselItemCount[widget.sectionKey] ?? 
                          SettingsProvider.defaultCarouselItemCount;
                      if (currentCount > 1) {
                        widget.settingsProvider.setCarouselItemCount(widget.sectionKey, currentCount - 1);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.red,
                      child: const Text(
                        "-",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    color: Colors.grey.shade800,
                    child: Text(
                      "${widget.settingsProvider.carouselItemCount[widget.sectionKey] ?? SettingsProvider.defaultCarouselItemCount}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      // Increase carousel items (maximum 7)
                      final currentCount = widget.settingsProvider.carouselItemCount[widget.sectionKey] ?? 
                          SettingsProvider.defaultCarouselItemCount;
                      if (currentCount < 7) {
                        widget.settingsProvider.setCarouselItemCount(widget.sectionKey, currentCount + 1);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.green,
                      child: const Text(
                        "+",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
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
      case 'static_image':
        return Icons.photo_library;
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

  // Get the transition direction (-1 for left, 1 for right)
  int _getTransitionDirection() {
    if (_previousSelectedIndex < widget.selectedIndex) {
      return -1; // Moving right, items shift left
    } else if (_previousSelectedIndex > widget.selectedIndex) {
      return 1; // Moving left, items shift right
    }
    return 0; // No movement
  }

  // Helper method to scroll to the selected item
  void _scrollToSelectedItem() {
    if (!_carouselScrollController.hasClients) return;
    
    // Get the number of items to show from settings
    final numItemsToShow = widget.settingsProvider.carouselItemCount[widget.sectionKey] ?? 
        SettingsProvider.defaultCarouselItemCount;
    
    // Calculate item width and spacing
    final safeWidth = widget.width.isFinite ? widget.width : 300.0;
    const spacing = 10.0;
    final displayItemWidth = (safeWidth - (spacing * (numItemsToShow + 1))) / numItemsToShow;
    
    // Calculate the number of duplicated items before the real items
    final numDuplicatedBeforeItems = widget.games.length > 1 ? 
        math.min(numItemsToShow, widget.games.length) : 0;
    
    // Calculate the offset based on the selected index plus duplicated items
    final itemTotalWidth = displayItemWidth + spacing;
    
    // Start with the initial spacing
    double offset = spacing;
    
    // Add width of duplicated items before actual items
    offset += numDuplicatedBeforeItems * itemTotalWidth;
    
    // Add width up to the selected item
    offset += widget.selectedIndex * itemTotalWidth;
    
    // Adjust to center the item in the viewport
    offset -= (safeWidth - displayItemWidth) / 2;
    
    // Ensure offset is within bounds
    final maxOffset = _carouselScrollController.position.maxScrollExtent;
    const minOffset = 0.0;
    final safeOffset = math.max(minOffset, math.min(offset, maxOffset));
    
    // Animate to the position
    _carouselScrollController.animateTo(
      safeOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildCarouselView(double height, double width) {
    if (widget.games.isEmpty) return const SizedBox.shrink();

    // Get the number of items to show from settings
    final numItemsToShow = widget.settingsProvider.carouselItemCount[widget.sectionKey] ?? 
        SettingsProvider.defaultCarouselItemCount;
    
    // Calculate item width and spacing
    final safeWidth = width.isFinite ? width : 300.0;
    const spacing = 10.0;
    final displayItemWidth = (safeWidth - (spacing * (numItemsToShow + 1))) / numItemsToShow;
    
    // Adjust height calculations to prevent overflow
    final itemHeight = height * 0.75; // Reduced from 0.8 to give more room for navigation
    final navigationHeight = height * 0.25; // Explicit height for navigation section
    
    // Add more duplicates at each end to ensure smooth continuous scrolling
    final int numDuplicatesNeeded = (numItemsToShow * 3).round();
    final numDuplicatedItems = widget.games.length > 1 ? 
        math.min(numDuplicatesNeeded, widget.games.length * 3) : 0;
    
    final totalItemsWidth = (widget.games.length + (numDuplicatedItems * 2)) * (displayItemWidth + spacing) + spacing;
    
    // Create list of items (same as before)
    final List<Widget> allItems = [];
    
    // Add duplicated items at the start
    if (widget.games.length > 1) {
      for (var i = 0; i < numDuplicatedItems; i++) {
        final gameIndex = (widget.games.length - 1) - (i % widget.games.length);
        allItems.add(_buildCarouselItem(displayItemWidth, itemHeight, gameIndex, spacing));
      }
    }
    
    // Add main items
    for (var i = 0; i < widget.games.length; i++) {
      allItems.add(_buildCarouselItem(displayItemWidth, itemHeight, i, spacing));
    }
    
    // Add duplicated items at the end
    if (widget.games.length > 1) {
      for (var i = 0; i < numDuplicatedItems; i++) {
        final gameIndex = i % widget.games.length;
        allItems.add(_buildCarouselItem(displayItemWidth, itemHeight, gameIndex, spacing));
      }
    }
    
    return SizedBox(
      height: height,
      width: safeWidth,
      child: Column(
        children: [
          // Main carousel with items - explicit height
          SizedBox(
            height: itemHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                return true;
              },
              child: SingleChildScrollView(
                controller: _carouselScrollController,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  width: totalItemsWidth,
                  height: itemHeight,
                  child: Stack(
                    children: [
                      Row(
                        children: [
                          const SizedBox(width: spacing),
                          ...allItems,
                        ],
                      ),
                      Positioned(
                        left: safeWidth / 2 - displayItemWidth / 2,
                        top: 0,
                        child: Container(
                          width: displayItemWidth,
                          height: itemHeight,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Navigation section with explicit height
          SizedBox(
            height: navigationHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 40),
                  icon: const Icon(Icons.arrow_left, color: Colors.white, size: 32),
                  onPressed: _onLeftArrowPressed,
                ),
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      widget.games[widget.selectedIndex].name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 40),
                  icon: const Icon(Icons.arrow_right, color: Colors.white, size: 32),
                  onPressed: _onRightArrowPressed,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build a carousel item
  Widget _buildCarouselItem(double displayItemWidth, double itemHeight, int index, double spacing) {
    return GestureDetector(
      onTap: () {
        if (widget.onGameSelected != null) {
          widget.onGameSelected!(index);
        }
      },
      child: Container(
        width: displayItemWidth,
        height: itemHeight,
        margin: EdgeInsets.symmetric(horizontal: spacing / 2),
        child: _buildGameItem(
          widget.games[index],
          itemHeight,
          displayItemWidth,
          index == widget.selectedIndex
        ),
      ),
    );
  }

  Widget _buildStaticView(double effectiveHeight, double itemWidth) {
    if (widget.games.isEmpty) {
      return const SizedBox();
    }

    final effectiveIndex = widget.selectedIndex < widget.games.length ? widget.selectedIndex : 0;
    // Always use full width for video to maximize display area
    final useFullWidth = widget.mediaType == 'video';
    final effectiveWidth = useFullWidth ? double.infinity : itemWidth;

    return Center(
      child: Container(
        width: effectiveWidth,
        height: effectiveHeight,
        alignment: Alignment.center,
        child: _buildGameItem(
            widget.games[effectiveIndex], effectiveHeight, effectiveWidth, true),
      ),
    );
  }

  Widget _buildGameItem(GameConfig game, double height, double width, bool isSelected) {
    // Determine which type of view to show based on media type
    if (widget.mediaType == 'static_image') {
      // Get the static image path for this section
      final staticImagePath = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
      
      return _buildStaticImageInGameItem(game, height, width, staticImagePath, isSelected);
    } else if (widget.mediaType == 'video') {
      final videoPath = _getMediaPath(game, 'video');
      final videoFile = File(videoPath);
      
      if (videoFile.existsSync()) {
        final aspectRatio = widget.settingsProvider.getVideoAspectRatio(widget.sectionKey) ?? 16/9;
        
        double videoWidth = width;
        double videoHeight = videoWidth / aspectRatio;
        
        if (videoHeight > height) {
          videoHeight = height;
          videoWidth = videoHeight * aspectRatio;
        }
        
        return _buildCarouselVideoPlayer(game, videoWidth, videoHeight, isSelected);
      } else {
        return _buildGameCover(game, height, width, isSelected);
      }
    } else {
      return _buildGameCover(game, height, width, isSelected);
    }
  }

  Widget _buildStaticImageInGameItem(GameConfig game, double height, double width, String? staticImagePath, bool isSelected) {
    if (staticImagePath == null) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        color: widget.backgroundColor,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 12),
            Text(
              'No static image selected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    final file = File(staticImagePath);
    final exists = file.existsSync();
    
    if (!exists) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        color: widget.backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Image not found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              staticImagePath,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    try {
      return Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Container(
                color: widget.backgroundColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Error loading image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Center(
        child: Container(
          color: widget.backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'Exception loading image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCarouselVideoPlayer(GameConfig game, double width, double height, bool isSelected) {
    // Get the video aspect ratio from settings or use default
    final aspectRatio = widget.settingsProvider.getVideoAspectRatio(widget.sectionKey) ?? 16/9;
    
    // Calculate dimensions to fill the entire space while maintaining aspect ratio
    final containerAspectRatio = width / height;
    
    double videoWidth, videoHeight;
    
    // If container is wider than the video aspect ratio, fill height and calculate width
    if (containerAspectRatio > aspectRatio) {
      videoHeight = height;
      videoWidth = videoHeight * aspectRatio;
    } 
    // If container is taller than the video aspect ratio, fill width and calculate height
    else {
      videoWidth = width;
      videoHeight = videoWidth / aspectRatio;
    }
    
    return Stack(
      children: [
        // Video container with custom dimensions
        Center(
          child: Container(
            width: videoWidth,
            height: videoHeight,
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.isEditMode ? Colors.blue.withOpacity(0.7) : Colors.transparent,
                width: widget.isEditMode ? 2 : 0,
              ),
              boxShadow: widget.isEditMode ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                // Video player
                CarouselVideoPlayer(
                  videoPath: game.videoPath,
                  width: videoWidth,
                  height: videoHeight,
                ),
                
                // Semi-transparent overlay to indicate edit mode
                if (widget.isEditMode)
                Container(
                  width: videoWidth,
                  height: videoHeight,
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "VIDEO EDIT MODE\nDrag corners to resize",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Resize handles - only show in edit mode
        if (widget.isEditMode) ...[
          // Bottom right corner
          Positioned(
            right: (width - videoWidth) / 2,
            bottom: (height - videoHeight) / 2,
            child: _buildResizeHandle(videoWidth, videoHeight, ResizeDirection.bottomRight),
          ),
          
          // Bottom left corner
          Positioned(
            left: (width - videoWidth) / 2,
            bottom: (height - videoHeight) / 2,
            child: _buildResizeHandle(videoWidth, videoHeight, ResizeDirection.bottomLeft),
          ),
          
          // Top right corner
          Positioned(
            right: (width - videoWidth) / 2,
            top: (height - videoHeight) / 2,
            child: _buildResizeHandle(videoWidth, videoHeight, ResizeDirection.topRight),
          ),
          
          // Top left corner
          Positioned(
            left: (width - videoWidth) / 2,
            top: (height - videoHeight) / 2,
            child: _buildResizeHandle(videoWidth, videoHeight, ResizeDirection.topLeft),
          ),
          
          // Aspect ratio controls
          if (widget.isEditMode)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey[700]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Aspect Ratio: ${aspectRatio.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildAspectRatioButton("16:9", 16/9),
                      const SizedBox(width: 4),
                      _buildAspectRatioButton("4:3", 4/3),
                      const SizedBox(width: 4),
                      _buildAspectRatioButton("1:1", 1),
                      const SizedBox(width: 4),
                      _buildCustomAspectRatioDialog(),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          widget.settingsProvider.resetVideoAspectRatio(widget.sectionKey);
                          widget.settingsProvider.forceSave();
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  // Helper method to build a resize handle
  Widget _buildResizeHandle(double videoWidth, double videoHeight, ResizeDirection direction) {
    // Determine the alignment and icon based on direction
    CrossAxisAlignment alignment;
    IconData icon;
    String label;
    
    switch (direction) {
      case ResizeDirection.topLeft:
        alignment = CrossAxisAlignment.start;
        icon = Icons.north_west;
        label = "Resize";
        break;
      case ResizeDirection.topRight:
        alignment = CrossAxisAlignment.end;
        icon = Icons.north_east;
        label = "Resize";
        break;
      case ResizeDirection.bottomLeft:
        alignment = CrossAxisAlignment.start;
        icon = Icons.south_west;
        label = "Resize";
        break;
      case ResizeDirection.bottomRight:
        alignment = CrossAxisAlignment.end;
        icon = Icons.south_east;
        label = "Drag to resize";
        break;
    }
    
    return Column(
      crossAxisAlignment: alignment,
      children: [
        if (direction == ResizeDirection.bottomRight) // Only show label on bottom right handle
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "Drag to resize",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
          ),
        if (direction == ResizeDirection.bottomRight)
          const SizedBox(height: 4),
        GestureDetector(
          onPanUpdate: (details) {
            // Calculate new dimensions based on drag and direction
            double newWidth = videoWidth;
            double newHeight = videoHeight;
            
            switch (direction) {
              case ResizeDirection.topLeft:
                // For top-left, we need to adjust both width and height in the opposite direction
                newWidth = videoWidth - details.delta.dx;
                newHeight = videoHeight - details.delta.dy;
                break;
              case ResizeDirection.topRight:
                // For top-right, we adjust width in the same direction and height in the opposite
                newWidth = videoWidth + details.delta.dx;
                newHeight = videoHeight - details.delta.dy;
                break;
              case ResizeDirection.bottomLeft:
                // For bottom-left, we adjust width in the opposite direction and height in the same
                newWidth = videoWidth - details.delta.dx;
                newHeight = videoHeight + details.delta.dy;
                break;
              case ResizeDirection.bottomRight:
                // For bottom-right, we adjust both in the same direction
                newWidth = videoWidth + details.delta.dx;
                newHeight = videoHeight + details.delta.dy;
                break;
            }
            
            // Ensure minimum size
            if (newWidth < 50 || newHeight < 50) return;
            
            // Calculate and save the new aspect ratio
            double newAspectRatio = newWidth / newHeight;
            widget.settingsProvider.setVideoAspectRatio(widget.sectionKey, newAspectRatio);
            
            // Force an immediate save to ensure the aspect ratio persists
            widget.settingsProvider.forceSave();
            
            // Force a rebuild
            setState(() {});
          },
          child: Container(
            width: 40, // Increased from 30
            height: 40, // Increased from 30
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(20), // Increased from 15
              border: Border.all(color: Colors.white, width: 3), // Increased from 2
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24, // Increased from 18
            ),
          ),
        ),
      ],
    );
  }
  
  // Helper method to build an aspect ratio button
  Widget _buildAspectRatioButton(String label, double ratio) {
    final currentRatio = widget.settingsProvider.getVideoAspectRatio(widget.sectionKey) ?? 16/9;
    final isSelected = (currentRatio - ratio).abs() < 0.1;
    
    return InkWell(
      onTap: () {
        widget.settingsProvider.setVideoAspectRatio(widget.sectionKey, ratio);
        // Force an immediate save to ensure the aspect ratio persists
        widget.settingsProvider.forceSave();
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAspectRatioDialog() {
    return GestureDetector(
      onTap: () => _showCustomAspectRatioDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.aspect_ratio, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text(
              "Custom",
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomAspectRatioDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        final aspectRatioController = TextEditingController();

        return AlertDialog(
          title: const Text('Enter Custom Aspect Ratio'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: aspectRatioController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Aspect Ratio (e.g., 16:9)',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a valid aspect ratio';
                    }
                    final parts = value.split(':');
                    if (parts.length != 2) {
                      return 'Please enter a valid format (e.g., 16:9)';
                    }
                    final width = double.tryParse(parts[0]);
                    final height = double.tryParse(parts[1]);
                    if (width == null || height == null || width <= 0 || height <= 0) {
                      return 'Please enter valid positive numbers';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final aspectRatio = aspectRatioController.text;
                  final parts = aspectRatio.split(':');
                  final width = double.parse(parts[0]);
                  final height = double.parse(parts[1]);
                  widget.settingsProvider.setVideoAspectRatio(widget.sectionKey, width / height);
                  // Force an immediate save to ensure the aspect ratio persists
                  widget.settingsProvider.forceSave();
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  // Handle infinite scrolling after the scrolling has finished
  void _handleAfterScroll() {
    // DISABLED - no more automatic scrolling
    return;
    
    /* Original code commented out to prevent any auto-jumping
    if (!_carouselScrollController.hasClients || widget.games.isEmpty) return;
    
    final position = _carouselScrollController.position;
    final numItemsToShow = widget.settingsProvider.carouselItemCount[widget.sectionKey] ?? 
        SettingsProvider.defaultCarouselItemCount;
    
    // Calculate item width and spacing
    final safeWidth = widget.width.isFinite ? widget.width : 300.0;
    const spacing = 10.0;
    final displayItemWidth = (safeWidth - (spacing * (numItemsToShow + 1))) / numItemsToShow;
    final itemTotalWidth = displayItemWidth + spacing;
    
    // Calculate the number of duplicated items (same value as in _buildCarouselView)
    final int numDuplicatesNeeded = (numItemsToShow * 3).round();
    final numDuplicatedItems = widget.games.length > 1 ? 
        math.min(numDuplicatesNeeded, widget.games.length * 3) : 0;
    
    // Calculate the transition points
    final realItemsWidth = widget.games.length * itemTotalWidth;
    final realItemsStartOffset = numDuplicatedItems * itemTotalWidth;
    final realItemsEndOffset = realItemsStartOffset + realItemsWidth;
    
    // Find the center of the viewport in the scroll space
    final visibleCenter = position.pixels + (safeWidth / 2);
    
    // Determine which item is at the center
    int visibleItemIndex;
    
    // If we're in the duplicated items at the start
    if (visibleCenter < realItemsStartOffset) {
      final distanceFromStart = realItemsStartOffset - visibleCenter;
      final itemsFromStart = (distanceFromStart / itemTotalWidth).floor();
      visibleItemIndex = (widget.games.length - (itemsFromStart % widget.games.length)) % widget.games.length;
      
      // Only update the selected index
    }
    // If we're in the duplicated items at the end
    else if (visibleCenter >= realItemsEndOffset) {
      final distanceFromEnd = visibleCenter - realItemsEndOffset;
      final itemsFromEnd = (distanceFromEnd / itemTotalWidth).floor();
      visibleItemIndex = itemsFromEnd % widget.games.length;
      
      // Only update the selected index
    }
    // If we're in the real items
    else {
      final distanceFromRealStart = visibleCenter - realItemsStartOffset;
      visibleItemIndex = (distanceFromRealStart / itemTotalWidth).floor() % widget.games.length;
    }
    
    // Update the selected index if needed
    if (visibleItemIndex != widget.selectedIndex && widget.onGameSelected != null) {
      widget.onGameSelected!(visibleItemIndex);
    }
    */
  }

  // Left arrow button handler
  void _onLeftArrowPressed() {
    if (widget.games.isEmpty) return;
    
    // Disable current item selection
    _previousSelectedIndex = widget.selectedIndex;
    
    // Update the selected index with wraparound
    int newIndex;
    if (widget.selectedIndex > 0) {
      newIndex = widget.selectedIndex - 1;
    } else {
      newIndex = widget.games.length - 1;
    }
    
    // Notify parent
    if (widget.onGameSelected != null) {
      widget.onGameSelected!(newIndex);
    }
  }
  
  // Right arrow button handler  
  void _onRightArrowPressed() {
    if (widget.games.isEmpty) return;
    
    // Disable current item selection
    _previousSelectedIndex = widget.selectedIndex;
    
    // Update the selected index with wraparound
    int newIndex;
    if (widget.selectedIndex < widget.games.length - 1) {
      newIndex = widget.selectedIndex + 1;
    } else {
      newIndex = 0;
    }
    
    // Notify parent
    if (widget.onGameSelected != null) {
      widget.onGameSelected!(newIndex);
    }
  }

  // Helper method to build a static image view
  Widget _buildStaticImageView(double effectiveHeight, double effectiveWidth, String? staticImagePath) {
    if (staticImagePath == null) {
      return Center(
        child: Container(
          color: widget.backgroundColor,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                size: 64,
                color: Colors.white,
              ),
              SizedBox(height: 12),
              Text(
                'No static image selected',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    final file = File(staticImagePath);
    final exists = file.existsSync();
    
    if (!exists) {
      return Center(
        child: Container(
          color: widget.backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.broken_image,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'Image not found',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                staticImagePath,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    try {
      return Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          width: effectiveWidth,
          height: effectiveHeight,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Container(
                color: widget.backgroundColor,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Error loading image',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Center(
        child: Container(
          color: widget.backgroundColor,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'Exception loading image',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }
  }

  // Helper method to build a game cover item
  Widget _buildGameCover(GameConfig game, double height, double width, bool isSelected) {
    String mediaPath = _getMediaPath(game, widget.mediaType);
    // Skip file existence check for story
    if (!File(mediaPath).existsSync() && widget.mediaType != 'story') {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        color: widget.backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getMediaTypeIcon(),
              size: math.min(64, height * 0.3),
              color: Colors.white,
            ),
            SizedBox(height: math.min(12, height * 0.05)),
            Text(
              'N/A',
              style: TextStyle(
                color: Colors.white,
                fontSize: math.min(28, height * 0.1),
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: math.min(12, height * 0.05)),
            Flexible(
              child: Text(
                'No ${widget.mediaType.replaceAll('_', ' ')} available',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: math.min(14, height * 0.06),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      );
    }

    switch (widget.mediaType) {
      case 'story':
        return Container(
          width: width,
          height: height,
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
          width: width,
          height: height,
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
                width: width,
                height: width,
                child: ClipOval(
                  child: SpinningDisc(
                    imagePath: mediaPath,
                    size: width,
                  ),
                ),
              ),
              // Bottom padding space
              const SizedBox(height: 16),
            ],
          ),
        );
      default:
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          child: Image.file(
            File(mediaPath),
            fit: BoxFit.contain,
          ),
        );
    }
  }
}


