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
    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveWidth = constraints.maxWidth;
        final effectiveHeight = constraints.maxHeight;
        
        // Adjust height for ticker if it's enabled
        final bool showTicker = widget.settingsProvider.showTicker[widget.sectionKey] ?? false;
        final double tickerHeight = showTicker ? 30.0 : 0.0;
        final double contentHeight = effectiveHeight - tickerHeight;
        final spacing = 10.0;
        final numItemsToShow = widget.settingsProvider.carouselItemCount[widget.sectionKey] ?? SettingsProvider.defaultCarouselItemCount;
        final itemWidth = (effectiveWidth - (spacing * (numItemsToShow - 1))) / numItemsToShow;

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
                      : (shouldUseCarousel
                          ? _buildCarouselView(contentHeight, effectiveWidth)
                          : _buildStaticView(contentHeight, effectiveWidth)),
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
    
    // Check if this section is in carousel mode
    final isCarouselMode = widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? widget.isCarousel;

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
                widget.mediaType.replaceAll('_', ' ').toUpperCase(),
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
    final spacing = 10.0;
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
    final minOffset = 0.0;
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
    final spacing = 10.0;
    final displayItemWidth = (safeWidth - (spacing * (numItemsToShow + 1))) / numItemsToShow;
    
    // Use a larger percentage of available height for items, leaving room for navigation
    final itemHeight = height * 0.8; // Reduced from 0.9 to ensure there's room for navigation
    
    // Number of items to duplicate at start and end for continuous effect
    final numDuplicatedItems = widget.games.length > 1 ? 
        math.min(numItemsToShow, widget.games.length) : 0;
    
    // Calculate the total width needed for all items, including duplicates and spacing
    final totalItemsWidth = (widget.games.length + (numDuplicatedItems * 2)) * (displayItemWidth + spacing) + spacing;
    
    // Calculate the center position
    final centerPosition = (safeWidth - displayItemWidth) / 2;
    
    // Create a list with main items and duplicated items for continuous loop
    final List<Widget> allItems = [];
    
    // Add duplicated items at the start (from the end of the list)
    if (widget.games.length > 1) {
      for (var i = 0; i < numDuplicatedItems; i++) {
        final gameIndex = (widget.games.length - numDuplicatedItems + i) % widget.games.length;
        allItems.add(_buildCarouselItem(displayItemWidth, itemHeight, gameIndex, spacing));
      }
    }
    
    // Add main items
    for (var i = 0; i < widget.games.length; i++) {
      allItems.add(_buildCarouselItem(displayItemWidth, itemHeight, i, spacing));
    }
    
    // Add duplicated items at the end (from the start of the list)
    if (widget.games.length > 1) {
      for (var i = 0; i < numDuplicatedItems; i++) {
        final gameIndex = i % widget.games.length;
        allItems.add(_buildCarouselItem(displayItemWidth, itemHeight, gameIndex, spacing));
      }
    }
    
    return Container(
      height: height,
      width: safeWidth,
      child: Column(
        children: [
          // Main carousel with items
          Container(
            height: itemHeight,
            width: safeWidth,
            alignment: Alignment.center,
            child: SingleChildScrollView(
              controller: _carouselScrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: totalItemsWidth,
                height: itemHeight,
                child: Stack(
                  children: [
                    // All items including duplicates
                    Row(
                      children: [
                        SizedBox(width: spacing), // Initial spacing
                        ...allItems,
                      ],
                    ),
                    
                    // Static center highlight - position at the exact center of the viewport
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
          
          // Left and right selection indicators - use remaining space
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Left arrow
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(width: 40),
                    icon: const Icon(Icons.arrow_left, color: Colors.white, size: 32),
                    onPressed: () {
                      setState(() {
                        // Move to the previous item with wraparound
                        if (widget.selectedIndex > 0) {
                          widget.onGameSelected!(widget.selectedIndex - 1);
                        } else {
                          // Wrap around to the last item
                          widget.onGameSelected!(widget.games.length - 1);
                        }
                      });
                      _scrollToSelectedItem();
                    },
                  ),
                  
                  // Game title text
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
                  
                  // Right arrow
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints.tightFor(width: 40),
                    icon: const Icon(Icons.arrow_right, color: Colors.white, size: 32),
                    onPressed: () {
                      setState(() {
                        // Move to the next item with wraparound
                        if (widget.selectedIndex < widget.games.length - 1) {
                          widget.onGameSelected!(widget.selectedIndex + 1);
                        } else {
                          // Wrap around to the first item
                          widget.onGameSelected!(0);
                        }
                      });
                      _scrollToSelectedItem();
                    },
                  ),
                ],
              ),
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

  Widget _buildGameItem(GameConfig game, double effectiveHeight,
      double itemWidth, bool isSelected) {
    String mediaPath = _getMediaPath(game, widget.mediaType);
    if (!File(mediaPath).existsSync() && widget.mediaType != 'story') {
      return SizedBox(width: itemWidth);
    }

    // Ensure maximum height for the item
    final itemHeight = effectiveHeight;

    // Special handling for video to ensure it fills the entire space
    if (widget.mediaType == 'video') {
      return SizedBox.expand(
        child: CarouselVideoPlayer(
          videoPath: mediaPath,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }

    return Container(
      width: itemWidth,
      height: itemHeight,
      alignment: Alignment.center,
      child: _buildMediaWidget(game, mediaPath, itemWidth, itemHeight),
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
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 12),
              const Text(
                'N/A',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No ${widget.mediaType.replaceAll('_', ' ')} available',
                style: const TextStyle(
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

    switch (widget.mediaType) {
      case 'video':
        // This case is now handled directly in _buildGameItem for better size control
        return const SizedBox(); // This should never be reached
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
