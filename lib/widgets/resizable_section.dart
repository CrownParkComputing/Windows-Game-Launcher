import 'package:flutter/material.dart';
import '../settings_provider.dart';
import 'game_carousel.dart';

class ResizableSection extends StatelessWidget {
  final double width;
  final double height;
  final String mediaType;
  final bool isVertical;
  final Function(double) onResize;
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
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the carousel mode and alignment for this section from settings provider
    bool isCarousel = settingsProvider.isCarouselMap[sectionKey] ?? true;
    Alignment alignment = settingsProvider.alignmentMap[sectionKey] ?? Alignment.center;
    Color backgroundColor = settingsProvider.backgroundColorMap[sectionKey] ?? Colors.black45;

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black38,
          border: Border.all(
            color:
                isEditMode ? Colors.orange.withOpacity(0.7) : Colors.grey[850]!,
            width: isEditMode ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: GameCarousel(
                games: settingsProvider.games,
                mediaType: mediaType,
                width: width,
                height: height,
                isCarousel: isCarousel,
                alignment: alignment,
                backgroundColor: backgroundColor,
                selectedIndex: selectedGameIndex,
                onGameSelected: onGameSelected,
                isEditMode: isEditMode,
                settingsProvider: settingsProvider,
                sectionKey: sectionKey,
              ),
            ),

            // Simple drag handle for resizing - only shown in edit mode and positioned on inner edges
            if (isEditMode)
              isVertical
                  ? Positioned(
                      // For vertical sections (top/bottom margins)
                      // For top section, place handle at bottom; for bottom section, place handle at top
                      bottom: sectionKey == 'top' ? 0 : null,
                      top: sectionKey == 'bottom' ? 0 : null,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
                        behavior:
                            HitTestBehavior.opaque, // Improve responsiveness
                        onVerticalDragUpdate: (details) {
                          // Apply multiplier for smoother dragging
                          const dragMultiplier = 1.5;
                          // For bottom section, positive delta means increase size; for top section, negative delta means increase size
                          final delta = sectionKey == 'bottom'
                              ? details.delta.dy * dragMultiplier
                              : -details.delta.dy * dragMultiplier;
                          onResize(delta);
                        },
                        child: Container(
                          height: 15,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.7),
                            border: Border(
                              top: sectionKey == 'bottom'
                                  ? const BorderSide(color: Colors.white, width: 2)
                                  : BorderSide.none,
                              bottom: sectionKey == 'top'
                                  ? const BorderSide(color: Colors.white, width: 2)
                                  : BorderSide.none,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.drag_handle,
                                color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    )
                  : Positioned(
                      // For horizontal sections (left/right margins)
                      top: 0,
                      bottom: 0,
                      // For left section, place handle on right; for right section, place handle on left
                      left: sectionKey == 'right' ? 0 : null,
                      right: sectionKey == 'left' ? 0 : null,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque, // Improve responsiveness
                        onHorizontalDragUpdate: (details) {
                          // Get drag direction relative to section position
                          const dragMultiplier = 1.5;
                          final delta = sectionKey == 'left'
                              ? details.delta.dx * dragMultiplier
                              : -details.delta.dx * dragMultiplier;
                          onResize(delta);
                        },
                        child: Container(
                          width: 15,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.7),
                            border: Border(
                              left: sectionKey == 'right'
                                  ? const BorderSide(color: Colors.white, width: 2)
                                  : BorderSide.none,
                              right: sectionKey == 'left'
                                  ? const BorderSide(color: Colors.white, width: 2)
                                  : BorderSide.none,
                            ),
                          ),
                          child: const Center(
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: Icon(Icons.drag_handle,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ),

            // Edit mode controls (media selector, alignment, etc.)
            if (isEditMode)
              _buildEditModeControls(alignment, backgroundColor),
          ],
        ),
      ),
    );
  }

  Widget _buildEditModeControls(
      Alignment alignment, Color backgroundColor) {
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
            // Background color selector
            DropdownButton<String>(
              value: SettingsProvider.availableBackgroundColors.keys.first,
              dropdownColor: Colors.black87,
              isDense: true,
              underline: const SizedBox(),
              hint: const Text('Background',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
              items: SettingsProvider.availableBackgroundColors.keys
                  .map((colorKey) {
                final color =
                    SettingsProvider.availableBackgroundColors[colorKey]!;
                return DropdownMenuItem<String>(
                  value: colorKey,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(color: Colors.white),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        colorKey.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (colorKey) {
                if (colorKey != null) {
                  _setBackgroundColor(colorKey);
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

                // Show alignment options for all views (carousel and static)
                IconButton(
                  icon: Icon(
                    Icons.align_horizontal_left,
                    color:
                        alignment == Alignment.centerLeft ? Colors.blue : Colors.white,
                    size: 16,
                  ),
                  tooltip: 'Left Align',
                  onPressed: () => _setAlignment('left'),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
                IconButton(
                  icon: Icon(
                    Icons.align_horizontal_center,
                    color: alignment == Alignment.center ? Colors.blue : Colors.white,
                    size: 16,
                  ),
                  tooltip: 'Center Align',
                  onPressed: () => _setAlignment('center'),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
                IconButton(
                  icon: Icon(
                    Icons.align_horizontal_right,
                    color:
                        alignment == Alignment.centerRight ? Colors.blue : Colors.white,
                    size: 16,
                  ),
                  tooltip: 'Right Align',
                  onPressed: () => _setAlignment('right'),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
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
    );
  }
}
