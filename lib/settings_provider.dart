import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'models/game_config.dart';
import 'dart:io';

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

  // Media subfolder paths relative to parent folder
  static const String mediaRootFolder = 'medium_artwork';
  static const String romsFolder = 'roms';
  static const String logoFolder = 'logo';
  static const String artworkFrontFolder = 'artwork_front';
  static const String artwork3dFolder = 'artwork_3d';
  static const String fanartFolder = 'fanart';
  static const String videoFolder = 'video';
  static const String mediumDiscFolder = 'medium_disc';

  // Valid media types for layout positions (including all available types)
  static const List<String> validLayoutMedia = [
    'logo',
    'artwork_front',
    'artwork_3d',
    'fanart',
    'video',
    'story',
    'medium_disc'
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
  Map<String, Alignment> get alignmentMap => _alignmentMap;
  Map<String, Color> get backgroundColorMap => _backgroundColorMap;

  // Getters for ticker settings
  Map<String, bool> get showTicker => Map.unmodifiable(_showTicker);
  Map<String, String> get tickerAlignment => Map.unmodifiable(_tickerAlignment);
  Map<String, double> get tickerSpeed => Map.unmodifiable(_tickerSpeed);

  // Default ticker settings
  static const defaultTickerSpeed = 50.0;
  static const List<String> validTickerAlignments = ['top', 'bottom'];

  // Convert color string to Color object
  static Color getColorFromString(String colorString) {
    return availableBackgroundColors[colorString] ?? Colors.black45;
  }

  // Constructor
  SettingsProvider() {
    _initializeSettings();
  }

  // Initialize settings
  Future<void> _initializeSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load saved paths
    _parentFolderPath = _prefs.getString(_parentFolderPathKey);
    _gamesFolderPath = _prefs.getString(_gamesFolderPathKey);
    _mediaFolderPath = _prefs.getString(_mediaFolderPathKey);
    
    // Load margin dimensions
    _leftMarginWidth = _prefs.getDouble(_leftMarginWidthKey) ?? 200;
    _rightMarginWidth = _prefs.getDouble(_rightMarginWidthKey) ?? 200;
    _bottomMarginHeight = _prefs.getDouble(_bottomMarginHeightKey) ?? 120;
    _topMarginHeight = _prefs.getDouble(_topMarginHeightKey) ?? 120;
    
    // Load selected images
    _selectedLeftImage = _prefs.getString(_selectedLeftImageKey) ?? 'logo';
    _selectedBottomImage = _prefs.getString(_selectedBottomImageKey) ?? 'logo';
    _selectedRightImage = _prefs.getString(_selectedRightImageKey) ?? 'logo';
    _selectedTopImage = _prefs.getString(_selectedTopImageKey) ?? 'logo';
    _selectedMainImage = _prefs.getString(_selectedMainImageKey) ?? 'video';

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
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Only update values that are provided, keep existing values otherwise
    if (leftMarginWidth != null) _leftMarginWidth = leftMarginWidth;
    if (rightMarginWidth != null) _rightMarginWidth = rightMarginWidth;
    if (bottomMarginHeight != null) _bottomMarginHeight = bottomMarginHeight;
    if (topMarginHeight != null) _topMarginHeight = topMarginHeight;
    
    // Update media type selections only if provided
    if (selectedLeftImage != null) _selectedLeftImage = selectedLeftImage;
    if (selectedRightImage != null) _selectedRightImage = selectedRightImage;
    if (selectedTopImage != null) _selectedTopImage = selectedTopImage;
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

    // Save all values to SharedPreferences
    await prefs.setDouble('leftMarginWidth', _leftMarginWidth);
    await prefs.setDouble('rightMarginWidth', _rightMarginWidth);
    await prefs.setDouble('bottomMarginHeight', _bottomMarginHeight);
    await prefs.setDouble('topMarginHeight', _topMarginHeight);
    
    await prefs.setString('selectedLeftImage', _selectedLeftImage);
    await prefs.setString('selectedRightImage', _selectedRightImage);
    await prefs.setString('selectedTopImage', _selectedTopImage);
    await prefs.setString('selectedBottomImage', _selectedBottomImage);
    await prefs.setString('selectedMainImage', _selectedMainImage);

    // Save maps as JSON strings
    await prefs.setString('isCarouselMap', jsonEncode(_isCarouselMap.map((key, value) => MapEntry(key, value))));
    await prefs.setString('alignmentMap', jsonEncode(_alignmentMap.map((key, value) => MapEntry(key, value.toString()))));
    await prefs.setString('backgroundColorMap', jsonEncode(_backgroundColorMap.map((key, value) => MapEntry(key, value.value))));
    await prefs.setString('showTicker', jsonEncode(_showTicker));
    await prefs.setString('tickerAlignment', jsonEncode(_tickerAlignment));

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

    // Save selected images
    await _prefs.setString(_selectedLeftImageKey, _selectedLeftImage);
    await _prefs.setString(_selectedBottomImageKey, _selectedBottomImage);
    await _prefs.setString(_selectedRightImageKey, _selectedRightImage);
    await _prefs.setString(_selectedTopImageKey, _selectedTopImage);
    await _prefs.setString(_selectedMainImageKey, _selectedMainImage);

    // Save maps
    await _saveMaps();
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
