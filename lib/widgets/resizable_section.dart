import 'dart:io';
import 'package:flutter/material.dart';
import '../settings_provider.dart';
import 'game_carousel.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/video_manager.dart';
import '../utils/logger.dart';
import '../utils/static_image_manager.dart';

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
  late bool _isChangingMediaType;
  List<String> _availableMediaFolders = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize the local media type from the widget
    _currentMediaType = widget.mediaType;
    
    // Initialize loading state
    _isChangingMediaType = false;
    
    // Load available media folders
    _loadAvailableMediaFolders();
    
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

  // Load available media folders from medium_artwork directory
  void _loadAvailableMediaFolders() {
    try {
      final baseDir = Directory('${Directory.current.path}/medium_artwork');
      
      // Create the base directory if it doesn't exist
      if (!baseDir.existsSync()) {
        baseDir.createSync(recursive: true);
        Logger.info('Created base medium_artwork directory', source: 'ResizableSection');
      }
      
      if (baseDir.existsSync()) {
        // Get only actual directories from the medium_artwork folder
        final dirs = baseDir.listSync()
          .where((entity) => entity is Directory)
          .map((dir) => dir.path.split(Platform.pathSeparator).last)
          .toList();
        
        setState(() {
          _availableMediaFolders = dirs;
          Logger.debug('Available media folders: $_availableMediaFolders', source: 'ResizableSection');
        });
      } else {
        Logger.warning('Medium artwork directory not found at ${baseDir.path}', source: 'ResizableSection');
      }
    } catch (e) {
      Logger.error('Error loading media folders: $e', source: 'ResizableSection');
      // Fallback to default media types
      setState(() {
        _availableMediaFolders = SettingsProvider.validLayoutMedia;
      });
    }
  }

  // This method ensures all section settings are consistent and correctly initialized
  void _ensureSectionConsistency() {
    Logger.debug('Ensuring consistency for section: ${widget.sectionKey}', source: 'ResizableSection');
    
    // 1. Make sure carousel mode is initialized for this section
    if (widget.settingsProvider.isCarouselMap[widget.sectionKey] == null) {
      // Set default to true if missing
      final Map<String, bool> updatedMap = Map.from(widget.settingsProvider.isCarouselMap);
      updatedMap[widget.sectionKey] = true;
      widget.settingsProvider.saveLayoutPreferences(isCarouselMap: updatedMap);
      Logger.debug('Initialized carousel mode for ${widget.sectionKey} to true', source: 'ResizableSection');
    }
    
    // 2. Make sure carousel item count is set
    if (widget.settingsProvider.carouselItemCount[widget.sectionKey] == null) {
      final Map<String, int> updatedMap = Map.from(widget.settingsProvider.carouselItemCount);
      updatedMap[widget.sectionKey] = SettingsProvider.defaultCarouselItemCount;
      widget.settingsProvider.saveLayoutPreferences(carouselItemCount: updatedMap);
      Logger.debug('Initialized carousel item count for ${widget.sectionKey} to ${SettingsProvider.defaultCarouselItemCount}', source: 'ResizableSection');
    }
    
    // 3. Get and validate the current media type for this section
    final String effectiveMediaType = _getSectionMediaType();
    Logger.debug('Current media type from provider: $effectiveMediaType', source: 'ResizableSection');
    
    // 4. Make sure the local state matches the provider
    if (_currentMediaType != effectiveMediaType) {
      Logger.debug('Correcting local media type in ${widget.sectionKey} from $_currentMediaType to $effectiveMediaType', source: 'ResizableSection');
      setState(() {
        _currentMediaType = effectiveMediaType;
      });
    }
    
    // 5. Ensure media type is valid by checking if it exists in available folders or standard types
    if (!_availableMediaFolders.contains(_currentMediaType) && 
        !SettingsProvider.validLayoutMedia.contains(_currentMediaType)) {
      // Set to logo or first available folder
      final String newType = _availableMediaFolders.contains('logo') ? 
          'logo' : (_availableMediaFolders.isNotEmpty ? _availableMediaFolders.first : 'logo');
          
      Logger.warning('Invalid media type ${_currentMediaType}, resetting to $newType', source: 'ResizableSection');
      _updateSectionMediaType(newType);
    }
    
    // 6. Debug log current settings
    Logger.debug('Section ${widget.sectionKey} settings:', source: 'ResizableSection');
    Logger.debug('- Media type: $_currentMediaType', source: 'ResizableSection');
    Logger.debug('- Carousel mode: ${widget.settingsProvider.isCarouselMap[widget.sectionKey]}', source: 'ResizableSection');
    Logger.debug('- Item count: ${widget.settingsProvider.carouselItemCount[widget.sectionKey]}', source: 'ResizableSection');
    
    // 7. Force save to ensure all settings are persisted
    widget.settingsProvider.forceSave();
    Logger.debug('Forcing save of all settings', source: 'ResizableSection');
    
    // 8. Delay a tiny bit and force a rebuild to ensure UI reflects the latest settings
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          // This will force the section to rebuild with correct settings
          Logger.debug('Forcing final consistency rebuild for section ${widget.sectionKey}', source: 'ResizableSection');
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
    
    Logger.info('_updateSectionMediaType: changing from $_currentMediaType to $mediaType for ${widget.sectionKey}', source: 'ResizableSection');
    
    // Add specific logging for transparent widget
    if (mediaType == SettingsProvider.transparentWidgetType) {
      Logger.info('Attempting to set transparent widget for ${widget.sectionKey}', source: 'ResizableSection');
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
        Logger.warning('Unknown section key ${widget.sectionKey} - media type change may not persist!', source: 'ResizableSection');
        break;
    }
    
    // Force an immediate save to ensure the changes are persisted
    widget.settingsProvider.forceSave();
    
    // Log the current state after the change
    Logger.debug('After update: Section ${widget.sectionKey} media type is now ${_currentMediaType}', source: 'ResizableSection');
    Logger.debug('Settings provider value for ${widget.sectionKey}: ${_getSectionMediaType()}', source: 'ResizableSection');
    
    // Add explicit verification for transparent widget
    if (mediaType == SettingsProvider.transparentWidgetType) {
      final String savedType = _getSectionMediaType();
      if (savedType != SettingsProvider.transparentWidgetType) {
        Logger.error('Failed to save transparent widget type! Saved as: $savedType', source: 'ResizableSection');
      } else {
        Logger.info('Successfully saved transparent widget type', source: 'ResizableSection');
      }
    }
    
    // Force a more substantial rebuild after a short delay to ensure all UI updates
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() {
          // Force a rebuild with the new media type
          Logger.debug('Forcing full rebuild of section ${widget.sectionKey} with media type $mediaType', source: 'ResizableSection');
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
        // Make container fully transparent when not in edit mode
        color: widget.isEditMode ? Colors.black38 : Colors.transparent,
        // Show borders only in edit mode
        border: widget.isEditMode ? Border(
          left: BorderSide(color: Colors.grey[850]!, width: 1),
          right: BorderSide(color: Colors.grey[850]!, width: 1),
          top: BorderSide(color: Colors.grey[850]!, width: 1),
          bottom: BorderSide(color: Colors.grey[850]!, width: 1),
        ) : null,
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
    // Build a unique key string that changes whenever relevant properties change
    final keyString = '${widget.sectionKey}_${_currentMediaType}_${widget.isEditMode}_${widget.selectedGameIndex}';
    
    // Get the carousel mode setting for this section (default to widget value if not set)
    final isCarousel = widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? true;
    
    // Calculate the alignment based on section position
    final alignment = _getAlignment();
    
    // Calculate the background color - make transparent except in edit mode
    final backgroundColor = widget.isEditMode 
      ? _getEditModeColor() 
      : Colors.transparent;
    
    // Get the selected game index for this section specifically
    final selectedGameIndex = widget.settingsProvider.getSelectedGameIndex(widget.sectionKey);
    
    Logger.debug('Building game content with key: $keyString', source: 'ResizableSection');
    
    // Show loading indicator when changing media types
    if (_isChangingMediaType) {
      return Container(
        color: backgroundColor,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Changing media type...',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }
    
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
        Logger.debug('ResizableSection received game selection: section=${widget.sectionKey}, index=$index', source: 'ResizableSection');
        
        // Update ALL sections with the new selection to keep them in sync
        widget.settingsProvider.setSelectedGameIndex('top_left', index);
        widget.settingsProvider.setSelectedGameIndex('top_center', index);
        widget.settingsProvider.setSelectedGameIndex('top_right', index);
        widget.settingsProvider.setSelectedGameIndex('left', index);
        widget.settingsProvider.setSelectedGameIndex('right', index);
        widget.settingsProvider.setSelectedGameIndex('bottom', index);
        widget.settingsProvider.setSelectedGameIndex('main', index);
        
        if (widget.onGameSelected != null) {
          Logger.debug('Calling parent onGameSelected with index=$index', source: 'ResizableSection');
          widget.onGameSelected!(index);
        }
        
        // Force a rebuild to ensure the UI updates
        setState(() {
          Logger.debug('Forcing ResizableSection rebuild for section ${widget.sectionKey}', source: 'ResizableSection');
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
    // Load standard media types if no folders were found
    final List<String> mediaOptions = _availableMediaFolders.isEmpty 
        ? SettingsProvider.validLayoutMedia 
        : _availableMediaFolders;
        
    // Make sure our special widget types are included in the options
    if (!mediaOptions.contains(SettingsProvider.staticImageWidgetType)) {
      mediaOptions.add(SettingsProvider.staticImageWidgetType);
    }
    if (!mediaOptions.contains(SettingsProvider.transparentWidgetType)) {
      mediaOptions.add(SettingsProvider.transparentWidgetType);
    }
        
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
              value: _currentMediaType.isNotEmpty && mediaOptions.contains(_currentMediaType) 
                  ? _currentMediaType 
                  : mediaOptions.isNotEmpty ? mediaOptions.first : 'logo',
              dropdownColor: Colors.black87,
              isDense: true,
              underline: const SizedBox(),
              items: [
                ...mediaOptions.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        _getDisplayNameForMediaType(type),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )),
              ],
              onChanged: (value) async {
                if (value != null) {
                  Logger.debug('Dropdown selection changed to: $value for section ${widget.sectionKey}', source: 'ResizableSection');
                  
                  // Use our wrapper method which ensures everything is properly updated
                  _changeMediaType(value);
                  
                  // Force another save and UI update after a short delay
                  Future.delayed(const Duration(milliseconds: 100), () {
                    widget.settingsProvider.forceSave();
                    
                    if (mounted) {
                      setState(() {
                        Logger.debug('Forcing final UI update after media type change to $value', source: 'ResizableSection');
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
                // Don't show carousel toggle for video type or our special widget types
                if (widget.mediaType != 'video' && 
                    widget.mediaType != SettingsProvider.staticImageWidgetType &&
                    widget.mediaType != SettingsProvider.transparentWidgetType)
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
    
    // Special validation for our widget types
    if (mediaType == SettingsProvider.transparentWidgetType || 
        mediaType == SettingsProvider.staticImageWidgetType) {
      // These types are valid and should be returned as-is
      Logger.debug('Special widget type found: $mediaType for ${widget.sectionKey}', source: 'ResizableSection');
    }
    
    // Log the media type being returned
    Logger.debug('_getSectionMediaType for ${widget.sectionKey} returning: $mediaType', source: 'ResizableSection');
    
    return mediaType;
  }

  // Update the media content when settings change
  void _updateMediaContent() {
    // Skip if widget is unmounted
    if (!mounted) return;
    
    Logger.debug('MediaContent update triggered for section ${widget.sectionKey}', source: 'ResizableSection');
    
    try {
      // Get the current media type from settings provider
      final newMediaType = _getSectionMediaType();
      
      // Handle invalid media types by resetting to a valid option
      if (!_availableMediaFolders.contains(newMediaType) && 
          !SettingsProvider.validLayoutMedia.contains(newMediaType)) {
        // Set to logo or first available folder
        final String resetType = _availableMediaFolders.contains('logo') ? 
            'logo' : (_availableMediaFolders.isNotEmpty ? _availableMediaFolders.first : 'logo');
            
        Logger.warning('Auto-correcting invalid media type $newMediaType to $resetType in ${widget.sectionKey}', source: 'ResizableSection');
        _updateSectionMediaType(resetType);
        return; // Return early since we're handling this in _updateSectionMediaType
      }
      
      // If media type changed, update the state
      if (newMediaType != _currentMediaType) {
        Logger.debug('Media type changed externally in ${widget.sectionKey} from $_currentMediaType to $newMediaType', source: 'ResizableSection');
        setState(() {
          _currentMediaType = newMediaType;
        });
      }
      
      // Check if the selected game index has changed
      final currentSelectedIndex = widget.settingsProvider.getSelectedGameIndex(widget.sectionKey);
      if (currentSelectedIndex != widget.selectedGameIndex) {
        Logger.debug('Selected game index changed in ${widget.sectionKey} from ${widget.selectedGameIndex} to $currentSelectedIndex', source: 'ResizableSection');
        // Force a rebuild to show the new selection
        setState(() {});
      }
      
      // Check if carousel mode changed
      final isCarousel = widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? true;
      Logger.debug('Carousel mode for ${widget.sectionKey}: $isCarousel', source: 'ResizableSection');
      
      // Force update regardless to ensure all sections stay in sync
      setState(() {
        Logger.debug('Forcing update in section ${widget.sectionKey} to ensure synchronization', source: 'ResizableSection');
      });
    } catch (e) {
      Logger.error('Error in _updateMediaContent for ${widget.sectionKey}: $e', source: 'ResizableSection');
    }
  }
  
  @override
  void dispose() {
    // Remove the listener when the widget is disposed
    widget.settingsProvider.removeListener(_updateMediaContent);
    super.dispose();
  }

  // Helper method to safely change the media type, ensuring all paths and settings are properly updated
  void _changeMediaType(String newMediaType) async {
    if (_currentMediaType == newMediaType) return;
    
    Logger.info('_changeMediaType: changing from ${_currentMediaType} to $newMediaType for ${widget.sectionKey}', source: 'ResizableSection');
    
    // Set a loading state to show user feedback
    setState(() {
      _isChangingMediaType = true;
    });
    
    // Delay the actual change to allow UI to refresh with loading indicator
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Use compute to offload resource cleanup to another thread if coming from video
    if (_currentMediaType == 'video') {
      // Cleanup video resources before switching
      await _cleanupVideoResources();
    }
    
    // Update the local state variable
    setState(() {
      _currentMediaType = newMediaType;
    });
    
    // Update the settings provider using our comprehensive update method
    _updateSectionMediaType(newMediaType);
    
    // Double-check that the media type was actually updated in the SettingsProvider
    final verifiedMediaType = _getSectionMediaType();
    Logger.debug('After _updateSectionMediaType: Provider reports media type for ${widget.sectionKey} is: $verifiedMediaType', source: 'ResizableSection');
    
    // Special handling for static_image - prompt user to select an image immediately
    if (newMediaType == 'static_image') {
      // If there's already a static image path, we don't need to prompt
      final existingPath = widget.settingsProvider.getStaticImagePath(widget.sectionKey);
      if (existingPath == null || existingPath.isEmpty) {
        Logger.info('New static_image section selected, will prompt for image selection', source: 'ResizableSection');
        // Use our StaticImageManager to prompt for image selection
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final staticImageManager = StaticImageManager();
          await staticImageManager.pickStaticImage(widget.settingsProvider, widget.sectionKey);
          
          // Force a rebuild to show the new image
          if (mounted) {
            setState(() {});
          }
        });
      } else {
        Logger.info('Static image already selected: $existingPath', source: 'ResizableSection');
      }
    }
    
    // Special handling for transparent widget type
    if (newMediaType == SettingsProvider.transparentWidgetType) {
      Logger.info('Setting transparent widget for ${widget.sectionKey}', source: 'ResizableSection');
      
      // No special action needed, just make sure it's correctly saved
      if (_getSectionMediaType() != SettingsProvider.transparentWidgetType) {
        Logger.warning('Transparent widget type not saved properly! Attempting to save again...', source: 'ResizableSection');
        
        // Try saving it again directly
        switch (widget.sectionKey) {
          case 'left':
            widget.settingsProvider.saveLayoutPreferences(selectedLeftImage: SettingsProvider.transparentWidgetType);
            break;
          case 'right':
            widget.settingsProvider.saveLayoutPreferences(selectedRightImage: SettingsProvider.transparentWidgetType);
            break;
          case 'top':
            widget.settingsProvider.saveLayoutPreferences(selectedTopImage: SettingsProvider.transparentWidgetType);
            break;
          case 'bottom':
            widget.settingsProvider.saveLayoutPreferences(selectedBottomImage: SettingsProvider.transparentWidgetType);
            break;
          case 'main':
            widget.settingsProvider.saveLayoutPreferences(selectedMainImage: SettingsProvider.transparentWidgetType);
            break;
          case 'top_left':
            widget.settingsProvider.saveLayoutPreferences(selectedTopLeftImage: SettingsProvider.transparentWidgetType);
            break;
          case 'top_center':
            widget.settingsProvider.saveLayoutPreferences(selectedTopCenterImage: SettingsProvider.transparentWidgetType);
            break;
          case 'top_right':
            widget.settingsProvider.saveLayoutPreferences(selectedTopRightImage: SettingsProvider.transparentWidgetType);
            break;
        }
        widget.settingsProvider.forceSave();
      }
    }
    
    // If switching TO video, initialize video slowly
    if (newMediaType == 'video') {
      // Prepare video resources in the background
      _prepareVideoResources();
    }
    
    // Clear loading state
    setState(() {
      _isChangingMediaType = false;
    });
    
    // Force another save and UI update after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.settingsProvider.forceSave();
      
      if (mounted) {
        setState(() {
          Logger.debug('Forcing final UI update after media type change to $newMediaType', source: 'ResizableSection');
        });
      }
    });
  }
  
  // Helper method to clean up video resources
  Future<void> _cleanupVideoResources() async {
    try {
      // Get VideoManager instance
      final videoManager = VideoManager();
      
      // Stop and release the player for this section
      String playerKey = 'section_${widget.sectionKey}';
      await videoManager.stopPlayer(playerKey);
      
      Logger.debug('Video resources cleaned up for ${widget.sectionKey}', source: 'ResizableSection');
    } catch (e) {
      Logger.error('Error cleaning up video resources: $e', source: 'ResizableSection');
    }
  }
  
  // Helper method to prepare video resources in the background
  Future<void> _prepareVideoResources() async {
    try {
      // Do this in the background to avoid UI freezing
      Future.delayed(const Duration(milliseconds: 100), () async {
        // Get VideoManager instance
        final videoManager = VideoManager();
        
        // Initialize player in advance
        String playerKey = 'section_${widget.sectionKey}';
        await videoManager.getPlayerAsync(playerKey);
        
        Logger.debug('Video resources prepared for ${widget.sectionKey}', source: 'ResizableSection');
      });
    } catch (e) {
      Logger.error('Error preparing video resources: $e', source: 'ResizableSection');
    }
  }

  // Helper method to get alignment based on section position
  Alignment _getAlignment() {
    // Use alignment from settings if available
    if (widget.settingsProvider.alignmentMap.containsKey(widget.sectionKey)) {
      return widget.settingsProvider.alignmentMap[widget.sectionKey]!;
    }
    
    // Default alignments based on section position
    switch (widget.sectionKey) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'top_left':
        return Alignment.topLeft;
      case 'top_center':
        return Alignment.topCenter;
      case 'top_right':
        return Alignment.topRight;
      default:
        return Alignment.center;
    }
  }
  
  // Helper method to get edit mode color
  Color _getEditModeColor() {
    // Different colors for different sections in edit mode
    switch (widget.sectionKey) {
      case 'left':
        return Colors.blue.withOpacity(0.3);
      case 'right':
        return Colors.red.withOpacity(0.3);
      case 'top':
        return Colors.green.withOpacity(0.3);
      case 'bottom':
        return Colors.orange.withOpacity(0.3);
      case 'main':
        return Colors.purple.withOpacity(0.3);
      case 'top_left':
        return Colors.teal.withOpacity(0.3);
      case 'top_center':
        return Colors.amber.withOpacity(0.3);
      case 'top_right':
        return Colors.cyan.withOpacity(0.3);
      default:
        return Colors.grey.withOpacity(0.3);
    }
  }

  // Helper method to get user-friendly display names for media types
  String _getDisplayNameForMediaType(String mediaType) {
    switch (mediaType) {
      case 'static_image_widget':
        return 'STATIC IMAGE WIDGET';
      case 'transparent':
        return 'TRANSPARENT';
      default:
        return mediaType.replaceAll('_', ' ').toUpperCase();
    }
  }
}
