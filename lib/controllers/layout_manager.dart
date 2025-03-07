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

  LayoutManager({required this.settingsProvider})
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
            : settingsProvider.selectedMainImage {
    // Don't automatically set media types to static_image just because paths exist
    // Let the user explicitly choose media types
    
    // Log the initial media types loaded from settings
    print("Initial media types from settings:");
    print("Left: $selectedLeftImage");
    print("Right: $selectedRightImage");
    print("Top: $selectedTopImage");
    print("Bottom: $selectedBottomImage");
    print("Main: $selectedMainImage");
    print("Top Left: $selectedTopLeftImage");
    print("Top Center: $selectedTopCenterImage");
    print("Top Right: $selectedTopRightImage");
    
    // Log static image paths without changing media types
    for (var key in ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right']) {
      final path = settingsProvider.getStaticImagePath(key);
      if (path != null && path.isNotEmpty) {
        print("Static image path for $key: $path");
      }
    }
  }

  // Check if we should update based on throttle interval
  bool _shouldUpdate() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastUpdateTime > _throttleInterval) {
      _lastUpdateTime = now;
      return true;
    }
    return false;
  }

  // Debug method to print current layout settings
  void debugPrintLayoutSettings() {
    print("Current Layout Settings:");
    print("Left Section Media Type: $selectedLeftImage");
    print("Right Section Media Type: $selectedRightImage");
    print("Top Section Media Type: $selectedTopImage");
    print("Bottom Section Media Type: $selectedBottomImage");
    print("Main Section Media Type: $selectedMainImage");
    print("Top Left Section Media Type: $selectedTopLeftImage");
    print("Top Center Section Media Type: $selectedTopCenterImage");
    print("Top Right Section Media Type: $selectedTopRightImage");
    
    // Print static image paths
    for (var key in ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right']) {
      final path = settingsProvider.getStaticImagePath(key);
      if (path != null) {
        print("$key: $path");
      }
    }
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
    print('LayoutManager: Updating media type for $sectionKey to $mediaType');
    
    // Get current media type to check if we're switching from static_image
    String currentMediaType = '';
    switch (sectionKey) {
      case 'left':
        currentMediaType = selectedLeftImage;
        selectedLeftImage = mediaType;
        // Use saveLayoutPreferences instead of direct assignment
        settingsProvider.saveLayoutPreferences(selectedLeftImage: mediaType);
        break;
      case 'right':
        currentMediaType = selectedRightImage;
        selectedRightImage = mediaType;
        // Use saveLayoutPreferences instead of direct assignment
        settingsProvider.saveLayoutPreferences(selectedRightImage: mediaType);
        break;
      case 'top':
        currentMediaType = selectedTopImage;
        selectedTopImage = mediaType;
        // Use saveLayoutPreferences instead of direct assignment
        settingsProvider.saveLayoutPreferences(selectedTopImage: mediaType);
        break;
      case 'top_left':
        currentMediaType = selectedTopLeftImage;
        selectedTopLeftImage = mediaType;
        // Use saveLayoutPreferences instead of direct assignment
        settingsProvider.saveLayoutPreferences(selectedTopLeftImage: mediaType);
        break;
      case 'top_center':
        currentMediaType = selectedTopCenterImage;
        selectedTopCenterImage = mediaType;
        // Use saveLayoutPreferences instead of direct assignment
        settingsProvider.saveLayoutPreferences(selectedTopCenterImage: mediaType);
        break;
      case 'top_right':
        currentMediaType = selectedTopRightImage;
        selectedTopRightImage = mediaType;
        // Use saveLayoutPreferences instead of direct assignment
        settingsProvider.saveLayoutPreferences(selectedTopRightImage: mediaType);
        break;
      case 'bottom':
        currentMediaType = selectedBottomImage;
        selectedBottomImage = mediaType;
        // Use saveLayoutPreferences instead of direct assignment
        settingsProvider.saveLayoutPreferences(selectedBottomImage: mediaType);
        break;
      case 'main':
        currentMediaType = selectedMainImage;
        selectedMainImage = mediaType;
        // Use saveLayoutPreferences instead of direct assignment
        settingsProvider.saveLayoutPreferences(selectedMainImage: mediaType);
        break;
    }

    // If switching from static_image to another type, clear the path
    if (currentMediaType == 'static_image' && mediaType != 'static_image') {
      print('Clearing static image path for $sectionKey when switching media type from static_image to $mediaType');
      settingsProvider.clearStaticImagePath(sectionKey);
    }

    // Force an immediate save to ensure changes are persisted
    settingsProvider.forceSave();
    
    // Debug print to verify correct values in the settings provider
    print('After update in LayoutManager:');
    print('- Media type in LayoutManager for $sectionKey: $mediaType');
    print('- Media type in SettingsProvider for $sectionKey: ${_getSettingsProviderMediaType(sectionKey)}');
    
    // Notify listeners to update the UI
    settingsProvider.notifyListeners();
  }
  
  // Helper method to get the current media type from SettingsProvider based on section key
  String _getSettingsProviderMediaType(String sectionKey) {
    switch (sectionKey) {
      case 'left': return settingsProvider.selectedLeftImage;
      case 'right': return settingsProvider.selectedRightImage;
      case 'top': return settingsProvider.selectedTopImage;
      case 'top_left': return settingsProvider.selectedTopLeftImage;
      case 'top_center': return settingsProvider.selectedTopCenterImage;
      case 'top_right': return settingsProvider.selectedTopRightImage;
      case 'bottom': return settingsProvider.selectedBottomImage;
      case 'main': return settingsProvider.selectedMainImage;
      default: return 'unknown';
    }
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
    
    // Get the most up-to-date media types from the SettingsProvider
    selectedLeftImage = settingsProvider.selectedLeftImage;
    selectedRightImage = settingsProvider.selectedRightImage;
    selectedTopImage = settingsProvider.selectedTopImage;
    selectedBottomImage = settingsProvider.selectedBottomImage;
    selectedMainImage = settingsProvider.selectedMainImage;
    selectedTopLeftImage = settingsProvider.selectedTopLeftImage;
    selectedTopCenterImage = settingsProvider.selectedTopCenterImage;
    selectedTopRightImage = settingsProvider.selectedTopRightImage;
    
    // Print debug information about media types being saved
    print("Saving media types:");
    print("Left: $selectedLeftImage");
    print("Right: $selectedRightImage");
    print("Top: $selectedTopImage");
    print("Bottom: $selectedBottomImage");
    print("Main: $selectedMainImage");
    print("Top Left: $selectedTopLeftImage");
    print("Top Center: $selectedTopCenterImage");
    print("Top Right: $selectedTopRightImage");
    
    // Print static image paths but don't automatically change media types
    for (var key in ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right']) {
      final path = settingsProvider.getStaticImagePath(key);
      if (path != null && path.isNotEmpty) {
        print("Static image for $key: $path");
      }
    }
    
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
