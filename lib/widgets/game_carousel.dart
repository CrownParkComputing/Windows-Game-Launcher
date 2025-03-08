import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../settings_provider.dart';
import 'spinning_disc.dart';
import '../models/game_config.dart';
import 'carousel_video_player.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/logger.dart';
import '../utils/static_image_manager.dart';
import 'static_image_widget.dart';
import 'transparent_widget.dart';

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

class _GameCarouselState extends State<GameCarousel> with TickerProviderStateMixin {
  late ScrollController _tickerController;
  late AnimationController _tickerAnimationController;
  String? _storyText;
  int _previousSelectedIndex = 0;
  
  // Add animation controller for selection
  late AnimationController _selectionAnimationController;
  late Animation<double> _selectionAnimation;

  @override
  void initState() {
    super.initState();
    _tickerController = ScrollController();
    _tickerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();
    
    // Initialize selection animation controller
    _selectionAnimationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 250),
    );
    
    _selectionAnimation = CurvedAnimation(
      parent: _selectionAnimationController,
      curve: Curves.easeInOut,
    );
    
    _loadStoryText();
    _previousSelectedIndex = widget.selectedIndex;
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerAnimationController.dispose();
    _selectionAnimationController.dispose();
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
    
    // Log changes that affect game selection or media display
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      Logger.debug('SELECTION CHANGED in ${widget.sectionKey}: ${oldWidget.selectedIndex} -> ${widget.selectedIndex}', source: 'GameCarousel');
      
      _loadStoryText();
      // Reset animation when text changes
      _tickerAnimationController
        ..reset()
        ..repeat();
      
      // Play selection animation when selection changes
      _playSelectionAnimation();
      
      // Track the change in selected index for animation
      _previousSelectedIndex = oldWidget.selectedIndex;
    }
    
    if (oldWidget.mediaType != widget.mediaType) {
      Logger.debug('MEDIA TYPE CHANGED in ${widget.sectionKey}: ${oldWidget.mediaType} -> ${widget.mediaType}', source: 'GameCarousel');
      _loadStoryText(); // Also reload story text on media type change
    }
  }

  String _getMediaPath(GameConfig game, String type) {
    final mediaFolder = widget.settingsProvider.effectiveMediaFolderPath;
    
    // Special handling for static_image type
    if (type == 'static_image') {
      // Get the static image path from settings provider
      final staticPath = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
      if (staticPath != null && staticPath.isNotEmpty) {
        return staticPath;
      }
      // If no image is selected, return a path that will trigger the missing media placeholder
      return '$mediaFolder/static_images/no_image_selected';
    }
    
    // If the type is a directory that exists, use that directly
    final typeDir = Directory('$mediaFolder/$type');
    if (typeDir.existsSync()) {
      // For standard media types, use game name with appropriate extension
      return '$mediaFolder/$type/${game.name}.${_getMediaExtension(type)}';
    }
    
    // Fallback to traditional mapping for backward compatibility
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
        return '$mediaFolder/$type/${game.name}.png'; // Default to PNG for unknown types
    }
  }
  
  // Helper to get the appropriate file extension based on media type
  String _getMediaExtension(String type) {
    switch (type) {
      case 'video':
        return 'mp4';
      case 'story':
        return 'txt';
      case 'fanart':
        return 'jpg';
      default:
        return 'png'; // Default to PNG for most image types
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap everything in a RawKeyboardListener to handle keyboard navigation
    return Focus(
      autofocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _onLeftArrowPressed();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _onRightArrowPressed();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: LayoutBuilder(
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

          return Stack(
            children: [
              Container(
                width: effectiveWidth,
                height: effectiveHeight,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: widget.isEditMode ? widget.backgroundColor : Colors.transparent,
                  borderRadius: widget.isEditMode ? BorderRadius.circular(4) : null,
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
      ),
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
    String mediaTypeDisplay = widget.mediaType.replaceAll('_', ' ').toUpperCase();

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
      default:
        // Default icon for any other folder type
        return Icons.folder;
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

  Widget _buildCarouselView(double height, double width) {
    if (widget.games.isEmpty) return const SizedBox.shrink();
    
    Logger.debug('Building carousel view for section ${widget.sectionKey}: selected=${widget.selectedIndex}', source: 'GameCarousel');

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
    
    // Create list of items for just the visible games - no duplicates
    final List<Widget> visibleItems = [];
    
    // Determine which games should be visible in the carousel based on selection
    final int totalGames = widget.games.length;
    
    // Show the selected game in the center and balanced items on each side
    final int startIndex = widget.selectedIndex - (numItemsToShow ~/ 2);
    
    // Build just enough items to fill the view
    for (int i = 0; i < numItemsToShow; i++) {
      // Calculate the actual index with wrapping
      int actualIndex = (startIndex + i) % totalGames;
      if (actualIndex < 0) actualIndex += totalGames;
      
      // Add the item - wrap in AnimatedContainer for smooth transitions
      visibleItems.add(
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(
            horizontal: spacing / 2,
            vertical: actualIndex == widget.selectedIndex ? 0 : 10, // Move selected item down slightly
          ),
          child: _buildCarouselItem(
            displayItemWidth, 
            actualIndex == widget.selectedIndex ? itemHeight : itemHeight * 0.9, // Selected item is slightly larger 
            actualIndex, 
            0, // No additional spacing needed since we're using container margins
          ),
        ),
      );
    }
    
    // Add a key to the SizedBox to force rebuilds when the selected index changes
    final carouselKey = ValueKey('carousel_${widget.sectionKey}_${widget.selectedIndex}');
    
    return SizedBox(
      key: carouselKey,
      height: height,
      width: safeWidth,
      child: Column(
        children: [
          // Main carousel with items - explicit height
          SizedBox(
            height: itemHeight,
            child: Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: visibleItems,
                ),
                
                // Center highlight indicator - make it more visible but not distracting
                Positioned(
                  left: safeWidth / 2 - displayItemWidth / 2 - 5,
                  top: 0,
                  child: Container(
                    width: displayItemWidth + 10,
                    height: itemHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.15),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation section with explicit height
          SizedBox(
            height: navigationHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Left arrow button - make it more visible
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _onLeftArrowPressed,
                    child: AnimatedBuilder(
                      animation: _selectionAnimation,
                      builder: (context, child) {
                        // Apply a bounce effect when clicked
                        final scaleFactor = widget.selectedIndex < widget.games.length - 1 
                            ? 1.0 - (_selectionAnimation.value * 0.15) + (math.sin(_selectionAnimation.value * math.pi) * 0.05)
                            : 1.0;
                        return Transform.scale(
                          scale: scaleFactor,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2 + (_selectionAnimation.value * 0.3)),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Game name - center with animation
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    alignment: Alignment.center,
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: AnimatedBuilder(
                      animation: _selectionAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1.0 + (_selectionAnimation.value * 0.05),
                          child: Opacity(
                            opacity: 0.7 + (_selectionAnimation.value * 0.3),
                            child: Text(
                              widget.games[widget.selectedIndex].name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18 + (_selectionAnimation.value * 1.0),
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.blue.withOpacity(_selectionAnimation.value * 0.8),
                                    blurRadius: 8.0 * _selectionAnimation.value,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Right arrow button - make it more visible
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _onRightArrowPressed,
                    child: AnimatedBuilder(
                      animation: _selectionAnimation,
                      builder: (context, child) {
                        // Apply a bounce effect when clicked
                        final scaleFactor = widget.selectedIndex > 0 
                            ? 1.0 - (_selectionAnimation.value * 0.15) + (math.sin(_selectionAnimation.value * math.pi) * 0.05)
                            : 1.0;
                        return Transform.scale(
                          scale: scaleFactor,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2 + (_selectionAnimation.value * 0.3)),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
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
    final GameConfig game = widget.games[index];
    final bool isSelected = index == widget.selectedIndex;
    
    return GestureDetector(
      onTap: () {
        Logger.debug('Carousel item tapped: section=${widget.sectionKey}, index=$index', source: 'GameCarousel');
        if (widget.onGameSelected != null) {
          widget.onGameSelected!(index);
          
          // Play selection animation when tapped
          if (isSelected) {
            _playSelectionAnimation();
          }
        }
      },
      child: AnimatedBuilder(
        animation: _selectionAnimation,
        builder: (context, child) {
          // Only apply the glow effect to the selected item
          final glowOpacity = isSelected ? _selectionAnimation.value * 0.6 : 0.0;
          final borderWidth = isSelected ? 3.0 + (_selectionAnimation.value * 1.0) : 1.0;
          
          return Container(
            width: displayItemWidth,
            height: itemHeight,
            margin: EdgeInsets.symmetric(horizontal: spacing / 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.withOpacity(0.2) : null,
              border: Border.all(
                color: isSelected 
                  ? Colors.blue.withOpacity(0.7 + (_selectionAnimation.value * 0.3))
                  : Colors.grey.withOpacity(0.3),
                width: borderWidth,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3 + glowOpacity),
                  spreadRadius: 2 + (_selectionAnimation.value * 2),
                  blurRadius: 4 + (_selectionAnimation.value * 4),
                  offset: const Offset(0, 0),
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                // Main content
                _buildGameItem(game, itemHeight, displayItemWidth, isSelected),
                
                // Selected indicator
                if (isSelected)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7 + (_selectionAnimation.value * 0.3)),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3 + glowOpacity),
                            spreadRadius: 1,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14 + (_selectionAnimation.value * 2),
                      ),
                    ),
                  ),
              ],
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
    final selectedGame = widget.games[effectiveIndex];
    
    // Always use full width for video to maximize display area
    final useFullWidth = widget.mediaType == 'video';
    final effectiveWidth = useFullWidth ? double.infinity : itemWidth;

    return Center(
      child: Container(
        width: effectiveWidth,
        height: effectiveHeight,
        alignment: Alignment.center,
        // No background color specified - will be transparent
        child: _buildGameItem(
            selectedGame, effectiveHeight, effectiveWidth, true),
      ),
    );
  }

  // Centralized method to check if media exists for a game
  bool _doesMediaExist(GameConfig game, String mediaType) {
    if (mediaType == 'story') return true; // Story is handled differently
    
    final String path = _getMediaPath(game, mediaType);
    final bool exists = File(path).existsSync();
    
    // Log media status for debugging
    Logger.debug('MEDIA CHECK: Game=${game.name}, Type=$mediaType, Section=${widget.sectionKey}, Path=$path, Exists=$exists', source: 'GameCarousel');
    
    return exists;
  }

  // Helper to build the game item with consistency for all sections
  Widget _buildGameItem(GameConfig game, double height, double width, bool isSelected) {
    // Handle special widget types
    if (widget.mediaType == SettingsProvider.staticImageWidgetType) {
      return StaticImageWidget(
        width: width,
        height: height,
        sectionKey: widget.sectionKey,
        isEditMode: widget.isEditMode,
        settingsProvider: widget.settingsProvider,
      );
    }
    
    if (widget.mediaType == SettingsProvider.transparentWidgetType) {
      return TransparentWidget(
        width: width,
        height: height,
        isEditMode: widget.isEditMode,
        settingsProvider: widget.settingsProvider,
      );
    }
    
    // Special handling for static_image type
    if (widget.mediaType == 'static_image') {
      return _buildStaticImageItem(height, width);
    }
    
    // First check if media exists (consistent check for all types)
    final bool mediaExists = _doesMediaExist(game, widget.mediaType);
    
    // If media doesn't exist, show the missing media placeholder
    if (!mediaExists) {
      return _buildMissingMediaPlaceholder(game, height, width);
    }
    
    // Handle specific media types
    switch (widget.mediaType) {
      case 'video':
        if (mediaExists) {
          return _buildVideoItem(game, height, width);
        } else {
          return _buildMissingMediaPlaceholder(game, height, width);
        }
        
      case 'medium_disc':
        return _buildGameCover(game, height, width, isSelected);
        
      default:
        // For all other media types (logo, artwork_front, etc)
        if (mediaExists) {
          final String mediaPath = _getMediaPath(game, widget.mediaType);
          return Container(
            width: width,
            height: height,
            alignment: Alignment.center,
            child: Image.file(
              File(mediaPath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder(game, height, width);
              },
            ),
          );
        } else {
          return _buildMissingMediaPlaceholder(game, height, width);
        }
    }
  }

  // Helper method for building video items
  Widget _buildVideoItem(GameConfig game, double height, double width) {
    // Get the video path
    final String videoPath = _getMediaPath(game, 'video');
    
    // Get or use default aspect ratio
    final aspectRatio = widget.settingsProvider.getVideoAspectRatio(widget.sectionKey) ?? 16/9;
    
    // Calculate dimensions to fill the space while maintaining aspect ratio
    double videoWidth = width;
    double videoHeight = videoWidth / aspectRatio;
    
    if (videoHeight > height) {
      videoHeight = height;
      videoWidth = videoHeight * aspectRatio;
    }
    
    return _buildCarouselVideoPlayer(game, videoWidth, videoHeight, true);
  }
  
  // Helper method for errors loading images
  Widget _buildErrorPlaceholder(GameConfig game, double height, double width) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 36,
            color: Colors.red.withOpacity(0.8),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              game.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Error loading ${widget.mediaType.replaceAll('_', ' ')}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.withOpacity(0.7),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
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
              // No background color or shadow in regular mode
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CarouselVideoPlayer(
                    videoPath: game.videoPath,
                    width: videoWidth,
                    height: videoHeight,
                  ),
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

  // Left arrow button handler
  void _onLeftArrowPressed() {
    if (widget.games.isEmpty) return;
    
    Logger.debug('Left arrow pressed in ${widget.sectionKey} carousel', source: 'GameCarousel');
    
    // Update the selected index with wraparound
    int newIndex;
    if (widget.selectedIndex > 0) {
      newIndex = widget.selectedIndex - 1;
    } else {
      newIndex = widget.games.length - 1;
    }
    
    Logger.debug('Changing selection from ${widget.selectedIndex} to $newIndex', source: 'GameCarousel');
    
    // Play selection animation
    _playSelectionAnimation();
    
    // Notify parent
    if (widget.onGameSelected != null) {
      widget.onGameSelected!(newIndex);
      
      // Trigger the rebuild directly
      Future.microtask(() {
        if (mounted) {
          setState(() {
            // This empty setState forces a rebuild
            Logger.debug('Forcing rebuild after left arrow press', source: 'GameCarousel');
          });
        }
      });
    }
  }
  
  // Right arrow button handler  
  void _onRightArrowPressed() {
    if (widget.games.isEmpty) return;
    
    Logger.debug('Right arrow pressed in ${widget.sectionKey} carousel', source: 'GameCarousel');
    
    // Update the selected index with wraparound
    int newIndex;
    if (widget.selectedIndex < widget.games.length - 1) {
      newIndex = widget.selectedIndex + 1;
    } else {
      newIndex = 0;
    }
    
    Logger.debug('Changing selection from ${widget.selectedIndex} to $newIndex', source: 'GameCarousel');
    
    // Play selection animation
    _playSelectionAnimation();
    
    // Notify parent
    if (widget.onGameSelected != null) {
      widget.onGameSelected!(newIndex);
      
      // Trigger the rebuild directly
      Future.microtask(() {
        if (mounted) {
          setState(() {
            // This empty setState forces a rebuild
            Logger.debug('Forcing rebuild after right arrow press', source: 'GameCarousel');
          });
        }
      });
    }
  }

  // Play the selection animation
  void _playSelectionAnimation() {
    _selectionAnimationController.reset();
    _selectionAnimationController.forward();
  }

  // Helper method to build a game cover item
  Widget _buildGameCover(GameConfig game, double height, double width, bool isSelected) {
    String mediaPath = _getMediaPath(game, widget.mediaType);
    
    // Debug output to help diagnose issues
    Logger.debug('Building cover for game: ${game.name}, media type: ${widget.mediaType}, section: ${widget.sectionKey}, path exists: ${File(mediaPath).existsSync()}', source: 'GameCarousel');
    
    // Skip file existence check for story
    if (!File(mediaPath).existsSync() && widget.mediaType != 'story') {
      Logger.debug('Showing N/A for ${game.name} in section ${widget.sectionKey} with media type ${widget.mediaType}', source: 'GameCarousel');
      return _buildMissingMediaPlaceholder(game, height, width);
    }

    switch (widget.mediaType) {
      case 'story':
        return Container(
          width: width,
          height: height,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black87, // Keep this background to ensure text is readable
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: SingleChildScrollView(
            child: Text(
              widget.settingsProvider.extractStoryText(game.storyText),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        );
        
      case 'video':
        // For video, use a transparent background and let the video player handle the display
        return _buildVideoItem(game, height, width);
        
      default:
        // For images, ensure they have a proper background for visibility
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isSelected ? Colors.black45 : Colors.black38, // Light background for images
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.file(
              File(mediaPath),
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                Logger.debug('Error loading image for ${game.name}: $error', source: 'GameCarousel');
                return _buildErrorPlaceholder(game, height, width);
              },
            ),
          ),
        );
    }
  }

  // Helper method to build placeholder for missing media
  Widget _buildMissingMediaPlaceholder(GameConfig game, double height, double width) {
    Logger.debug('Building missing media placeholder for ${game.name} in ${widget.sectionKey}', source: 'GameCarousel');
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black54, // Keep a background for the placeholder
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getMediaTypeIcon(),
            size: 36,
            color: Colors.white.withOpacity(0.7),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              game.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No ${widget.mediaType.replaceAll('_', ' ')} available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // New method to build a static image item
  Widget _buildStaticImageItem(double height, double width) {
    final GameConfig dummyGame = GameConfig(
      name: '',
      executablePath: '',
      logoPath: '',
      videoPath: '',
      storyText: '',
      bannerPath: '',
    );
    
    final String staticImagePath = _getMediaPath(
      widget.games.isNotEmpty ? widget.games[0] : dummyGame, 
      'static_image'
    );
    
    final bool imageExists = File(staticImagePath).existsSync();
    
    if (imageExists) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        // No background color specified - will be transparent
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(staticImagePath),
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return _buildStaticImageErrorPlaceholder(height, width);
            },
          ),
        ),
      );
    } else {
      return _buildStaticImageMissingPlaceholder(height, width);
    }
  }
  
  // Placeholder for missing static images
  Widget _buildStaticImageMissingPlaceholder(double height, double width) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black54, // Keep a background for the placeholder to be visible
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 64,
            color: Colors.white70,
          ),
          SizedBox(height: 16),
          Text(
            'No static image selected',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _selectStaticImage(),
            child: Text('Select Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Placeholder for static image loading errors
  Widget _buildStaticImageErrorPlaceholder(double height, double width) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black54, // Keep a background for the error placeholder to be visible
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.red,
          ),
          SizedBox(height: 16),
          Text(
            'Error loading static image',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _selectStaticImage(),
            child: Text('Select New Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  // Method to prompt user to select a static image
  Future<void> _selectStaticImage() async {
    try {
      Logger.info('Opening file picker to select static image for section ${widget.sectionKey}', source: 'GameCarousel');
      
      // Use our StaticImageManager to handle image selection
      final staticImageManager = StaticImageManager();
      final path = await staticImageManager.pickStaticImage(widget.settingsProvider, widget.sectionKey);
      
      if (path != null) {
        // Force a rebuild to show the new image
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      Logger.error('Error selecting static image: $e', source: 'GameCarousel');
    }
  }
}


