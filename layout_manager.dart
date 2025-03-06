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

  // Check if the mediaType is 'static_image'
  if (mediaType == 'static_image') {
    // Use the getStaticImagePath method to get the current path
    String? currentPath = settingsProvider.getStaticImagePath(sectionKey);
    // If there's no current path, set it to a default value or prompt the user to select one
    if (currentPath.isEmpty) {
      // Here you might want to show a dialog to select an image
      // For now, we'll set it to a default path
      settingsProvider.setStaticImagePath(sectionKey, 'default_static_image_path');
    }
    // Set the media type to 'static_image' when a static image is selected
    switch (sectionKey) {
      case 'left':
        selectedLeftImage = 'static_image';
        break;
      case 'right':
        selectedRightImage = 'static_image';
        break;
      case 'top':
        selectedTopImage = 'static_image';
        break;
      case 'top_left':
        selectedTopLeftImage = 'static_image';
        break;
      case 'top_center':
        selectedTopCenterImage = 'static_image';
        break;
      case 'top_right':
        selectedTopRightImage = 'static_image';
        break;
      case 'bottom':
        selectedBottomImage = 'static_image';
        break;
      case 'main':
        selectedMainImage = 'static_image';
        break;
    }
  }

  // Notify listeners (save will happen when exiting edit mode)
  settingsProvider.notifyListeners();
}

void saveAllLayoutSettings() {
  print("Saving all layout settings to persistent storage");
  
  // ... (existing code for saving media types and other settings)

  // Save static image paths
  print("Saving static image paths:");
  Map<String, String?> staticImagePaths = {};
  for (var key in ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right']) {
    final path = settingsProvider.getStaticImagePath(key);
    if (path != null) {
      print("$key: $path");
      staticImagePaths[key] = path;
      
      // If a static image path exists, set the media type to 'static_image'
      if (path.isNotEmpty) {
        switch (key) {
          case 'left':
            selectedLeftImage = 'static_image';
            break;
          case 'right':
            selectedRightImage = 'static_image';
            break;
          case 'top':
            selectedTopImage = 'static_image';
            break;
          case 'top_left':
            selectedTopLeftImage = 'static_image';
            break;
          case 'top_center':
            selectedTopCenterImage = 'static_image';
            break;
          case 'top_right':
            selectedTopRightImage = 'static_image';
            break;
          case 'bottom':
            selectedBottomImage = 'static_image';
            break;
          case 'main':
            selectedMainImage = 'static_image';
            break;
        }
      }
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
    staticImagePaths: staticImagePaths,
  );
  
  // Force an immediate save to SharedPreferences
  settingsProvider.forceSave();
  
  // Print confirmation
  print("Layout settings saved successfully");
}

LayoutManager({required this.settingsProvider})
    : leftMarginWidth = settingsProvider.leftMarginWidth,
      rightMarginWidth = settingsProvider.rightMarginWidth,
      topMarginHeight = settingsProvider.topMarginHeight,
      bottomMarginHeight = settingsProvider.bottomMarginHeight,
      topLeftWidth = settingsProvider.topLeftWidth,
      topCenterWidth = settingsProvider.topCenterWidth,
      topRightWidth = settingsProvider.topRightWidth,
      selectedLeftImage = settingsProvider.selectedLeftImage,
      selectedRightImage = settingsProvider.selectedRightImage,
      selectedTopImage = settingsProvider.selectedTopImage,
      selectedTopLeftImage = settingsProvider.selectedTopLeftImage,
      selectedTopCenterImage = settingsProvider.selectedTopCenterImage,
      selectedTopRightImage = settingsProvider.selectedTopRightImage,
      selectedBottomImage = settingsProvider.selectedBottomImage,
      selectedMainImage = settingsProvider.selectedMainImage {
  // Print debug information about loaded media types
  print("LayoutManager initialized with the following media types:");
  print("Left: $selectedLeftImage");
  print("Right: $selectedRightImage");
  print("Top: $selectedTopImage");
  print("Bottom: $selectedBottomImage");
  print("Main: $selectedMainImage");
  print("Top Left: $selectedTopLeftImage");
  print("Top Center: $selectedTopCenterImage");
  print("Top Right: $selectedTopRightImage");
  
  // Print static image paths
  print("Static Image Paths:");
  for (var key in ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right']) {
    final path = settingsProvider.getStaticImagePath(key);
    if (path != null) {
      print("$key: $path");
    }
  }
} 