import 'package:flutter/material.dart';
import '../settings_provider.dart';
import 'game_carousel.dart';

class ResizableSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      width: width > 0 ? width : 0,
      height: height > 0 ? height : 0,
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
              width: width > 0 ? width : 0,
              height: height > 0 ? height : 0,
              child: GameCarousel(
                games: settingsProvider.games,
                mediaType: mediaType,
                width: (width > 0 ? width : 0) - (isEditMode ? 20 : 0), // Give more room for dividers
                height: height > 0 ? height : 0,
                isCarousel: settingsProvider.isCarouselMap[sectionKey] ?? true,
                alignment: Alignment.center,
                backgroundColor: settingsProvider.backgroundColorMap[sectionKey] ?? Colors.black45,
                selectedIndex: selectedGameIndex,
                onGameSelected: onGameSelected,
                isEditMode: isEditMode,
                settingsProvider: settingsProvider,
                sectionKey: sectionKey,
              ),
            ),
          ),

          // Dividers for resizing
          if (isEditMode && _shouldShowRightDivider())
            _buildRightDivider(),
            
          if (isEditMode && _shouldShowLeftDivider())
            _buildLeftDivider(),
            
          if (isEditMode && _shouldShowTopDivider())
            _buildTopDivider(),
            
          if (isEditMode && _shouldShowBottomDivider())
            _buildBottomDivider(),
            
          if (isEditMode && sectionKey == 'artwork_3d')
            _buildArtwork3dRightDivider(),
            
          if (isEditMode && sectionKey == 'fanart')
            _buildFanartRightDivider(),

          // Edit mode controls
          if (isEditMode)
            _buildEditModeControls(),
        ],
      ),
    );
  }

  bool _shouldShowRightDivider() {
    return sectionKey == 'top_left' || sectionKey == 'left';
  }
  
  bool _shouldShowLeftDivider() {
    return sectionKey == 'fanart';
  }
  
  bool _shouldShowTopDivider() {
    return sectionKey == 'bottom';
  }
  
  bool _shouldShowBottomDivider() {
    return sectionKey == 'top_center';
  }
  
  bool _shouldShowMiddleDivider() {
    return sectionKey == 'artwork_3d';
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
            onResize(details.delta.dx);
          },
          onPanEnd: (_) {
            if (onResizeEnd != null) {
              onResizeEnd!();
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
            onResize(-details.delta.dx);
          },
          onPanEnd: (_) {
            if (onResizeEnd != null) {
              onResizeEnd!();
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
            onResize(details.delta.dx);
          },
          onPanEnd: (_) {
            if (onResizeEnd != null) {
              onResizeEnd!();
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
            onResize(-details.delta.dy);
          },
          onPanEnd: (_) {
            if (onResizeEnd != null) {
              onResizeEnd!();
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
            onResize(details.delta.dy);
          },
          onPanEnd: (_) {
            if (onResizeEnd != null) {
              onResizeEnd!();
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
            onResize(details.delta.dx);
          },
          onPanEnd: (_) {
            if (onResizeEnd != null) {
              onResizeEnd!();
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
            onResize(details.delta.dx);
          },
          onPanEnd: (_) {
            if (onResizeEnd != null) {
              onResizeEnd!();
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
              value: mediaType,
              dropdownColor: Colors.black87,
              isDense: true,
              underline: const SizedBox(),
              items: SettingsProvider.validLayoutMedia
                  .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateSectionMediaType(value);
                }
              },
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Don't show carousel toggle for video type
                if (mediaType != 'video')
                  IconButton(
                    icon: Icon(
                      (settingsProvider.isCarouselMap[sectionKey] ?? true)
                          ? Icons.view_carousel
                          : Icons.image,
                      color: Colors.white,
                      size: 16,
                    ),
                    tooltip:
                        (settingsProvider.isCarouselMap[sectionKey] ?? true)
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
                    color: (settingsProvider.showTicker[sectionKey] ?? false)
                        ? Colors.blue
                        : Colors.white,
                    size: 16,
                  ),
                  tooltip: (settingsProvider.showTicker[sectionKey] ?? false)
                      ? 'Hide Story Ticker'
                      : 'Show Story Ticker',
                  onPressed: _toggleTicker,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),

                // Show ticker alignment options if ticker is enabled
                if (settingsProvider.showTicker[sectionKey] ?? false)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.vertical_align_top,
                          color: (settingsProvider.tickerAlignment[sectionKey] ?? 'bottom') == 'top'
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
                          color: (settingsProvider.tickerAlignment[sectionKey] ?? 'bottom') == 'bottom'
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
        Map.from(settingsProvider.alignmentMap);
    updatedAlignmentMap[sectionKey] = SettingsProvider.getAlignmentFromString(alignment);
    _saveLayoutPreferences(alignmentMap: updatedAlignmentMap);
  }

  // Helper method to set background color
  void _setBackgroundColor(String colorKey) {
    Map<String, Color> updatedBackgroundColorMap =
        Map.from(settingsProvider.backgroundColorMap);
    updatedBackgroundColorMap[sectionKey] = SettingsProvider.getColorFromString(colorKey);
    _saveLayoutPreferences(backgroundColorMap: updatedBackgroundColorMap);
  }

  // Helper method to toggle carousel mode
  void _toggleCarouselMode() {
    Map<String, bool> updatedCarouselMap =
        Map.from(settingsProvider.isCarouselMap);
    updatedCarouselMap[sectionKey] =
        !(settingsProvider.isCarouselMap[sectionKey] ?? true);
    _saveLayoutPreferences(isCarouselMap: updatedCarouselMap);
  }

  // Helper method to toggle ticker
  void _toggleTicker() {
    Map<String, bool> updatedShowTicker =
        Map.from(settingsProvider.showTicker);
    updatedShowTicker[sectionKey] =
        !(settingsProvider.showTicker[sectionKey] ?? false);
    _saveLayoutPreferences(showTicker: updatedShowTicker);
  }

  // Helper method to set ticker alignment
  void _setTickerAlignment(String alignment) {
    Map<String, String> updatedTickerAlignment =
        Map.from(settingsProvider.tickerAlignment);
    updatedTickerAlignment[sectionKey] = alignment;
    _saveLayoutPreferences(tickerAlignment: updatedTickerAlignment);
  }

  // Helper method to update media type
  void _updateSectionMediaType(String newMediaType) {
    switch (sectionKey) {
      case 'left':
        settingsProvider.saveLayoutPreferences(
          leftMarginWidth: settingsProvider.leftMarginWidth,
          rightMarginWidth: settingsProvider.rightMarginWidth,
          bottomMarginHeight: settingsProvider.bottomMarginHeight,
          topMarginHeight: settingsProvider.topMarginHeight,
          selectedLeftImage: newMediaType,
          selectedRightImage: settingsProvider.selectedRightImage,
          selectedTopImage: settingsProvider.selectedTopImage,
          selectedBottomImage: settingsProvider.selectedBottomImage,
          selectedMainImage: settingsProvider.selectedMainImage,
          isCarouselMap: settingsProvider.isCarouselMap,
          alignmentMap: settingsProvider.alignmentMap,
          backgroundColorMap: settingsProvider.backgroundColorMap,
          showTicker: settingsProvider.showTicker,
          tickerAlignment: settingsProvider.tickerAlignment,
          carouselItemCount: settingsProvider.carouselItemCount,
        );
        break;
      case 'right':
        settingsProvider.saveLayoutPreferences(
          leftMarginWidth: settingsProvider.leftMarginWidth,
          rightMarginWidth: settingsProvider.rightMarginWidth,
          bottomMarginHeight: settingsProvider.bottomMarginHeight,
          topMarginHeight: settingsProvider.topMarginHeight,
          selectedLeftImage: settingsProvider.selectedLeftImage,
          selectedRightImage: newMediaType,
          selectedTopImage: settingsProvider.selectedTopImage,
          selectedBottomImage: settingsProvider.selectedBottomImage,
          selectedMainImage: settingsProvider.selectedMainImage,
          isCarouselMap: settingsProvider.isCarouselMap,
          alignmentMap: settingsProvider.alignmentMap,
          backgroundColorMap: settingsProvider.backgroundColorMap,
          showTicker: settingsProvider.showTicker,
          tickerAlignment: settingsProvider.tickerAlignment,
          carouselItemCount: settingsProvider.carouselItemCount,
        );
        break;
      case 'top':
        settingsProvider.saveLayoutPreferences(
          leftMarginWidth: settingsProvider.leftMarginWidth,
          rightMarginWidth: settingsProvider.rightMarginWidth,
          bottomMarginHeight: settingsProvider.bottomMarginHeight,
          topMarginHeight: settingsProvider.topMarginHeight,
          selectedLeftImage: settingsProvider.selectedLeftImage,
          selectedRightImage: settingsProvider.selectedRightImage,
          selectedTopImage: newMediaType,
          selectedBottomImage: settingsProvider.selectedBottomImage,
          selectedMainImage: settingsProvider.selectedMainImage,
          isCarouselMap: settingsProvider.isCarouselMap,
          alignmentMap: settingsProvider.alignmentMap,
          backgroundColorMap: settingsProvider.backgroundColorMap,
          showTicker: settingsProvider.showTicker,
          tickerAlignment: settingsProvider.tickerAlignment,
          carouselItemCount: settingsProvider.carouselItemCount,
        );
        break;
      case 'bottom':
        settingsProvider.saveLayoutPreferences(
          leftMarginWidth: settingsProvider.leftMarginWidth,
          rightMarginWidth: settingsProvider.rightMarginWidth,
          bottomMarginHeight: settingsProvider.bottomMarginHeight,
          topMarginHeight: settingsProvider.topMarginHeight,
          selectedLeftImage: settingsProvider.selectedLeftImage,
          selectedRightImage: settingsProvider.selectedRightImage,
          selectedTopImage: settingsProvider.selectedTopImage,
          selectedBottomImage: newMediaType,
          selectedMainImage: settingsProvider.selectedMainImage,
          isCarouselMap: settingsProvider.isCarouselMap,
          alignmentMap: settingsProvider.alignmentMap,
          backgroundColorMap: settingsProvider.backgroundColorMap,
          showTicker: settingsProvider.showTicker,
          tickerAlignment: settingsProvider.tickerAlignment,
          carouselItemCount: settingsProvider.carouselItemCount,
        );
        break;
      case 'main':
        settingsProvider.saveLayoutPreferences(
          leftMarginWidth: settingsProvider.leftMarginWidth,
          rightMarginWidth: settingsProvider.rightMarginWidth,
          bottomMarginHeight: settingsProvider.bottomMarginHeight,
          topMarginHeight: settingsProvider.topMarginHeight,
          selectedLeftImage: settingsProvider.selectedLeftImage,
          selectedRightImage: settingsProvider.selectedRightImage,
          selectedTopImage: settingsProvider.selectedTopImage,
          selectedBottomImage: settingsProvider.selectedBottomImage,
          selectedMainImage: newMediaType,
          isCarouselMap: settingsProvider.isCarouselMap,
          alignmentMap: settingsProvider.alignmentMap,
          backgroundColorMap: settingsProvider.backgroundColorMap,
          showTicker: settingsProvider.showTicker,
          tickerAlignment: settingsProvider.tickerAlignment,
          carouselItemCount: settingsProvider.carouselItemCount,
        );
        break;
    }
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
    settingsProvider.saveLayoutPreferences(
      leftMarginWidth: settingsProvider.leftMarginWidth,
      rightMarginWidth: settingsProvider.rightMarginWidth,
      topMarginHeight: settingsProvider.topMarginHeight,
      bottomMarginHeight: settingsProvider.bottomMarginHeight,
      selectedLeftImage:
          selectedLeftImage ?? settingsProvider.selectedLeftImage,
      selectedRightImage:
          selectedRightImage ?? settingsProvider.selectedRightImage,
      selectedTopImage: selectedTopImage ?? settingsProvider.selectedTopImage,
      selectedBottomImage:
          selectedBottomImage ?? settingsProvider.selectedBottomImage,
      selectedMainImage:
          selectedMainImage ?? settingsProvider.selectedMainImage,
      alignmentMap: alignmentMap ?? settingsProvider.alignmentMap,
      backgroundColorMap:
          backgroundColorMap ?? settingsProvider.backgroundColorMap,
      isCarouselMap: isCarouselMap ?? settingsProvider.isCarouselMap,
      showTicker: showTicker ?? settingsProvider.showTicker,
      tickerAlignment: tickerAlignment ?? settingsProvider.tickerAlignment,
      carouselItemCount: carouselItemCount ?? settingsProvider.carouselItemCount,
    );
  }
}
