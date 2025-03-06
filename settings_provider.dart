void setStaticImagePath(String sectionKey, String imagePath) {
  // Store in memory
  _staticImagePaths[sectionKey] = imagePath;
  
  // Save directly to SharedPreferences with a simple key
  _prefs.setString('static_image_direct_$sectionKey', imagePath);
  print("DIRECT SAVE: Static image path for $sectionKey: $imagePath");
  
  // Force save everything immediately
  forceSave();
  
  notifyListeners();
} 

Future<void> saveLayoutPreferences({
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
  Map<String, String?>? staticImagePaths,
}) async {
  final prefs = await SharedPreferences.getInstance();

  // ... (existing code for saving other settings)

  // Save static image paths
  if (staticImagePaths != null) {
    for (var entry in staticImagePaths.entries) {
      if (entry.value != null) {
        await prefs.setString('static_image_direct_${entry.key}', entry.value!);
      }
    }
  }

  // ... (existing code for saving other settings)

  // Also call _saveData to ensure everything is saved
  await _saveData();

  notifyListeners();
} 

Future<void> _initializeSettings() async {
  _prefs = await SharedPreferences.getInstance();
  
  // ... (existing code for loading other settings)

  // Load static image paths directly from individual keys
  final List<String> sectionKeys = ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right'];
  for (var key in sectionKeys) {
    // Try direct key first
    String? directPath = _prefs.getString('static_image_direct_$key');
    
    // If not found, try older key formats for backward compatibility
    if (directPath.isEmpty) {
      directPath = _prefs.getString('static_image_$key');
    }
    if (directPath.isEmpty) {
      directPath = _prefs.getString('static_image_path_$key');
    }
    
    if (directPath.isNotEmpty) {
      _staticImagePaths[key] = directPath;
      print("Loaded static image path for $key: $directPath");
      
      // Also save with the new direct key format to ensure future compatibility
      _prefs.setString('static_image_direct_$key', directPath);
      
      // Set the media type to 'static_image' if a static image path exists
      switch (key) {
        case 'left':
          _selectedLeftImage = 'static_image';
          break;
        case 'right':
          _selectedRightImage = 'static_image';
          break;
        case 'top':
          _selectedTopImage = 'static_image';
          break;
        case 'top_left':
          _selectedTopLeftImage = 'static_image';
          break;
        case 'top_center':
          _selectedTopCenterImage = 'static_image';
          break;
        case 'top_right':
          _selectedTopRightImage = 'static_image';
          break;
        case 'bottom':
          _selectedBottomImage = 'static_image';
          break;
        case 'main':
          _selectedMainImage = 'static_image';
          break;
      }
    }
  }
  
  // ... (existing code for loading other settings)

  notifyListeners();
} 

String? getStaticImagePath(String sectionKey) {
  // First try to get from direct key
  String? path = _prefs.getString('static_image_direct_$sectionKey');
  
  // If not found with direct key, try the map
  if (path.isEmpty) {
    path = _staticImagePaths[sectionKey];
  }
  
  // If found in direct key but not in map, update the map
  if (path.isNotEmpty && _staticImagePaths[sectionKey] != path) {
    _staticImagePaths[sectionKey] = path;
    print("Using direct static image path for $sectionKey: $path");
  }
  
  return path;
} 