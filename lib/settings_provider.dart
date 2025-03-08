import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/game_config.dart';
import 'utils/logger.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _gamesKey = 'games';
  static const String _parentFolderPathKey = 'parentFolderPath';
  static const String _gamesFolderPathKey = 'gamesFolderPath';
  static const String _mediaFolderPathKey = 'mediaFolderPath';
  static const String _leftMarginWidthKey = 'leftMarginWidth';
  static const String _rightMarginWidthKey = 'rightMarginWidth';
  static const String _bottomMarginHeightKey = 'bottomMarginHeight';
  static const String _selectedLeftImageKey = 'selectedLeftImage';
  static const String _selectedBottomImageKey = 'selectedBottomImage';
  static const String _selectedRightImageKey = 'selectedRightImage';
  static const String _topMarginHeightKey = 'topMarginHeight';
  static const String _selectedTopImageKey = 'selectedTopImage';
  static const String _selectedMainImageKey = 'selectedMainImage';
  static const String _showTickerKey = 'showTicker';
  static const String _tickerAlignmentKey = 'tickerAlignment';
  static const String _tickerSpeedKey = 'tickerSpeed';
  static const String _topLeftWidthKey = 'topLeftWidth';
  static const String _topCenterWidthKey = 'topCenterWidth';
  static const String _topRightWidthKey = 'topRightWidth';
  static const String _selectedTopLeftImageKey = 'selectedTopLeftImage';
  static const String _selectedTopCenterImageKey = 'selectedTopCenterImage';
  static const String _selectedTopRightImageKey = 'selectedTopRightImage';
  static const String _carouselItemCountKey = 'carouselItemCount';

  // Media subfolder paths relative to parent folder
  static const String mediaRootFolder = 'medium_artwork';
  static const String romsFolder = 'roms';
  static const String logoFolder = 'logo';
  static const String artworkFrontFolder = 'artwork_front';
  static const String artwork3dFolder = 'artwork_3d';
  static const String fanartFolder = 'fanart';
  static const String videoFolder = 'video';
  static const String mediumDiscFolder = 'medium_disc';

  // Add media type constants for our new widgets
  static const String staticImageWidgetType = 'static_image_widget';
  static const String transparentWidgetType = 'transparent';

  // Valid media types for layout positions (including all available types)
  static const List<String> validLayoutMedia = [
    'logo',
    'artwork_front',
    'artwork_3d',
    'fanart',
    'video',
    'story',
    'medium_disc',
    'static_image',
    staticImageWidgetType,
    transparentWidgetType,
  ];

  late SharedPreferences _prefs;
  List<GameConfig> _games = [];

  String? _parentFolderPath;
  String? get parentFolderPath => _parentFolderPath;
  
  String get effectiveMediaFolderPath => _parentFolderPath != null 
    ? '$_parentFolderPath/$mediaRootFolder' 
    : _mediaFolderPath ?? '';
    
  String get effectiveGamesFolderPath => _parentFolderPath != null 
    ? '$_parentFolderPath/$romsFolder' 
    : _gamesFolderPath ?? '';

  String? _gamesFolderPath;
  String? _mediaFolderPath;
  final Map<String, String> _gameExecutables = {};
  final Map<String, String> _gameLogoPaths = {};
  final Map<String, String> _gameVideoPaths = {};
  final Map<String, String> _gameBannerPaths = {};

  double _leftMarginWidth = 200;
  double _rightMarginWidth = 200;
  double _bottomMarginHeight = 120;
  double _topMarginHeight = 120;
  String _selectedLeftImage = 'logo';
  String _selectedBottomImage = 'logo';
  String _selectedRightImage = 'logo';
  String _selectedTopImage = 'logo';
  String _selectedMainImage = 'video';

  // Top section dimensions and media types
  double _topLeftWidth = 200;
  double _topCenterWidth = 200;
  double _topRightWidth = 200;
  String _selectedTopLeftImage = 'logo';
  String _selectedTopCenterImage = 'logo';
  String _selectedTopRightImage = 'logo';

  // Carousel mode preferences (defaults to carousel)
  Map<String, bool> _isCarouselMap = {
    'left': true,
    'right': true,
    'top': true,
    'bottom': true,
    'main': true,
  };

  // Alignment preferences (defaults to center)
  Map<String, Alignment> _alignmentMap = {
    'left': Alignment.centerLeft,
    'right': Alignment.centerRight,
    'top': Alignment.topCenter,
    'bottom': Alignment.bottomCenter,
    'main': Alignment.center,
  };

  // Background color preferences (defaults to black45)
  Map<String, Color> _backgroundColorMap = {
    'left': Colors.black45,
    'right': Colors.black45,
    'top': Colors.black45,
    'bottom': Colors.black45,
    'main': Colors.black45,
  };

  // List of available background colors
  static const Map<String, Color> availableBackgroundColors = {
    'black45': Colors.black45,
    'black87': Colors.black87,
    'blue900': Color(0xFF0D47A1), // Deep Blue
    'green900': Color(0xFF1B5E20), // Deep Green
    'red900': Color(0xFFB71C1C), // Deep Red
    'purple900': Color(0xFF4A148C), // Deep Purple
    'amber900': Color(0xFFFF6F00), // Deep Amber
    'grey900': Color(0xFF212121), // Deep Grey
  };

  Map<String, bool> _showTicker = {};
  Map<String, String> _tickerAlignment = {};
  Map<String, double> _tickerSpeed = {};
  Map<String, int> _carouselItemCount = {};

  // Story text markers
  static const String storyStartMarker = "[STORY_START]";
  static const String storyEndMarker = "[STORY_END]";

  // Helper method to format story text with markers
  String formatStoryText(String text) {
    return "$storyStartMarker\n$text\n$storyEndMarker";
  }

  // Helper method to extract story text between markers
  String extractStoryText(String text) {
    final startIndex = text.indexOf(storyStartMarker);
    final endIndex = text.indexOf(storyEndMarker);
    if (startIndex != -1 && endIndex != -1) {
      return text.substring(startIndex + storyStartMarker.length, endIndex).trim();
    }
    return text;
  }

  // Getters
  String? get gamesFolderPath => _gamesFolderPath;
  String? get mediaFolderPath => _mediaFolderPath;
  List<GameConfig> get games => List.unmodifiable(_games);
  bool get hasConfiguredGames => _games.isNotEmpty;
  Map<String, String> get gameExecutables => Map.unmodifiable(_gameExecutables);
  Map<String, String> get gameLogoPaths => Map.unmodifiable(_gameLogoPaths);
  Map<String, String> get gameVideoPaths => Map.unmodifiable(_gameVideoPaths);
  Map<String, String> get gameBannerPaths => Map.unmodifiable(_gameBannerPaths);

  double get leftMarginWidth => _leftMarginWidth;
  double get rightMarginWidth => _rightMarginWidth;
  double get bottomMarginHeight => _bottomMarginHeight;
  double get topMarginHeight => _topMarginHeight;
  String get selectedLeftImage => _selectedLeftImage;
  String get selectedBottomImage => _selectedBottomImage;
  String get selectedRightImage => _selectedRightImage;
  String get selectedTopImage => _selectedTopImage;
  String get selectedMainImage => _selectedMainImage;
  Map<String, bool> get isCarouselMap => _isCarouselMap;
  set isCarouselMap(Map<String, bool> value) {
    _isCarouselMap = value;
    _saveData();
  }
  
  Map<String, Alignment> get alignmentMap => _alignmentMap;
  set alignmentMap(Map<String, Alignment> value) {
    _alignmentMap = value;
    _saveData();
  }
  
  Map<String, Color> get backgroundColorMap => _backgroundColorMap;
  set backgroundColorMap(Map<String, Color> value) {
    _backgroundColorMap = value;
    _saveData();
  }

  // Getters for ticker settings
  Map<String, bool> get showTicker => Map<String, bool>.from(_showTicker);
  set showTicker(Map<String, bool> value) {
    _showTicker = value;
    _saveData();
  }
  
  Map<String, String> get tickerAlignment => Map<String, String>.from(_tickerAlignment);
  set tickerAlignment(Map<String, String> value) {
    _tickerAlignment = value;
    _saveData();
  }
  
  Map<String, double> get tickerSpeed => Map<String, double>.from(_tickerSpeed);
  Map<String, int> get carouselItemCount => Map<String, int>.from(_carouselItemCount);
  set carouselItemCount(Map<String, int> value) {
    _carouselItemCount = value;
    _saveData();
  }

  // Default ticker settings
  static const defaultTickerSpeed = 50.0;
  static const List<String> validTickerAlignments = ['top', 'bottom'];
  static const int defaultCarouselItemCount = 3;

  // Getters for top section settings
  double get topLeftWidth => _topLeftWidth;
  double get topCenterWidth => _topCenterWidth;
  double get topRightWidth => _topRightWidth;
  String get selectedTopLeftImage => _selectedTopLeftImage;
  String get selectedTopCenterImage => _selectedTopCenterImage;
  String get selectedTopRightImage => _selectedTopRightImage;

  // Convert color string to Color object
  static Color getColorFromString(String colorString) {
    return availableBackgroundColors[colorString] ?? Colors.black45;
  }

  // Add a map to store static image paths
  final Map<String, String> _staticImagePaths = {};
  
  // Add a map to store video aspect ratios
  final Map<String, double> _videoAspectRatios = {};

  // Background image path
  String? _backgroundImagePath;
  String? get backgroundImagePath => _backgroundImagePath;
  
  // Method to set background image path
  void setBackgroundImagePath(String? imagePath) {
    _backgroundImagePath = imagePath;
    
    // Save directly to SharedPreferences for immediate persistence
    _saveBackgroundImagePathDirectly(imagePath);
    
    // Force save all settings to ensure everything is persisted
    forceSave();
    
    // Notify listeners
    notifyListeners();
  }
  
  // Save the background image path directly to SharedPreferences
  Future<void> _saveBackgroundImagePathDirectly(String? imagePath) async {
    final key = 'background_image_path';
    if (imagePath != null) {
      await _prefs.setString(key, imagePath);
    } else {
      await _prefs.remove(key);
    }
  }
  
  // Load the background image path from SharedPreferences
  Future<void> _loadBackgroundImagePath() async {
    final key = 'background_image_path';
    _backgroundImagePath = _prefs.getString(key);
  }

  // Method to set static image path
  void setStaticImagePath(String sectionKey, String? imagePath) {
    if (imagePath != null) {
      _staticImagePaths[sectionKey] = imagePath;
    } else {
      _staticImagePaths.remove(sectionKey);
    }
    
    // Save directly to SharedPreferences for immediate persistence
    _saveStaticImagePathDirectly(sectionKey, imagePath);
    
    // Force save all settings to ensure everything is persisted
    forceSave();
    
    // Notify listeners
    notifyListeners();
  }
  
  // Save a static image path directly to SharedPreferences
  Future<void> _saveStaticImagePathDirectly(String sectionKey, String? imagePath) async {
    final key = 'static_image_path_$sectionKey';
    if (imagePath != null) {
      await _prefs.setString(key, imagePath);
    } else {
      await _prefs.remove(key);
    }
  }
  
  // Get a static image path for a specific section
  String? getStaticImagePath(String sectionKey) {
    final path = _staticImagePaths[sectionKey];
    return path;
  }
  
  // Clear a static image path for a specific section
  void clearStaticImagePath(String sectionKey) {
    debugPrint('Clearing static image path for section: $sectionKey');
    // This will remove the path from the map and also from SharedPreferences
    setStaticImagePath(sectionKey, null);
  }
  
  // Set a video aspect ratio for a specific section
  void setVideoAspectRatio(String sectionKey, double aspectRatio) {
    _videoAspectRatios[sectionKey] = aspectRatio;
    
    // Save directly to SharedPreferences for immediate persistence
    _saveVideoAspectRatioDirectly(sectionKey, aspectRatio);
    
    // Notify listeners
    notifyListeners();
  }
  
  // Save a video aspect ratio directly to SharedPreferences
  Future<void> _saveVideoAspectRatioDirectly(String sectionKey, double aspectRatio) async {
    final key = 'video_aspect_ratio_$sectionKey';
    await _prefs.setDouble(key, aspectRatio);
  }
  
  // Get a video aspect ratio for a specific section
  double? getVideoAspectRatio(String sectionKey) {
    final ratio = _videoAspectRatios[sectionKey];
    return ratio;
  }
  
  // Reset a video aspect ratio for a specific section
  void resetVideoAspectRatio(String sectionKey) {
    _videoAspectRatios.remove(sectionKey);
    
    // Remove directly from SharedPreferences for immediate persistence
    _removeVideoAspectRatioDirectly(sectionKey);
    
    // Notify listeners
    notifyListeners();
  }
  
  // Remove a video aspect ratio directly from SharedPreferences
  Future<void> _removeVideoAspectRatioDirectly(String sectionKey) async {
    final key = 'video_aspect_ratio_$sectionKey';
    await _prefs.remove(key);
  }

  // Add a setting for enabling/disabling glass effect
  bool _useGlassEffect = false;
  bool get useGlassEffect => _useGlassEffect;

  // Method to toggle glass effect
  void toggleGlassEffect() {
    _useGlassEffect = !_useGlassEffect;
    _saveUseGlassEffectPreference();
    notifyListeners();
  }

  // Method to set glass effect
  void setGlassEffect(bool enabled) {
    _useGlassEffect = enabled;
    _saveUseGlassEffectPreference();
    notifyListeners();
  }

  // Save glass effect preference to SharedPreferences
  Future<void> _saveUseGlassEffectPreference() async {
    await _prefs.setBool('use_glass_effect', _useGlassEffect);
    Logger.debug('Saved glass effect preference: $_useGlassEffect', source: 'SettingsProvider');
  }

  // Load glass effect preference from SharedPreferences
  void _loadUseGlassEffectPreference() {
    _useGlassEffect = _prefs.getBool('use_glass_effect') ?? false;
    Logger.debug('Loaded glass effect preference: $_useGlassEffect', source: 'SettingsProvider');
  }

  // Constructor
  SettingsProvider() {
    _initializeSettings();
  }

  // Initialize settings
  Future<void> _initializeSettings() async {
    debugPrint('Initializing settings provider');
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved paths
    _parentFolderPath = _prefs.getString(_parentFolderPathKey);
    _gamesFolderPath = _prefs.getString(_gamesFolderPathKey);
    _mediaFolderPath = _prefs.getString(_mediaFolderPathKey);
    debugPrint('Loaded paths: parent=$_parentFolderPath, games=$_gamesFolderPath, media=$_mediaFolderPath');
    
    // Load static image paths using our enhanced loading method
    await reloadStaticImagePaths();
    
    // Load video aspect ratios using our enhanced loading method
    await reloadVideoAspectRatios();
    
    // Load background image path
    await _loadBackgroundImagePath();
    
    // Load selected game indices
    await loadSelectedGameIndices();
    
    // Don't automatically set media types to static_image - let the user choose
    // We'll still load the static image paths, but we won't override the saved media types
    
    // Load media types from saved preferences
    _selectedLeftImage = _prefs.getString(_selectedLeftImageKey) ?? 'logo';
    _selectedRightImage = _prefs.getString(_selectedRightImageKey) ?? 'logo';
    _selectedTopImage = _prefs.getString(_selectedTopImageKey) ?? 'logo';
    _selectedBottomImage = _prefs.getString(_selectedBottomImageKey) ?? 'logo';
    _selectedMainImage = _prefs.getString(_selectedMainImageKey) ?? 'video';
    _selectedTopLeftImage = _prefs.getString(_selectedTopLeftImageKey) ?? 'logo';
    _selectedTopCenterImage = _prefs.getString(_selectedTopCenterImageKey) ?? 'logo';
    _selectedTopRightImage = _prefs.getString(_selectedTopRightImageKey) ?? 'logo';
    
    // Load margin dimensions
    _leftMarginWidth = _prefs.getDouble(_leftMarginWidthKey) ?? 200;
    _rightMarginWidth = _prefs.getDouble(_rightMarginWidthKey) ?? 200;
    _bottomMarginHeight = _prefs.getDouble(_bottomMarginHeightKey) ?? 120;
    _topMarginHeight = _prefs.getDouble(_topMarginHeightKey) ?? 120;
    
    // Load top section dimensions and media types
    _topLeftWidth = _prefs.getDouble(_topLeftWidthKey) ?? 200;
    _topCenterWidth = _prefs.getDouble(_topCenterWidthKey) ?? 200;
    _topRightWidth = _prefs.getDouble(_topRightWidthKey) ?? 200;
    
    // Initialize default ticker settings if not already set
    final String? showTickerJson = _prefs.getString(_showTickerKey);
    if (showTickerJson == null) {
      _showTicker = {
        'left': false,
        'right': false,
        'top': false,
        'bottom': false,
        'main': false,
      };
      await _prefs.setString(_showTickerKey, json.encode(_showTicker));
    }

    final String? tickerAlignmentJson = _prefs.getString(_tickerAlignmentKey);
    if (tickerAlignmentJson == null) {
      _tickerAlignment = {
        'left': 'bottom',
        'right': 'bottom',
        'top': 'bottom',
        'bottom': 'bottom',
        'main': 'bottom',
      };
      await _prefs.setString(_tickerAlignmentKey, json.encode(_tickerAlignment));
    }

    final String? tickerSpeedJson = _prefs.getString(_tickerSpeedKey);
    if (tickerSpeedJson == null) {
      _tickerSpeed = {
        'left': defaultTickerSpeed,
        'right': defaultTickerSpeed,
        'top': defaultTickerSpeed,
        'bottom': defaultTickerSpeed,
        'main': defaultTickerSpeed,
      };
      await _prefs.setString(_tickerSpeedKey, json.encode(_tickerSpeed));
    }

    // Load all maps
    await _loadMaps();

    // Load games
    final String? gamesJson = _prefs.getString(_gamesKey);
    if (gamesJson != null) {
      final List<dynamic> gamesData = json.decode(gamesJson);
      _games = gamesData.map((gameData) => GameConfig(
        name: gameData['name'],
        executablePath: gameData['executablePath'],
        logoPath: gameData['logoPath'] ?? '',
        videoPath: gameData['videoPath'] ?? '',
        storyText: gameData['storyText'] ?? '',
        bannerPath: gameData['bannerPath'] ?? '',
      )).toList();

      // Update maps for backward compatibility
      for (var game in _games) {
        _gameExecutables[game.name] = game.executablePath;
        if (game.logoPath.isNotEmpty) _gameLogoPaths[game.name] = game.logoPath;
        if (game.videoPath.isNotEmpty) _gameVideoPaths[game.name] = game.videoPath;
        if (game.bannerPath.isNotEmpty) _gameBannerPaths[game.name] = game.bannerPath;
      }
    }

    _loadUseGlassEffectPreference();

    notifyListeners();
  }

  // Setters
  void setParentFolderPath(String? path) {
    _parentFolderPath = path;
    if (path != null) {
      // When parent path is set, derive media and games paths from it
      _mediaFolderPath = '$path/$mediaRootFolder';
      _gamesFolderPath = '$path/$romsFolder';
    }
    _saveData();
    notifyListeners();
  }

  void setGamesFolderPath(String? path) {
    _gamesFolderPath = path;
    _saveData();
    notifyListeners();
  }

  void setMediaFolderPath(String? path) {
    _mediaFolderPath = path;
    _saveData();
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
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Only update values that are provided, keep existing values otherwise
    if (leftMarginWidth != null) _leftMarginWidth = leftMarginWidth;
    if (rightMarginWidth != null) _rightMarginWidth = rightMarginWidth;
    if (bottomMarginHeight != null) _bottomMarginHeight = bottomMarginHeight;
    if (topMarginHeight != null) _topMarginHeight = topMarginHeight;
    if (topLeftWidth != null) _topLeftWidth = topLeftWidth;
    if (topCenterWidth != null) _topCenterWidth = topCenterWidth;
    if (topRightWidth != null) _topRightWidth = topRightWidth;
    
    // Update media type selections only if provided
    if (selectedLeftImage != null) _selectedLeftImage = selectedLeftImage;
    if (selectedRightImage != null) _selectedRightImage = selectedRightImage;
    if (selectedTopImage != null) _selectedTopImage = selectedTopImage;
    if (selectedTopLeftImage != null) _selectedTopLeftImage = selectedTopLeftImage;
    if (selectedTopCenterImage != null) _selectedTopCenterImage = selectedTopCenterImage;
    if (selectedTopRightImage != null) _selectedTopRightImage = selectedTopRightImage;
    if (selectedBottomImage != null) _selectedBottomImage = selectedBottomImage;
    if (selectedMainImage != null) _selectedMainImage = selectedMainImage;

    // Update maps only if provided, otherwise keep existing values
    if (isCarouselMap != null) {
      _isCarouselMap = Map<String, bool>.from(isCarouselMap);
    }
    if (alignmentMap != null) {
      _alignmentMap = Map<String, Alignment>.from(alignmentMap);
    }
    if (backgroundColorMap != null) {
      _backgroundColorMap = Map<String, Color>.from(backgroundColorMap);
    }
    if (showTicker != null) {
      _showTicker = Map<String, bool>.from(showTicker);
    }
    if (tickerAlignment != null) {
      _tickerAlignment = Map<String, String>.from(tickerAlignment);
    }
    if (carouselItemCount != null) {
      _carouselItemCount = Map<String, int>.from(carouselItemCount);
    }

    // Save all values to SharedPreferences
    await prefs.setDouble('leftMarginWidth', _leftMarginWidth);
    await prefs.setDouble('rightMarginWidth', _rightMarginWidth);
    await prefs.setDouble('bottomMarginHeight', _bottomMarginHeight);
    await prefs.setDouble('topMarginHeight', _topMarginHeight);
    
    // Save top section dimensions
    await prefs.setDouble(_topLeftWidthKey, _topLeftWidth);
    await prefs.setDouble(_topCenterWidthKey, _topCenterWidth);
    await prefs.setDouble(_topRightWidthKey, _topRightWidth);
    
    await prefs.setString('selectedLeftImage', _selectedLeftImage);
    await prefs.setString('selectedRightImage', _selectedRightImage);
    await prefs.setString('selectedTopImage', _selectedTopImage);
    await prefs.setString('selectedTopLeftImage', _selectedTopLeftImage);
    await prefs.setString('selectedTopCenterImage', _selectedTopCenterImage);
    await prefs.setString('selectedTopRightImage', _selectedTopRightImage);
    await prefs.setString('selectedBottomImage', _selectedBottomImage);
    await prefs.setString('selectedMainImage', _selectedMainImage);

    // Save maps as JSON strings
    await prefs.setString('isCarouselMap', jsonEncode(_isCarouselMap.map((key, value) => MapEntry(key, value))));
    await prefs.setString('alignmentMap', jsonEncode(_alignmentMap.map((key, value) => MapEntry(key, value.toString()))));
    await prefs.setString('backgroundColorMap', jsonEncode(_backgroundColorMap.map((key, value) => MapEntry(key, value.value))));
    await prefs.setString('showTicker', jsonEncode(_showTicker));
    await prefs.setString('tickerAlignment', jsonEncode(_tickerAlignment));

    // Save carousel item count
    await prefs.setString(_carouselItemCountKey, json.encode(_carouselItemCount));
    
    // Also call _saveData to ensure everything is saved
    await _saveData();

    notifyListeners();
  }

  // Game management methods
  void addGame(GameConfig game) {
    // Prevent duplicate games by name
    if (_games.any((existingGame) => existingGame.name == game.name)) {
      throw Exception('A game with the name "${game.name}" already exists.');
    }
    _games.add(game);

    // Update the maps for backward compatibility
    _gameExecutables[game.name] = game.executablePath;
    if (game.logoPath.isNotEmpty) _gameLogoPaths[game.name] = game.logoPath;
    if (game.videoPath.isNotEmpty) _gameVideoPaths[game.name] = game.videoPath;
    if (game.bannerPath.isNotEmpty) {
      _gameBannerPaths[game.name] = game.bannerPath;
    }

    _saveData();
    notifyListeners();
  }

  void updateGame(int index, GameConfig game) {
    if (index >= 0 && index < _games.length) {
      final oldGame = _games[index];
      _games[index] = game;

      // Update the maps for backward compatibility
      _gameExecutables.remove(oldGame.name);
      _gameLogoPaths.remove(oldGame.name);
      _gameVideoPaths.remove(oldGame.name);
      _gameBannerPaths.remove(oldGame.name);

      _gameExecutables[game.name] = game.executablePath;
      if (game.logoPath.isNotEmpty) _gameLogoPaths[game.name] = game.logoPath;
      if (game.videoPath.isNotEmpty) _gameVideoPaths[game.name] = game.videoPath;
      if (game.bannerPath.isNotEmpty) _gameBannerPaths[game.name] = game.bannerPath;

      _saveData();
      notifyListeners();
    }
  }

  void removeGame(int index) {
    if (index >= 0 && index < _games.length) {
      final game = _games[index];
      _games.removeAt(index);

      // Clean up the maps
      _gameExecutables.remove(game.name);
      _gameLogoPaths.remove(game.name);
      _gameVideoPaths.remove(game.name);
      _gameBannerPaths.remove(game.name);

      _saveData();
      notifyListeners();
    }
  }

  // Delete game
  void deleteGame(int index) {
    if (index >= 0 && index < _games.length) {
      final game = _games[index];
      _games.removeAt(index);

      // Clean up the maps when deleting
      _gameExecutables.remove(game.name);
      _gameLogoPaths.remove(game.name);
      _gameVideoPaths.remove(game.name);
      _gameBannerPaths.remove(game.name);

      _saveData();
      notifyListeners();
    }
  }

  // Delete game by name
  void deleteGameByName(String gameName) {
    final index = _games.indexWhere((game) => game.name == gameName);
    if (index != -1) {
      deleteGame(index);
    }
  }

  // Game path management methods
  void setGameExecutable(String gameName, String executablePath) {
    _gameExecutables[gameName] = executablePath;
    notifyListeners();
  }

  void setGameLogoPath(String gameName, String logoPath) {
    _gameLogoPaths[gameName] = _getMediaPath(gameName, MediaType.logo);
    notifyListeners();
  }

  void setGameVideoPath(String gameName, String videoPath) {
    _gameVideoPaths[gameName] = _getMediaPath(gameName, MediaType.video);
    notifyListeners();
  }

  void setGameBannerPath(String gameName, String bannerPath) {
    _gameBannerPaths[gameName] = _getMediaPath(gameName, MediaType.banner);
    notifyListeners();
  }

  void removeGameExecutable(String gameName) {
    _gameExecutables.remove(gameName);
    _gameLogoPaths.remove(gameName);
    _gameVideoPaths.remove(gameName);
    _gameBannerPaths.remove(gameName);
    notifyListeners();
  }

  GameConfig? getGame(int index) {
    if (index >= 0 && index < _games.length) {
      return _games[index];
    }
    return null;
  }

  // Drag and drop file handling
  bool handleDroppedExecutable(String gameName, String filePath) {
    if (_isExecutableFile(filePath)) {
      // Find the game in the list and update it
      final gameIndex = _games.indexWhere((game) => game.name == gameName);
      if (gameIndex != -1) {
        final updatedGame = GameConfig(
          name: _games[gameIndex].name,
          executablePath: filePath,
          logoPath: _games[gameIndex].logoPath,
          videoPath: _games[gameIndex].videoPath,
          storyText: _games[gameIndex].storyText,
          bannerPath: _games[gameIndex].bannerPath,
        );
        updateGame(gameIndex, updatedGame);
      } else {
        // Just update the map if game not found in list
        setGameExecutable(gameName, filePath);
        _saveData();
      }
      return true;
    }
    return false;
  }

  bool handleDroppedImage(String gameName, String filePath, ImageType type) {
    if (_isImageFile(filePath) || _isVideoFile(filePath)) {
      final gameIndex = _games.indexWhere((game) => game.name == gameName);
      if (gameIndex != -1) {
        GameConfig updatedGame;
        switch (type) {
          case ImageType.logo:
            updatedGame = GameConfig(
              name: _games[gameIndex].name,
              executablePath: _games[gameIndex].executablePath,
              logoPath: filePath,
              videoPath: _games[gameIndex].videoPath,
              storyText: _games[gameIndex].storyText,
              bannerPath: _games[gameIndex].bannerPath,
            );
            break;
          case ImageType.video:
            updatedGame = GameConfig(
              name: _games[gameIndex].name,
              executablePath: _games[gameIndex].executablePath,
              logoPath: _games[gameIndex].logoPath,
              videoPath: filePath,
              storyText: _games[gameIndex].storyText,
              bannerPath: _games[gameIndex].bannerPath,
            );
            break;
          case ImageType.story:
            updatedGame = GameConfig(
              name: _games[gameIndex].name,
              executablePath: _games[gameIndex].executablePath,
              logoPath: _games[gameIndex].logoPath,
              videoPath: _games[gameIndex].videoPath,
              storyText: filePath,
              bannerPath: _games[gameIndex].bannerPath,
            );
            break;
          case ImageType.banner:
            updatedGame = GameConfig(
              name: _games[gameIndex].name,
              executablePath: _games[gameIndex].executablePath,
              logoPath: _games[gameIndex].logoPath,
              videoPath: _games[gameIndex].videoPath,
              storyText: _games[gameIndex].storyText,
              bannerPath: filePath,
            );
            break;
        }
        updateGame(gameIndex, updatedGame);
      } else {
        // Update the specific map if game not found in list
        switch (type) {
          case ImageType.logo:
            setGameLogoPath(gameName, filePath);
            break;
          case ImageType.video:
            setGameVideoPath(gameName, filePath);
            break;
          case ImageType.story:
            // storyText is not set in handleDroppedImage
            break;
          case ImageType.banner:
            setGameBannerPath(gameName, filePath);
            break;
        }
        _saveData();
      }
      return true;
    }
    return false;
  }

  // Utility methods to validate file types
  bool _isExecutableFile(String filePath) {
    final lowercasePath = filePath.toLowerCase();
    return lowercasePath.endsWith('.exe') ||
        lowercasePath.endsWith('.bat') ||
        lowercasePath.endsWith('.cmd') ||
        lowercasePath.endsWith('.lnk');
  }

  bool _isImageFile(String filePath) {
    final lowercasePath = filePath.toLowerCase();
    return lowercasePath.endsWith('.jpg') ||
        lowercasePath.endsWith('.jpeg') ||
        lowercasePath.endsWith('.png') ||
        lowercasePath.endsWith('.gif') ||
        lowercasePath.endsWith('.webp') ||
        lowercasePath.endsWith('.bmp');
  }

  bool _isVideoFile(String filePath) {
    final lowercasePath = filePath.toLowerCase();
    return lowercasePath.endsWith('.mp4') ||
        lowercasePath.endsWith('.webm') ||
        lowercasePath.endsWith('.mov') ||
        lowercasePath.endsWith('.avi') ||
        lowercasePath.endsWith('.mkv') ||
        lowercasePath.endsWith('.wmv');
  }

  // Get the expected file path for different media types
  String _getMediaPath(String gameName, MediaType type) {
    final mediaFolder = effectiveMediaFolderPath;
    if (mediaFolder.isEmpty) return '';

    switch (type) {
      case MediaType.logo:
        return '$mediaFolder/$logoFolder/$gameName.png';
      case MediaType.artwork_front:
        return '$mediaFolder/$artworkFrontFolder/$gameName.png';
      case MediaType.artwork_3d:
        return '$mediaFolder/$artwork3dFolder/$gameName.png';
      case MediaType.fanart:
        return '$mediaFolder/$fanartFolder/$gameName.jpg';
      case MediaType.video:
        return '$mediaFolder/$videoFolder/$gameName.mp4';
      case MediaType.banner:
        return '$mediaFolder/$mediumDiscFolder/$gameName.png';
    }
  }

  // Helper method to convert string to Alignment
  static Alignment getAlignmentFromString(String alignmentString) {
    switch (alignmentString.toLowerCase()) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'center':
      default:
        return Alignment.center;
    }
  }

  // Helper method to convert Alignment to string
  static String getStringFromAlignment(Alignment alignment) {
    if (alignment == Alignment.centerLeft) return 'left';
    if (alignment == Alignment.centerRight) return 'right';
    if (alignment == Alignment.topCenter) return 'top';
    if (alignment == Alignment.bottomCenter) return 'bottom';
    return 'center';
  }

  // Load maps from SharedPreferences
  Future<void> _loadMaps() async {
    final String? isCarouselMapJson = _prefs.getString('isCarouselMap');
    if (isCarouselMapJson != null) {
      final Map<String, dynamic> decoded = json.decode(isCarouselMapJson);
      _isCarouselMap = decoded.map((key, value) => MapEntry(key, value as bool));
    }

    final String? alignmentMapJson = _prefs.getString('alignmentMap');
    if (alignmentMapJson != null) {
      final Map<String, dynamic> decoded = json.decode(alignmentMapJson);
      _alignmentMap = decoded.map((key, value) => 
        MapEntry(key, getAlignmentFromString(value as String)));
    }

    final String? backgroundColorMapJson = _prefs.getString('backgroundColorMap');
    if (backgroundColorMapJson != null) {
      final Map<String, dynamic> decoded = json.decode(backgroundColorMapJson);
      _backgroundColorMap = decoded.map((key, value) => 
        MapEntry(key, Color(value as int)));
    }

    final String? showTickerJson = _prefs.getString(_showTickerKey);
    if (showTickerJson != null) {
      final Map<String, dynamic> decoded = json.decode(showTickerJson);
      _showTicker = decoded.map((key, value) => MapEntry(key, value as bool));
    }

    final String? tickerAlignmentJson = _prefs.getString(_tickerAlignmentKey);
    if (tickerAlignmentJson != null) {
      final Map<String, dynamic> decoded = json.decode(tickerAlignmentJson);
      _tickerAlignment = decoded.map((key, value) => MapEntry(key, value as String));
    }

    final String? tickerSpeedJson = _prefs.getString(_tickerSpeedKey);
    if (tickerSpeedJson != null) {
      final Map<String, dynamic> decoded = json.decode(tickerSpeedJson);
      _tickerSpeed = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
    }

    final String? carouselItemCountJson = _prefs.getString(_carouselItemCountKey);
    if (carouselItemCountJson != null) {
      final Map<String, dynamic> data = json.decode(carouselItemCountJson);
      _carouselItemCount = data.map((key, value) => MapEntry(key, value as int));
    } else {
      _carouselItemCount = {
        'left': defaultCarouselItemCount,
        'right': defaultCarouselItemCount,
        'top': defaultCarouselItemCount,
        'top_left': defaultCarouselItemCount,
        'top_center': defaultCarouselItemCount,
        'top_right': defaultCarouselItemCount,
        'bottom': defaultCarouselItemCount,
        'main': defaultCarouselItemCount,
      };
      await _prefs.setString(_carouselItemCountKey, json.encode(_carouselItemCount));
    }

    // Note: Static image paths and video aspect ratios are now loaded directly in _initializeSettings
    // to ensure they're available as early as possible
  }

  // Save maps to SharedPreferences
  Future<void> _saveMaps() async {
    await _prefs.setString('isCarouselMap', json.encode(_isCarouselMap));
    await _prefs.setString('alignmentMap', json.encode(_alignmentMap.map(
      (key, value) => MapEntry(key, getStringFromAlignment(value)))));
    await _prefs.setString('backgroundColorMap', json.encode(_backgroundColorMap.map(
      (key, value) => MapEntry(key, value.value))));
    await _prefs.setString(_showTickerKey, json.encode(_showTicker));
    await _prefs.setString(_tickerAlignmentKey, json.encode(_tickerAlignment));
    await _prefs.setString(_tickerSpeedKey, json.encode(_tickerSpeed));
    
    // Save static image paths
    await _prefs.setString('staticImagePaths', json.encode(_staticImagePaths));
    
    // Save video aspect ratios
    await _prefs.setString('videoAspectRatios', json.encode(_videoAspectRatios));
    
    // Make sure we save carousel item count
    await _prefs.setString(_carouselItemCountKey, json.encode(_carouselItemCount));
  }

  Future<void> _saveData() async {
    if (_games.isNotEmpty) {
      final List<Map<String, dynamic>> gamesData = _games.map((game) => {
        'name': game.name,
        'executablePath': game.executablePath,
        'logoPath': game.logoPath,
        'videoPath': game.videoPath,
        'storyText': game.storyText,
        'bannerPath': game.bannerPath,
      }).toList();
      await _prefs.setString(_gamesKey, json.encode(gamesData));
    }
    
    if (_parentFolderPath != null) {
      await _prefs.setString(_parentFolderPathKey, _parentFolderPath!);
    }
    
    if (_gamesFolderPath != null) {
      await _prefs.setString(_gamesFolderPathKey, _gamesFolderPath!);
    }
    
    if (_mediaFolderPath != null) {
      await _prefs.setString(_mediaFolderPathKey, _mediaFolderPath!);
    }

    // Save margin dimensions
    await _prefs.setDouble(_leftMarginWidthKey, _leftMarginWidth);
    await _prefs.setDouble(_rightMarginWidthKey, _rightMarginWidth);
    await _prefs.setDouble(_bottomMarginHeightKey, _bottomMarginHeight);
    await _prefs.setDouble(_topMarginHeightKey, _topMarginHeight);

    // Save top section dimensions
    await _prefs.setDouble(_topLeftWidthKey, _topLeftWidth);
    await _prefs.setDouble(_topCenterWidthKey, _topCenterWidth);
    await _prefs.setDouble(_topRightWidthKey, _topRightWidth);

    // Save selected images
    await _prefs.setString(_selectedLeftImageKey, _selectedLeftImage);
    await _prefs.setString(_selectedBottomImageKey, _selectedBottomImage);
    await _prefs.setString(_selectedRightImageKey, _selectedRightImage);
    await _prefs.setString(_selectedTopImageKey, _selectedTopImage);
    await _prefs.setString(_selectedMainImageKey, _selectedMainImage);
    await _prefs.setString(_selectedTopLeftImageKey, _selectedTopLeftImage);
    await _prefs.setString(_selectedTopCenterImageKey, _selectedTopCenterImage);
    await _prefs.setString(_selectedTopRightImageKey, _selectedTopRightImage);
    
    // Make sure to save all maps including static image paths and video aspect ratios
    await _saveMaps();
  }

  // Update carousel item count in memory (save happens when exiting edit mode)
  Future<void> setCarouselItemCount(String sectionKey, int count) async {
    // Create a copy of the current map
    final newCarouselItemCount = Map<String, int>.from(_carouselItemCount);
    
    // Update the value for the specified key
    newCarouselItemCount[sectionKey] = count;
    
    // Just update the map in memory
    _carouselItemCount = newCarouselItemCount;
    
    // Notify listeners, but don't save (save will happen when exiting edit mode)
    notifyListeners();
  }

  // Force save all static image paths directly to SharedPreferences
  Future<void> forceSaveStaticImagePaths() async {
    // First save the entire map to a single key
    await _prefs.setString('staticImagePaths', json.encode(_staticImagePaths));
    
    // Then also save each path individually for redundancy
    for (var entry in _staticImagePaths.entries) {
      if (entry.value.isNotEmpty) {
        final key = 'static_image_path_${entry.key}';
        await _prefs.setString(key, entry.value);
        
        // Log the save for debugging
        debugPrint('Saved static image path for ${entry.key}: ${entry.value}');
      }
    }
  }
  
  // Method to reload all static image paths from SharedPreferences
  Future<void> reloadStaticImagePaths() async {
    // Clear current paths
    _staticImagePaths.clear();
    
    // Try loading from the main map first
    final String? staticImagePathsJson = _prefs.getString('staticImagePaths');
    if (staticImagePathsJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(staticImagePathsJson);
        decoded.forEach((key, value) {
          if (value != null && value.isNotEmpty) {
            _staticImagePaths[key] = value as String;
            debugPrint('Loaded static image for $key from main map: $value');
          }
        });
      } catch (e) {
        debugPrint('Error loading static image paths from main map: $e');
      }
    }
    
    // Also try loading individual paths (these will override the main map if they exist)
    for (final key in ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right']) {
      final individualPath = _prefs.getString('static_image_path_$key');
      if (individualPath != null && individualPath.isNotEmpty) {
        _staticImagePaths[key] = individualPath;
        debugPrint('Loaded static image for $key from individual key: $individualPath');
      }
    }
    
    // Notify listeners after reloading
    notifyListeners();
  }
  
  // Method to reload all video aspect ratios from SharedPreferences
  Future<void> reloadVideoAspectRatios() async {
    // Clear current aspect ratios
    _videoAspectRatios.clear();
    
    // Try loading from the main map first
    final String? videoAspectRatiosJson = _prefs.getString('videoAspectRatios');
    if (videoAspectRatiosJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(videoAspectRatiosJson);
        decoded.forEach((key, value) {
          if (value != null) {
            _videoAspectRatios[key] = double.parse(value.toString());
            debugPrint('Loaded video aspect ratio for $key from main map: $value');
          }
        });
      } catch (e) {
        debugPrint('Error loading video aspect ratios from main map: $e');
      }
    }
    
    // Also try loading individual aspect ratios (these will override the main map if they exist)
    for (final key in ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right']) {
      double? directRatio = _prefs.getDouble('video_aspect_ratio_$key');
      if (directRatio != null) {
        _videoAspectRatios[key] = directRatio;
        debugPrint('Loaded video aspect ratio for $key from individual key: $directRatio');
      }
    }
    
    // Notify listeners after reloading
    notifyListeners();
  }

  // Force save all video aspect ratios directly to SharedPreferences
  Future<void> forceSaveVideoAspectRatios() async {
    // First save the entire map to a single key
    await _prefs.setString('videoAspectRatios', json.encode(_videoAspectRatios));
    
    // Then also save each ratio individually for redundancy
    for (var entry in _videoAspectRatios.entries) {
      final key = 'video_aspect_ratio_${entry.key}';
      await _prefs.setDouble(key, entry.value);
      
      // Log the save for debugging
      debugPrint('Saved video aspect ratio for ${entry.key}: ${entry.value}');
    }
  }

  // Force an immediate save of all settings to SharedPreferences
  Future<void> forceSave() async {
    debugPrint('Forcing save of all settings');
    await _saveData();
    await forceSaveStaticImagePaths();
    await forceSaveVideoAspectRatios();
    await _saveBackgroundImagePathDirectly(_backgroundImagePath);
    debugPrint('All settings saved');
  }

  // Add map to store selected game indices for each section
  final Map<String, int> _selectedGameIndices = {};
  
  // Get selected game index for a section
  int getSelectedGameIndex(String sectionKey) {
    return _selectedGameIndices[sectionKey] ?? 0;
  }
  
  // Set selected game index for a section
  void setSelectedGameIndex(String sectionKey, int index) {
    debugPrint('Setting selected game index for $sectionKey to $index');
    
    // Ensure valid index
    if (index < 0 || (games.isNotEmpty && index >= games.length)) {
      debugPrint('Invalid game index: $index, using 0 instead');
      index = 0;
    }
    
    _selectedGameIndices[sectionKey] = index;
    
    // Save directly to SharedPreferences for immediate persistence
    _saveSelectedGameIndexDirectly(sectionKey, index);
    
    // Notify listeners
    notifyListeners();
  }
  
  // Save selected game index directly to SharedPreferences
  Future<void> _saveSelectedGameIndexDirectly(String sectionKey, int index) async {
    final key = 'selected_game_index_$sectionKey';
    await _prefs.setInt(key, index);
    debugPrint('Saved selected game index for $sectionKey: $index');
  }
  
  // Load selected game indices from SharedPreferences
  Future<void> loadSelectedGameIndices() async {
    _selectedGameIndices.clear();
    
    // Load indices for all possible sections
    for (final key in ['left', 'right', 'top', 'bottom', 'main', 'top_left', 'top_center', 'top_right']) {
      final index = _prefs.getInt('selected_game_index_$key');
      if (index != null) {
        _selectedGameIndices[key] = index;
        debugPrint('Loaded selected game index for $key: $index');
      }
    }
  }

  // Helper methods to get alignment and background color for sections
  Alignment getAlignmentForSection(String sectionKey) {
    return _alignmentMap[sectionKey] ?? Alignment.center;
  }
  
  Color getBackgroundColorForSection(String sectionKey) {
    return _backgroundColorMap[sectionKey] ?? Colors.black45;
  }
}

// Add an enum to specify which type of image is being dropped
enum ImageType { logo, video, story, banner }

// Update MediaType enum to reflect all available media types
enum MediaType {
  logo, // Carousel only
  artwork_front, // Front box art
  artwork_3d, // 3D box art
  fanart, // Fanart images
  video, // Video previews
  banner // Banner images
}
