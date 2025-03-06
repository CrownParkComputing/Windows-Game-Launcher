import 'package:flutter/material.dart';
import '../settings_provider.dart';

class LayoutManager {
  final SettingsProvider settingsProvider;

  // Margin dimensions
  double leftMarginWidth;
  double rightMarginWidth;
  double topMarginHeight;
  double bottomMarginHeight;
  double topLeftWidth;
  double topCenterWidth;
  double topRightWidth;

  // Throttle values to reduce updates
  int _lastUpdateTime = 0;
  final int _throttleInterval = 50; // milliseconds

  // Media types for each section
  String selectedLeftImage;
  String selectedRightImage;
  String selectedTopImage;
  String selectedTopLeftImage;
  String selectedTopCenterImage;
  String selectedTopRightImage;
  String selectedBottomImage;
  String selectedMainImage;

  LayoutManager(this.settingsProvider)
      : leftMarginWidth = settingsProvider.leftMarginWidth,
        rightMarginWidth = settingsProvider.rightMarginWidth,
        topMarginHeight = settingsProvider.topMarginHeight,
        bottomMarginHeight = settingsProvider.bottomMarginHeight,
        topLeftWidth = settingsProvider.topLeftWidth,
        topCenterWidth = settingsProvider.topCenterWidth,
        topRightWidth = settingsProvider.topRightWidth,
        selectedLeftImage = settingsProvider.selectedLeftImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedLeftImage,
        selectedRightImage = settingsProvider.selectedRightImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedRightImage,
        selectedTopImage = settingsProvider.selectedTopImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedTopImage,
        selectedTopLeftImage = settingsProvider.selectedTopLeftImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedTopLeftImage,
        selectedTopCenterImage = settingsProvider.selectedTopCenterImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedTopCenterImage,
        selectedTopRightImage = settingsProvider.selectedTopRightImage.isEmpty
            ? 'banner'
            : settingsProvider.selectedTopRightImage,
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
    
    // Only notify listeners, don't save during drag
    settingsProvider.notifyListeners();
  }

  // Adjust bottom margin height with limits
  void adjustBottomMargin(double delta, double maxHeight) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newHeight = (bottomMarginHeight + delta).clamp(50.0, maxHeight);
    if ((newHeight - bottomMarginHeight).abs() < 1.0) {
      return; // Ignore tiny changes
    }

    bottomMarginHeight = newHeight;
    
    // Only notify listeners, don't save during drag
    settingsProvider.notifyListeners();
  }

  // Adjust left margin width with limits
  void adjustLeftMargin(double delta, double maxWidth) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newWidth = (leftMarginWidth + delta).clamp(50.0, maxWidth);
    if ((newWidth - leftMarginWidth).abs() < 1.0) {
      return; // Ignore tiny changes
    }

    leftMarginWidth = newWidth;
    
    // Only notify listeners, don't save during drag
    settingsProvider.notifyListeners();
  }

  // Adjust right margin width with limits
  void adjustRightMargin(double delta, double maxWidth) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newWidth = (rightMarginWidth + delta).clamp(50.0, maxWidth);
    if ((newWidth - rightMarginWidth).abs() < 1.0) {
      return; // Ignore tiny changes
    }

    rightMarginWidth = newWidth;
    
    // Only notify listeners, don't save during drag
    settingsProvider.notifyListeners();
  }

  // Adjust top left width with limits
  void adjustTopLeftWidth(double delta, double maxWidth) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newWidth = (topLeftWidth + delta).clamp(50.0, maxWidth);
    if ((newWidth - topLeftWidth).abs() < 1.0) return;

    topLeftWidth = newWidth;
    
    // Only notify listeners, don't save during drag
    settingsProvider.notifyListeners();
  }

  // Adjust top center width with limits
  void adjustTopCenterWidth(double delta, double maxWidth) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newWidth = (topCenterWidth + delta).clamp(50.0, maxWidth);
    if ((newWidth - topCenterWidth).abs() < 1.0) return;

    topCenterWidth = newWidth;
    
    // Only notify listeners, don't save during drag
    settingsProvider.notifyListeners();
  }

  // Adjust top right width with limits
  void adjustTopRightWidth(double delta, double maxWidth) {
    if (!_shouldUpdate()) return; // Throttle updates for smoother performance

    double newWidth = (topRightWidth + delta).clamp(50.0, maxWidth);
    if ((newWidth - topRightWidth).abs() < 1.0) return;

    topRightWidth = newWidth;
    
    // Only notify listeners, don't save during drag
    settingsProvider.notifyListeners();
  }

  // Set alignment for a specific section
  void setAlignment(String sectionKey, String alignment) {
    Map<String, Alignment> updatedAlignmentMap =
        Map.from(settingsProvider.alignmentMap);
    updatedAlignmentMap[sectionKey] = SettingsProvider.getAlignmentFromString(alignment);

    // Just update the map in memory, save will happen when exiting edit mode
    settingsProvider.alignmentMap = updatedAlignmentMap;
    settingsProvider.notifyListeners();
  }

  // Set background color for a specific section
  void setBackgroundColor(String sectionKey, String colorKey) {
    Map<String, Color> updatedBackgroundColorMap =
        Map.from(settingsProvider.backgroundColorMap);
    updatedBackgroundColorMap[sectionKey] = SettingsProvider.getColorFromString(colorKey);

    // Just update the map in memory, save will happen when exiting edit mode
    settingsProvider.backgroundColorMap = updatedBackgroundColorMap;
    settingsProvider.notifyListeners();
  }

  // Toggle carousel mode for a specific section
  void toggleCarouselMode(String sectionKey) {
    Map<String, bool> updatedCarouselMap =
        Map.from(settingsProvider.isCarouselMap);
    updatedCarouselMap[sectionKey] =
        !(settingsProvider.isCarouselMap[sectionKey] ?? true);

    // Just update the map in memory, save will happen when exiting edit mode
    settingsProvider.isCarouselMap = updatedCarouselMap;
    settingsProvider.notifyListeners();
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
      case 'top_left':
        selectedTopLeftImage = mediaType;
        break;
      case 'top_center':
        selectedTopCenterImage = mediaType;
        break;
      case 'top_right':
        selectedTopRightImage = mediaType;
        break;
      case 'bottom':
        selectedBottomImage = mediaType;
        break;
      case 'main':
        selectedMainImage = mediaType;
        break;
    }

    // Notify listeners (save will happen when exiting edit mode)
    settingsProvider.notifyListeners();
  }

  // Save all layout preferences
  void saveLayoutPreferences({
    double? leftMarginWidth,
    double? rightMarginWidth,
    double? bottomMarginHeight,
    double? topMarginHeight,
    double? topLeftWidth,
    double? topCenterWidth,
    double? topRightWidth,
    String? selectedLeftImage,
    String? selectedRightImage,
    String? selectedTopImage,
    String? selectedTopLeftImage,
    String? selectedTopCenterImage,
    String? selectedTopRightImage,
    String? selectedBottomImage,
    String? selectedMainImage,
    Map<String, bool>? isCarouselMap,
    Map<String, Alignment>? alignmentMap,
    Map<String, Color>? backgroundColorMap,
    Map<String, bool>? showTicker,
    Map<String, String>? tickerAlignment,
    Map<String, int>? carouselItemCount,
  }) {
    settingsProvider.saveLayoutPreferences(
      leftMarginWidth: leftMarginWidth,
      rightMarginWidth: rightMarginWidth,
      bottomMarginHeight: bottomMarginHeight,
      topMarginHeight: topMarginHeight,
      topLeftWidth: topLeftWidth,
      topCenterWidth: topCenterWidth,
      topRightWidth: topRightWidth,
      selectedLeftImage: selectedLeftImage,
      selectedRightImage: selectedRightImage,
      selectedTopImage: selectedTopImage,
      selectedTopLeftImage: selectedTopLeftImage,
      selectedTopCenterImage: selectedTopCenterImage,
      selectedTopRightImage: selectedTopRightImage,
      selectedBottomImage: selectedBottomImage,
      selectedMainImage: selectedMainImage,
      isCarouselMap: isCarouselMap,
      alignmentMap: alignmentMap,
      backgroundColorMap: backgroundColorMap,
      showTicker: showTicker,
      tickerAlignment: tickerAlignment,
      carouselItemCount: carouselItemCount,
    );
  }

  // Save all layout settings at once with robust persistence
  void saveAllLayoutSettings() {
    print("Saving all layout settings to persistent storage");
    
    // Ensure we have the latest data from settings provider where needed
    final currentIsCarouselMap = settingsProvider.isCarouselMap;
    final currentAlignmentMap = settingsProvider.alignmentMap;
    final currentBackgroundColorMap = settingsProvider.backgroundColorMap;
    final currentShowTicker = settingsProvider.showTicker;
    final currentTickerAlignment = settingsProvider.tickerAlignment;
    final currentCarouselItemCount = settingsProvider.carouselItemCount;
    
    // Call the saveLayoutPreferences method with all current settings
    settingsProvider.saveLayoutPreferences(
      leftMarginWidth: leftMarginWidth,
      rightMarginWidth: rightMarginWidth,
      topMarginHeight: topMarginHeight,
      bottomMarginHeight: bottomMarginHeight,
      topLeftWidth: topLeftWidth,
      topCenterWidth: topCenterWidth,
      topRightWidth: topRightWidth,
      selectedLeftImage: selectedLeftImage,
      selectedRightImage: selectedRightImage,
      selectedTopImage: selectedTopImage,
      selectedTopLeftImage: selectedTopLeftImage,
      selectedTopCenterImage: selectedTopCenterImage,
      selectedTopRightImage: selectedTopRightImage,
      selectedBottomImage: selectedBottomImage,
      selectedMainImage: selectedMainImage,
      isCarouselMap: currentIsCarouselMap,
      alignmentMap: currentAlignmentMap,
      backgroundColorMap: currentBackgroundColorMap,
      showTicker: currentShowTicker,
      tickerAlignment: currentTickerAlignment,
      carouselItemCount: currentCarouselItemCount,
    );
    
    // Force an immediate save to SharedPreferences
    settingsProvider.forceSave();
  }
}
