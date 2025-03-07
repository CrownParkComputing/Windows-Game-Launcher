import 'dart:io';
import 'package:flutter/material.dart';
import '../settings_provider.dart';
import 'game_carousel.dart';
import 'package:file_picker/file_picker.dart';

class ResizableSection extends StatefulWidget {
  final double width;
  final double height;
  final String mediaType;
  final bool isVertical;
  final Function(double) onResize;
  final VoidCallback? onResizeEnd;
  final String sectionKey;
  final bool isEditMode;
  final SettingsProvider settingsProvider;
  final int selectedGameIndex;
  final Function(int) onGameSelected;

  const ResizableSection({
    Key? key,
    required this.width,
    required this.height,
    required this.mediaType,
    required this.isVertical,
    required this.onResize,
    required this.sectionKey,
    required this.isEditMode,
    required this.settingsProvider,
    required this.selectedGameIndex,
    required this.onGameSelected,
    this.onResizeEnd,
  }) : super(key: key);

  @override
  State<ResizableSection> createState() => _ResizableSectionState();
}

class _ResizableSectionState extends State<ResizableSection> {
  // Add a local state variable to track the current media type
  late String _currentMediaType;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the local media type from the widget
    _currentMediaType = widget.mediaType;
    
    // Make sure this section has all needed settings initialized
    _ensureSectionConsistency();
    
    // Register a listener for game selection changes
    widget.settingsProvider.addListener(_updateMediaContent);
  }
  
  @override
  void didUpdateWidget(ResizableSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local media type if the widget's media type changed
    if (oldWidget.mediaType != widget.mediaType) {
      setState(() {
        _currentMediaType = widget.mediaType;
      });
    }
  }

  // This method ensures all section settings are consistent and correctly initialized
  void _ensureSectionConsistency() {
    debugPrint('Ensuring consistency for section: ${widget.sectionKey}');
    
    // 1. Make sure carousel mode is initialized for this section
    if (widget.settingsProvider.isCarouselMap[widget.sectionKey] == null) {
      // Set default to true if missing
      final Map<String, bool> updatedMap = Map.from(widget.settingsProvider.isCarouselMap);
      updatedMap[widget.sectionKey] = true;
      widget.settingsProvider.saveLayoutPreferences(isCarouselMap: updatedMap);
      debugPrint('Initialized carousel mode for ${widget.sectionKey} to true');
    }
    
    // 2. Make sure carousel item count is set
    if (widget.settingsProvider.carouselItemCount[widget.sectionKey] == null) {
      final Map<String, int> updatedMap = Map.from(widget.settingsProvider.carouselItemCount);
      updatedMap[widget.sectionKey] = SettingsProvider.defaultCarouselItemCount;
      widget.settingsProvider.saveLayoutPreferences(carouselItemCount: updatedMap);
      debugPrint('Initialized carousel item count for ${widget.sectionKey} to ${SettingsProvider.defaultCarouselItemCount}');
    }
    
    // 3. Get and validate the current media type for this section
    final String effectiveMediaType = _getSectionMediaType();
    debugPrint('Current media type from provider: $effectiveMediaType');
    
    // 4. Make sure the local state matches the provider
    if (_currentMediaType != effectiveMediaType) {
      debugPrint('Correcting local media type in ${widget.sectionKey} from $_currentMediaType to $effectiveMediaType');
      setState(() {
        _currentMediaType = effectiveMediaType;
      });
    }
    
    // 5. Ensure media type is valid
    if (!SettingsProvider.validLayoutMedia.contains(_currentMediaType) && _currentMediaType != 'static_image') {
      debugPrint('WARNING: Invalid media type ${_currentMediaType}, resetting to default logo');
      _updateSectionMediaType('logo');
    }
    
    // 6. For static_image, validate path exists but don't change media type
    if (_currentMediaType == 'static_image') {
      final String? staticImagePath = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
      debugPrint('Static image path: $staticImagePath');
      
      if (staticImagePath != null && staticImagePath.isNotEmpty) {
        // Check if the file exists
        final file = File(staticImagePath);
        final bool exists = file.existsSync();
        debugPrint('Static image exists: $exists');
        
        if (!exists) {
          // Log the issue but don't change automatically
          debugPrint('WARNING: Static image does not exist: $staticImagePath');
        }
      } else {
        debugPrint('WARNING: Static image path is null or empty for section ${widget.sectionKey}');
        // If the user explicitly selected static_image but there's no path, we should not
        // automatically reset it - they may want to add an image later
      }
    }
    
    // 7. Debug log current settings
    debugPrint('Section ${widget.sectionKey} settings:');
    debugPrint('- Media type: $_currentMediaType');
    debugPrint('- Carousel mode: ${widget.settingsProvider.isCarouselMap[widget.sectionKey]}');
    debugPrint('- Item count: ${widget.settingsProvider.carouselItemCount[widget.sectionKey]}');
    
    // 8. Force save to ensure all settings are persisted
    widget.settingsProvider.forceSave();
    debugPrint('Forcing save of all settings');
    
    // 9. Delay a tiny bit and force a rebuild to ensure UI reflects the latest settings
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          // This will force the section to rebuild with correct settings
          debugPrint('Forcing final consistency rebuild for section ${widget.sectionKey}');
        });
      }
    });
  }

  void _debugPrintMediaInfo() {
    // Removed print statements
  }

  void _updateSectionMediaType(String mediaType) {
    // If the media type hasn't changed, don't do anything
    if (_currentMediaType == mediaType) return;
    
    debugPrint('Changing media type in section ${widget.sectionKey} from $_currentMediaType to $mediaType');
    
    // If switching FROM static_image TO another type, clear the static image path
    if (_currentMediaType == 'static_image' && mediaType != 'static_image') {
      debugPrint('Clearing static image path for ${widget.sectionKey} since switching to non-static media type');
      widget.settingsProvider.clearStaticImagePath(widget.sectionKey);
    }
    
    // Update the local state variable
    setState(() {
      _currentMediaType = mediaType;
    });
    
    // Update the settings provider based on section key
    switch (widget.sectionKey) {
      case 'left':
        // Only use saveLayoutPreferences
        widget.settingsProvider.saveLayoutPreferences(selectedLeftImage: mediaType);
        break;
      case 'right':
        // Only use saveLayoutPreferences
        widget.settingsProvider.saveLayoutPreferences(selectedRightImage: mediaType);
        break;
      case 'top':
        // Only use saveLayoutPreferences
        widget.settingsProvider.saveLayoutPreferences(selectedTopImage: mediaType);
        break;
      case 'bottom':
        // Only use saveLayoutPreferences
        widget.settingsProvider.saveLayoutPreferences(selectedBottomImage: mediaType);
        break;
      case 'main':
        // Only use saveLayoutPreferences
        widget.settingsProvider.saveLayoutPreferences(selectedMainImage: mediaType);
        break;
      case 'top_left':
        // Only use saveLayoutPreferences
        widget.settingsProvider.saveLayoutPreferences(selectedTopLeftImage: mediaType);
        break;
      case 'top_center':
        // Only use saveLayoutPreferences
        widget.settingsProvider.saveLayoutPreferences(selectedTopCenterImage: mediaType);
        break;
      case 'top_right':
        // Only use saveLayoutPreferences
        widget.settingsProvider.saveLayoutPreferences(selectedTopRightImage: mediaType);
        break;
      default:
        debugPrint('WARNING: Unknown section key ${widget.sectionKey} - media type change may not persist!');
        break;
    }
    
    // Force an immediate save to ensure the changes are persisted
    widget.settingsProvider.forceSave();
    
    // Log the current state after the change
    debugPrint('After update: Section ${widget.sectionKey} media type is now ${_currentMediaType}');
    debugPrint('Settings provider value for ${widget.sectionKey}: ${_getSectionMediaType()}');
    
    // Force a more substantial rebuild after a short delay to ensure all UI updates
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          // Force a rebuild with the new media type
          debugPrint('Forcing full rebuild of section ${widget.sectionKey} with media type $mediaType');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width > 0 ? widget.width : 0,
      height: widget.height > 0 ? widget.height : 0,
      decoration: BoxDecoration(
        color: Colors.black38,
        border: Border(
          left: BorderSide(color: Colors.grey[850]!, width: 1),
          right: BorderSide(color: Colors.grey[850]!, width: 1),
          top: BorderSide(color: Colors.grey[850]!, width: 1),
          bottom: BorderSide(color: Colors.grey[850]!, width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: SizedBox(
              width: widget.width > 0 ? widget.width : 0,
              height: widget.height > 0 ? widget.height : 0,
              child: _buildGameContent(),
            ),
          ),

          // Dividers for resizing
          if (widget.isEditMode && _shouldShowRightDivider())
            _buildRightDivider(),
            
          if (widget.isEditMode && _shouldShowLeftDivider())
            _buildLeftDivider(),
            
          if (widget.isEditMode && _shouldShowTopDivider())
            _buildTopDivider(),
            
          if (widget.isEditMode && _shouldShowBottomDivider())
            _buildBottomDivider(),
            
          if (widget.isEditMode && widget.sectionKey == 'artwork_3d')
            _buildArtwork3dRightDivider(),
            
          if (widget.isEditMode && widget.sectionKey == 'fanart')
            _buildFanartRightDivider(),

          // Edit mode controls
          if (widget.isEditMode)
            _buildEditModeControls(),
        ],
      ),
    );
  }

  Widget _buildGameContent() {
    final selectedGameIndex = widget.settingsProvider.getSelectedGameIndex(widget.sectionKey);
    final isCarousel = widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? true;
    final alignment = widget.settingsProvider.getAlignmentForSection(widget.sectionKey);
    final backgroundColor = widget.settingsProvider.getBackgroundColorForSection(widget.sectionKey);
    
    // Create a unique key that incorporates ALL factors that should trigger a rebuild:
    // 1. The section identifier
    // 2. The current media type - crucial for widget type changes!
    // 3. Static image path (if applicable)
    // 4. Whether it's in carousel mode
    // 5. The selected game index
    // 6. A unique timestamp to ensure complete rebuild when needed
    
    // Start with section and media type - most critical for widget type changes
    String keyString = 'carousel_${widget.sectionKey}_${_currentMediaType}';
    
    // Add additional elements to the key
    if (_currentMediaType == 'static_image') {
      // For static images, include the path in the key
      final String? path = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
      if (path != null && path.isNotEmpty) {
        // Use just the filename to keep key manageable
        final filename = path.split(Platform.pathSeparator).last;
        keyString += '_$filename';
      } else {
        keyString += '_nopath';
      }
    }
    
    // Add selected game index to ensure selection changes trigger rebuilds
    keyString += '_$selectedGameIndex';
    
    // Add carousel mode state - crucial for layout changes
    keyString += '_${isCarousel ? 'carousel' : 'static'}';
    
    // Add current time to force rebuilds when needed
    keyString += '_${DateTime.now().millisecondsSinceEpoch}';
    
    debugPrint('Building game content with key: $keyString');
    
    return GameCarousel(
      key: ValueKey(keyString),
      games: widget.settingsProvider.games,
      mediaType: _currentMediaType,
      width: widget.width,
      height: widget.height,
      isCarousel: isCarousel,
      alignment: alignment,
      backgroundColor: backgroundColor,
      selectedIndex: selectedGameIndex,
      onGameSelected: (index) {
        // Update the selected game index and call the parent's handler if it exists
        debugPrint('ResizableSection received game selection: section=${widget.sectionKey}, index=$index');
        
        // Update ALL sections with the new selection to keep them in sync
        widget.settingsProvider.setSelectedGameIndex('top_left', index);
        widget.settingsProvider.setSelectedGameIndex('top_center', index);
        widget.settingsProvider.setSelectedGameIndex('top_right', index);
        widget.settingsProvider.setSelectedGameIndex('left', index);
        widget.settingsProvider.setSelectedGameIndex('right', index);
        widget.settingsProvider.setSelectedGameIndex('bottom', index);
        widget.settingsProvider.setSelectedGameIndex('main', index);
        
        if (widget.onGameSelected != null) {
          debugPrint('Calling parent onGameSelected with index=$index');
          widget.onGameSelected!(index);
        }
        
        // Force a rebuild to ensure the UI updates
        setState(() {
          debugPrint('Forcing ResizableSection rebuild for section ${widget.sectionKey}');
        });
      },
      isEditMode: widget.isEditMode,
      settingsProvider: widget.settingsProvider,
      sectionKey: widget.sectionKey,
    );
  }

  bool _shouldShowRightDivider() {
    return widget.sectionKey == 'top_left' || widget.sectionKey == 'left';
  }
  
  bool _shouldShowLeftDivider() {
    return widget.sectionKey == 'fanart';
  }
  
  bool _shouldShowTopDivider() {
    return widget.sectionKey == 'bottom';
  }
  
  bool _shouldShowBottomDivider() {
    return widget.sectionKey == 'top_center';
  }
  
  bool _shouldShowMiddleDivider() {
    return widget.sectionKey == 'artwork_3d';
  }
  
  Widget _buildRightDivider() {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 10,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            // Positive delta means drag to the right, should expand the width
            widget.onResize(details.delta.dx);
          },
          onPanEnd: (_) {
            if (widget.onResizeEnd != null) {
              widget.onResizeEnd!();
            }
          },
          child: Container(
            color: Colors.red,
            child: const Center(
              child: Icon(
                Icons.keyboard_arrow_right,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLeftDivider() {
    return Positioned(
      top: 0,
      left: 0,
      bottom: 0,
      width: 10,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            // Negative here because dragging left should shrink the width
            widget.onResize(-details.delta.dx);
          },
          onPanEnd: (_) {
            if (widget.onResizeEnd != null) {
              widget.onResizeEnd!();
            }
          },
          child: Container(
            color: Colors.red,
            child: const Center(
              child: Icon(
                Icons.keyboard_arrow_left,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildMiddleDivider() {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 10,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            // Positive delta means drag to the right, should expand the width
            widget.onResize(details.delta.dx);
          },
          onPanEnd: (_) {
            if (widget.onResizeEnd != null) {
              widget.onResizeEnd!();
            }
          },
          child: Container(
            color: Colors.purple, // Changed color to distinguish from other dividers
            child: const Center(
              child: Icon(
                Icons.keyboard_arrow_right,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTopDivider() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 10,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            // Negative because dragging up should shrink the height
            widget.onResize(-details.delta.dy);
          },
          onPanEnd: (_) {
            if (widget.onResizeEnd != null) {
              widget.onResizeEnd!();
            }
          },
          child: Container(
            color: Colors.red,
            child: const Center(
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBottomDivider() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 10,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeRow,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            // Positive because dragging down should expand the height
            widget.onResize(details.delta.dy);
          },
          onPanEnd: (_) {
            if (widget.onResizeEnd != null) {
              widget.onResizeEnd!();
            }
          },
          child: Container(
            color: Colors.red,
            child: const Center(
              child: Icon(
                Icons.keyboard_arrow_up,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFanartRightDivider() {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 10,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            // Positive delta means drag to the right, should expand the width
            widget.onResize(details.delta.dx);
          },
          onPanEnd: (_) {
            if (widget.onResizeEnd != null) {
              widget.onResizeEnd!();
            }
          },
          child: Container(
            color: Colors.red,
            child: const Center(
              child: Icon(
                Icons.keyboard_arrow_right,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtwork3dRightDivider() {
    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 10,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) {
            // Positive delta means drag to the right, should expand the width
            widget.onResize(details.delta.dx);
          },
          onPanEnd: (_) {
            if (widget.onResizeEnd != null) {
              widget.onResizeEnd!();
            }
          },
          child: Container(
            color: Colors.green, // Different color to distinguish it
            child: const Center(
              child: Icon(
                Icons.keyboard_arrow_right,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditModeControls() {
    return Positioned(
      top: 5,
      right: 5,
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
            // Media type selector
            DropdownButton<String>(
              value: _currentMediaType, // Use the local state variable instead of widget.mediaType
              dropdownColor: Colors.black87,
              isDense: true,
              underline: const SizedBox(),
              items: [
                ...SettingsProvider.validLayoutMedia.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.replaceAll('_', ' ').toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )),
              ],
              onChanged: (value) async {
                if (value != null) {
                  debugPrint('Dropdown selection changed to: $value for section ${widget.sectionKey}');
                  
                  // Special handling for static_image which requires a file path
                  if (value == 'static_image') {
                    final imagePath = await _promptForImagePath(context);
                    if (imagePath == null) {
                      // If the user cancels the file picker, revert to the previous media type
                      debugPrint('File picker cancelled, reverting to ${_currentMediaType}');
                      setState(() {
                        // No change, keep current media type
                      });
                      return;
                    }
                    // _promptForImagePath handles saving the path and setting the media type
                  } else {
                    // For all other media types, explicitly update the type
                    debugPrint('Updating section media type to $value');
                    
                    // Use our wrapper method which ensures everything is properly updated
                    _changeMediaType(value);
                  }
                  
                  // Force another save and UI update after a short delay
                  Future.delayed(const Duration(milliseconds: 100), () {
                    widget.settingsProvider.forceSave();
                    
                    if (mounted) {
                      setState(() {
                        debugPrint('Forcing final UI update after media type change to $value');
                      });
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Don't show carousel toggle for video type
                if (widget.mediaType != 'video')
                  IconButton(
                    icon: Icon(
                      (widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? true)
                          ? Icons.view_carousel
                          : Icons.image,
                      color: Colors.white,
                      size: 16,
                    ),
                    tooltip:
                        (widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? true)
                            ? 'Switch to Static Image'
                            : 'Switch to Carousel',
                    onPressed: _toggleCarouselMode,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  ),

                // Show ticker toggle if story text is available
                IconButton(
                  icon: Icon(
                    Icons.format_align_justify,
                    color: (widget.settingsProvider.showTicker[widget.sectionKey] ?? false)
                        ? Colors.blue
                        : Colors.white,
                    size: 16,
                  ),
                  tooltip: (widget.settingsProvider.showTicker[widget.sectionKey] ?? false)
                      ? 'Hide Story Ticker'
                      : 'Show Story Ticker',
                  onPressed: _toggleTicker,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),

                // Show ticker alignment options if ticker is enabled
                if (widget.settingsProvider.showTicker[widget.sectionKey] ?? false)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.vertical_align_top,
                          color: (widget.settingsProvider.tickerAlignment[widget.sectionKey] ?? 'bottom') == 'top'
                              ? Colors.blue
                              : Colors.white,
                          size: 16,
                        ),
                        tooltip: 'Align Ticker Top',
                        onPressed: () => _setTickerAlignment('top'),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.vertical_align_bottom,
                          color: (widget.settingsProvider.tickerAlignment[widget.sectionKey] ?? 'bottom') == 'bottom'
                              ? Colors.blue
                              : Colors.white,
                          size: 16,
                        ),
                        tooltip: 'Align Ticker Bottom',
                        onPressed: () => _setTickerAlignment('bottom'),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to set alignment
  void _setAlignment(String alignment) {
    Map<String, Alignment> updatedAlignmentMap =
        Map.from(widget.settingsProvider.alignmentMap);
    updatedAlignmentMap[widget.sectionKey] = SettingsProvider.getAlignmentFromString(alignment);
    _saveLayoutPreferences(alignmentMap: updatedAlignmentMap);
  }

  // Helper method to set background color
  void _setBackgroundColor(String colorKey) {
    Map<String, Color> updatedBackgroundColorMap =
        Map.from(widget.settingsProvider.backgroundColorMap);
    updatedBackgroundColorMap[widget.sectionKey] = SettingsProvider.getColorFromString(colorKey);
    _saveLayoutPreferences(backgroundColorMap: updatedBackgroundColorMap);
  }

  // Helper method to toggle carousel mode
  void _toggleCarouselMode() {
    Map<String, bool> updatedCarouselMap =
        Map.from(widget.settingsProvider.isCarouselMap);
    updatedCarouselMap[widget.sectionKey] =
        !(widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? true);
    _saveLayoutPreferences(isCarouselMap: updatedCarouselMap);
  }

  // Helper method to toggle ticker
  void _toggleTicker() {
    Map<String, bool> updatedShowTicker =
        Map.from(widget.settingsProvider.showTicker);
    updatedShowTicker[widget.sectionKey] =
        !(widget.settingsProvider.showTicker[widget.sectionKey] ?? false);
    _saveLayoutPreferences(showTicker: updatedShowTicker);
  }

  // Helper method to set ticker alignment
  void _setTickerAlignment(String alignment) {
    Map<String, String> updatedTickerAlignment =
        Map.from(widget.settingsProvider.tickerAlignment);
    updatedTickerAlignment[widget.sectionKey] = alignment;
    _saveLayoutPreferences(tickerAlignment: updatedTickerAlignment);
  }

  // Helper method to save layout preferences with optional parameters
  void _saveLayoutPreferences({
    Map<String, Alignment>? alignmentMap,
    Map<String, Color>? backgroundColorMap,
    Map<String, bool>? isCarouselMap,
    Map<String, bool>? showTicker,
    Map<String, String>? tickerAlignment,
    Map<String, int>? carouselItemCount,
    String? selectedLeftImage,
    String? selectedRightImage,
    String? selectedTopImage,
    String? selectedBottomImage,
    String? selectedMainImage,
  }) {
    widget.settingsProvider.saveLayoutPreferences(
      leftMarginWidth: widget.settingsProvider.leftMarginWidth,
      rightMarginWidth: widget.settingsProvider.rightMarginWidth,
      topMarginHeight: widget.settingsProvider.topMarginHeight,
      bottomMarginHeight: widget.settingsProvider.bottomMarginHeight,
      selectedLeftImage:
          selectedLeftImage ?? widget.settingsProvider.selectedLeftImage,
      selectedRightImage:
          selectedRightImage ?? widget.settingsProvider.selectedRightImage,
      selectedTopImage: selectedTopImage ?? widget.settingsProvider.selectedTopImage,
      selectedBottomImage:
          selectedBottomImage ?? widget.settingsProvider.selectedBottomImage,
      selectedMainImage:
          selectedMainImage ?? widget.settingsProvider.selectedMainImage,
      alignmentMap: alignmentMap ?? widget.settingsProvider.alignmentMap,
      backgroundColorMap:
          backgroundColorMap ?? widget.settingsProvider.backgroundColorMap,
      isCarouselMap: isCarouselMap ?? widget.settingsProvider.isCarouselMap,
      showTicker: showTicker ?? widget.settingsProvider.showTicker,
      tickerAlignment: tickerAlignment ?? widget.settingsProvider.tickerAlignment,
      carouselItemCount: carouselItemCount ?? widget.settingsProvider.carouselItemCount,
    );
  }

  Future<String?> _promptForImagePath(BuildContext context) async {
    try {
      debugPrint('Opening file picker for static image selection in section ${widget.sectionKey}');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final String? path = result.files.first.path;
        
        if (path != null && path.isNotEmpty) {
          // Validate that the file exists
          final file = File(path);
          final bool exists = file.existsSync();
          
          if (exists) {
            debugPrint('Selected valid static image path: $path for section ${widget.sectionKey}');
            
            // First set the media type to static_image
            _updateSectionMediaType('static_image');
            
            // Then save the path
            widget.settingsProvider.setStaticImagePath(widget.sectionKey, path);
            debugPrint('Saved static image path for ${widget.sectionKey}: $path');
            
            // Force an immediate save
            widget.settingsProvider.forceSave();
            
            // Force a complete rebuild after a short delay
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                setState(() {
                  debugPrint('Completed static image setup for section ${widget.sectionKey}');
                  // Verify the current media type is static_image
                  if (_currentMediaType != 'static_image') {
                    debugPrint('WARNING: Media type not correctly set to static_image after selecting image');
                    _currentMediaType = 'static_image';
                  }
                });
              }
            });
            
            return path;
          } else {
            debugPrint('Selected file does not exist: $path');
            
            // Show error dialog
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Invalid Image'),
                  content: const Text('The selected image file does not exist.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            
            return null;
          }
        }
      }
      
      debugPrint('No image selected or selection cancelled');
      return null;
    } catch (e) {
      debugPrint('Error selecting image: $e');
      
      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to select image: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
      return null;
    }
  }

  // Helper method to get the current media type for this section
  String _getSectionMediaType() {
    String mediaType;
    
    switch (widget.sectionKey) {
      case 'left':
        mediaType = widget.settingsProvider.selectedLeftImage;
        break;
      case 'right':
        mediaType = widget.settingsProvider.selectedRightImage;
        break;
      case 'top':
        mediaType = widget.settingsProvider.selectedTopImage;
        break;
      case 'bottom':
        mediaType = widget.settingsProvider.selectedBottomImage;
        break;
      case 'main':
        mediaType = widget.settingsProvider.selectedMainImage;
        break;
      case 'top_left':
        mediaType = widget.settingsProvider.selectedTopLeftImage;
        break;
      case 'top_center':
        mediaType = widget.settingsProvider.selectedTopCenterImage;
        break;
      case 'top_right':
        mediaType = widget.settingsProvider.selectedTopRightImage;
        break;
      default:
        mediaType = 'logo';
    }
    
    // DON'T automatically switch back to static_image mode just because a path exists
    // This was causing issues with being unable to switch away from static_image
    
    // Log the media type being returned
    debugPrint('_getSectionMediaType for ${widget.sectionKey} returning: $mediaType');
    
    return mediaType;
  }

  // Update the media content when settings change
  void _updateMediaContent() {
    // Skip if widget is unmounted
    if (!mounted) return;
    
    debugPrint('MediaContent update triggered for section ${widget.sectionKey}');
    
    try {
      // Get the current media type from settings provider
      final newMediaType = _getSectionMediaType();
      
      // If media type changed, update the state
      if (newMediaType != _currentMediaType) {
        debugPrint('Media type changed externally in ${widget.sectionKey} from $_currentMediaType to $newMediaType');
        
        // If changing FROM static_image TO another type, clear the static image path
        if (_currentMediaType == 'static_image' && newMediaType != 'static_image') {
          debugPrint('Clearing static image path during media content update since type changed');
          widget.settingsProvider.clearStaticImagePath(widget.sectionKey);
        }
        
        setState(() {
          _currentMediaType = newMediaType;
        });
      }
      
      // Check if static image path changed (for static image sections)
      if (_currentMediaType == 'static_image') {
        final path = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
        debugPrint('Current static image path for ${widget.sectionKey}: $path');
        
        // Validate the path exists
        if (path == null || path.isEmpty || !File(path).existsSync()) {
          debugPrint('Static image path invalid, might need to reset media type');
        }
        
        // Rebuild anyway to ensure the image is updated
        setState(() {});
      }
      
      // Check if the selected game index has changed
      final currentSelectedIndex = widget.settingsProvider.getSelectedGameIndex(widget.sectionKey);
      if (currentSelectedIndex != widget.selectedGameIndex) {
        debugPrint('Selected game index changed in ${widget.sectionKey} from ${widget.selectedGameIndex} to $currentSelectedIndex');
        // Force a rebuild to show the new selection
        setState(() {});
      }
      
      // Check if carousel mode changed
      final isCarousel = widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? true;
      debugPrint('Carousel mode for ${widget.sectionKey}: $isCarousel');
      
      // Force update regardless to ensure all sections stay in sync
      setState(() {
        debugPrint('Forcing update in section ${widget.sectionKey} to ensure synchronization');
      });
    } catch (e) {
      debugPrint('Error in _updateMediaContent for ${widget.sectionKey}: $e');
    }
  }
  
  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    widget.settingsProvider.removeListener(_updateMediaContent);
    super.dispose();
  }

  // Helper method to safely change the media type, ensuring all paths and settings are properly updated
  void _changeMediaType(String newMediaType) {
    if (_currentMediaType == newMediaType) return;
    
    debugPrint('_changeMediaType: changing from ${_currentMediaType} to $newMediaType for ${widget.sectionKey}');
    
    // If we're switching FROM static_image TO something else, clear the path
    if (_currentMediaType == 'static_image' && newMediaType != 'static_image') {
      debugPrint('Clearing static image path because we\'re switching away from static_image');
      widget.settingsProvider.clearStaticImagePath(widget.sectionKey);
    }
    
    // Update the local state variable
    setState(() {
      _currentMediaType = newMediaType;
    });
    
    // Update the settings provider using our comprehensive update method
    _updateSectionMediaType(newMediaType);
    
    // Double-check that the media type was actually updated in the SettingsProvider
    final verifiedMediaType = _getSectionMediaType();
    debugPrint('After _updateSectionMediaType: Provider reports media type for ${widget.sectionKey} is: $verifiedMediaType');
    
    if (verifiedMediaType != newMediaType) {
      debugPrint('WARNING: Media type was not updated correctly! Trying with additional save...');
      
      // Try another save with specific parameters
      switch (widget.sectionKey) {
        case 'left':
          widget.settingsProvider.saveLayoutPreferences(selectedLeftImage: newMediaType);
          break;
        case 'right':
          widget.settingsProvider.saveLayoutPreferences(selectedRightImage: newMediaType);
          break;
        case 'top':
          widget.settingsProvider.saveLayoutPreferences(selectedTopImage: newMediaType);
          break;
        case 'bottom':
          widget.settingsProvider.saveLayoutPreferences(selectedBottomImage: newMediaType);
          break;
        case 'main':
          widget.settingsProvider.saveLayoutPreferences(selectedMainImage: newMediaType);
          break;
        case 'top_left':
          widget.settingsProvider.saveLayoutPreferences(selectedTopLeftImage: newMediaType);
          break;
        case 'top_center':
          widget.settingsProvider.saveLayoutPreferences(selectedTopCenterImage: newMediaType);
          break;
        case 'top_right':
          widget.settingsProvider.saveLayoutPreferences(selectedTopRightImage: newMediaType);
          break;
      }
      
      // Force an immediate save
      widget.settingsProvider.forceSave();
      
      // Verify again
      final secondVerification = _getSectionMediaType();
      debugPrint('After additional save: Provider reports media type for ${widget.sectionKey} is: $secondVerification');
    }
    
    // Force a UI rebuild after a short delay
    Future.microtask(() {
      if (mounted) {
        setState(() {
          debugPrint('_changeMediaType complete - new media type: ${_currentMediaType}');
          
          // Final verification
          final finalMediaType = _getSectionMediaType();
          debugPrint('Final verification - media type in provider for ${widget.sectionKey}: $finalMediaType');
        });
      }
    });
  }
}
