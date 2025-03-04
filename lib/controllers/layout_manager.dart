import 'package:flutter/material.dart';
import '../settings_provider.dart';

class LayoutManager {
  final SettingsProvider settingsProvider;

  // Margin dimensions
  double leftMarginWidth;
  double rightMarginWidth;
  double topMarginHeight;
  double bottomMarginHeight;

  // Throttle values to reduce updates
  int _lastUpdateTime = 0;
  final int _throttleInterval = 50; // milliseconds

  // Media types for each section
  String selectedLeftImage;
  String selectedRightImage;
  String selectedTopImage;
  String selectedBottomImage;
  String selectedMainImage;

  LayoutManager(this.settingsProvider)
      : leftMarginWidth = settingsProvider.leftMarginWidth,
        rightMarginWidth = settingsProvider.rightMarginWidth,
        topMarginHeight = settingsProvider.topMarginHeight,
        bottomMarginHeight = settingsProvider.bottomMarginHeight,
        selectedLeftImage = settingsProvider.selectedLeftImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedLeftImage,
        selectedRightImage = settingsProvider.selectedRightImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedRightImage,
        selectedTopImage = settingsProvider.selectedTopImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedTopImage,
        selectedBottomImage = settingsProvider.selectedBottomImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedBottomImage,
        selectedMainImage = settingsProvider.selectedMainImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedMainImage;

  // Check if we should update based on throttle interval
  bool _shouldUpdate() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateTime > _throttleInterval) {
      _lastUpdateTime = now;
      return true;
    }
    return false;
  }

  // Adjust top margin height with limits
  void adjustTopMargin(double delta, double maxHeight) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newHeight = (topMarginHeight + delta).clamp(50.0, maxHeight);
    if ((newHeight - topMarginHeight).abs() < 1.0) {
      return; // Ignore tiny changes
    }

    topMarginHeight = newHeight;
    settingsProvider.notifyListeners(); // Notify listeners of the change
  }

  // Adjust bottom margin height with limits
  void adjustBottomMargin(double delta, double maxHeight) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newHeight = (bottomMarginHeight + delta).clamp(50.0, maxHeight);
    if ((newHeight - bottomMarginHeight).abs() < 1.0) {
      return; // Ignore tiny changes
    }

    bottomMarginHeight = newHeight;
    settingsProvider.notifyListeners(); // Notify listeners of the change
  }

  // Adjust left margin width with limits
  void adjustLeftMargin(double delta, double maxWidth) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newWidth = (leftMarginWidth + delta).clamp(100.0, maxWidth);
    if ((newWidth - leftMarginWidth).abs() < 1.0) return; // Ignore tiny changes

    leftMarginWidth = newWidth;
    settingsProvider.notifyListeners(); // Notify listeners of the change
  }

  // Adjust right margin width with limits
  void adjustRightMargin(double delta, double maxWidth) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newWidth = (rightMarginWidth + delta).clamp(100.0, maxWidth);
    if ((newWidth - rightMarginWidth).abs() < 1.0) {
      return; // Ignore tiny changes
    }

    rightMarginWidth = newWidth;
    settingsProvider.notifyListeners(); // Notify listeners of the change
  }

  // Set alignment for a specific section
  void setAlignment(String sectionKey, String alignment) {
    Map<String, Alignment> updatedAlignmentMap =
        Map.from(settingsProvider.alignmentMap);
    updatedAlignmentMap[sectionKey] = SettingsProvider.getAlignmentFromString(alignment);

    saveLayoutPreferences(alignmentMap: updatedAlignmentMap);
  }

  // Set background color for a specific section
  void setBackgroundColor(String sectionKey, String colorKey) {
    Map<String, Color> updatedBackgroundColorMap =
        Map.from(settingsProvider.backgroundColorMap);
    updatedBackgroundColorMap[sectionKey] = SettingsProvider.getColorFromString(colorKey);

    saveLayoutPreferences(backgroundColorMap: updatedBackgroundColorMap);
  }

  // Toggle carousel mode for a specific section
  void toggleCarouselMode(String sectionKey) {
    Map<String, bool> updatedCarouselMap =
        Map.from(settingsProvider.isCarouselMap);
    updatedCarouselMap[sectionKey] =
        !(settingsProvider.isCarouselMap[sectionKey] ?? true);

    saveLayoutPreferences(isCarouselMap: updatedCarouselMap);
  }

  // Update media type for a specific section
  void updateSectionMediaType(String sectionKey, String mediaType) {
    switch (sectionKey) {
      case 'left':
        selectedLeftImage = mediaType;
        break;
      case 'right':
        selectedRightImage = mediaType;
        break;
      case 'top':
        selectedTopImage = mediaType;
        break;
      case 'bottom':
        selectedBottomImage = mediaType;
        break;
      case 'main':
        selectedMainImage = mediaType;
        break;
    }

    // Save changes immediately and notify listeners
    settingsProvider.saveLayoutPreferences(
      leftMarginWidth: leftMarginWidth,
      rightMarginWidth: rightMarginWidth,
      topMarginHeight: topMarginHeight,
      bottomMarginHeight: bottomMarginHeight,
      selectedLeftImage: selectedLeftImage,
      selectedRightImage: selectedRightImage,
      selectedTopImage: selectedTopImage,
      selectedBottomImage: selectedBottomImage,
      selectedMainImage: selectedMainImage,
    );
    settingsProvider.notifyListeners();
  }

  // Save all layout preferences
  void saveLayoutPreferences({
    double? leftMarginWidth,
    double? rightMarginWidth,
    double? bottomMarginHeight,
    double? topMarginHeight,
    String? selectedLeftImage,
    String? selectedRightImage,
    String? selectedTopImage,
    String? selectedBottomImage,
    String? selectedMainImage,
    Map<String, bool>? isCarouselMap,
    Map<String, Alignment>? alignmentMap,
    Map<String, Color>? backgroundColorMap,
    Map<String, bool>? showTicker,
    Map<String, String>? tickerAlignment,
  }) {
    settingsProvider.saveLayoutPreferences(
      leftMarginWidth: leftMarginWidth,
      rightMarginWidth: rightMarginWidth,
      bottomMarginHeight: bottomMarginHeight,
      topMarginHeight: topMarginHeight,
      selectedLeftImage: selectedLeftImage,
      selectedRightImage: selectedRightImage,
      selectedTopImage: selectedTopImage,
      selectedBottomImage: selectedBottomImage,
      selectedMainImage: selectedMainImage,
      isCarouselMap: isCarouselMap,
      alignmentMap: alignmentMap,
      backgroundColorMap: backgroundColorMap,
      showTicker: showTicker,
      tickerAlignment: tickerAlignment,
    );
  }
}
