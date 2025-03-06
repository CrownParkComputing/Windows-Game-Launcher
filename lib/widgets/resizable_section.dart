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
    
    // Debug print current media type and static image path
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _debugPrintMediaInfo();
    });
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

  void _debugPrintMediaInfo() {
    // Removed print statements
  }

  void _updateSectionMediaType(String mediaType) {
    // Update the local state variable
    setState(() {
      _currentMediaType = mediaType;
    });
    
    switch (widget.sectionKey) {
      case 'left':
        widget.settingsProvider.saveLayoutPreferences(selectedLeftImage: mediaType);
        break;
      case 'right':
        widget.settingsProvider.saveLayoutPreferences(selectedRightImage: mediaType);
        break;
      case 'top':
        widget.settingsProvider.saveLayoutPreferences(selectedTopImage: mediaType);
        break;
      case 'bottom':
        widget.settingsProvider.saveLayoutPreferences(selectedBottomImage: mediaType);
        break;
      case 'main':
        widget.settingsProvider.saveLayoutPreferences(selectedMainImage: mediaType);
        break;
      case 'top_left':
        widget.settingsProvider.saveLayoutPreferences(selectedTopLeftImage: mediaType);
        break;
      case 'top_center':
        widget.settingsProvider.saveLayoutPreferences(selectedTopCenterImage: mediaType);
        break;
      case 'top_right':
        widget.settingsProvider.saveLayoutPreferences(selectedTopRightImage: mediaType);
        break;
    }
    // Force an immediate save to ensure the changes are persisted
    widget.settingsProvider.forceSave();
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
              child: GameCarousel(
                games: widget.settingsProvider.games,
                mediaType: _currentMediaType,
                width: (widget.width > 0 ? widget.width : 0) - (widget.isEditMode ? 20 : 0), // Give more room for dividers
                height: widget.height > 0 ? widget.height : 0,
                isCarousel: widget.settingsProvider.isCarouselMap[widget.sectionKey] ?? true,
                alignment: Alignment.center,
                backgroundColor: widget.settingsProvider.backgroundColorMap[widget.sectionKey] ?? Colors.black45,
                selectedIndex: widget.selectedGameIndex,
                onGameSelected: widget.onGameSelected,
                isEditMode: widget.isEditMode,
                settingsProvider: widget.settingsProvider,
                sectionKey: widget.sectionKey,
              ),
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
                  // Removed print statement
                  
                  // Update the local state immediately to reflect the change in the dropdown
                  setState(() {
                    _currentMediaType = value;
                  });
                  
                  if (value == 'static_image') {
                    final imagePath = await _promptForImagePath(context);
                    if (imagePath != null) {
                      // Removed print statement
                      
                      // First update the section media type to 'static_image'
                      _updateSectionMediaType('static_image');
                      // Then set the static image path
                      widget.settingsProvider.setStaticImagePath(widget.sectionKey, imagePath);
                      
                      // Force an immediate save to ensure all settings are persisted
                      widget.settingsProvider.forceSave();
                      
                      // Removed print statements
                    } else {
                      // If the user cancels the file picker, revert to the previous media type
                      setState(() {
                        _currentMediaType = widget.mediaType;
                      });
                    }
                  } else {
                    _updateSectionMediaType(value);
                    
                    // Removed print statement
                  }
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
    return await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    ).then((result) {
      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
      return null;
    });
  }

  // Helper method to get the current media type for this section
  String _getSectionMediaType() {
    switch (widget.sectionKey) {
      case 'left':
        return widget.settingsProvider.selectedLeftImage;
      case 'right':
        return widget.settingsProvider.selectedRightImage;
      case 'top':
        return widget.settingsProvider.selectedTopImage;
      case 'bottom':
        return widget.settingsProvider.selectedBottomImage;
      case 'main':
        return widget.settingsProvider.selectedMainImage;
      case 'top_left':
        return widget.settingsProvider.selectedTopLeftImage;
      case 'top_center':
        return widget.settingsProvider.selectedTopCenterImage;
      case 'top_right':
        return widget.settingsProvider.selectedTopRightImage;
      default:
        return 'logo';
    }
  }
}
