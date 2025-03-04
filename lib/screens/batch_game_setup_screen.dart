import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../utils/file_picker_utils.dart';
import '../models/game_config.dart';
import '../settings_provider.dart';

class BatchGameSetupScreen extends StatefulWidget {
  const BatchGameSetupScreen({super.key});

  @override
  State<BatchGameSetupScreen> createState() => _BatchGameSetupScreenState();
}

class _BatchGameSetupScreenState extends State<BatchGameSetupScreen> {
  String _parentPath = '';
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSaving = false;
  List<GameSetupItem> _gameSetupItems = [];
  int _savedGamesCount = 0;
  int _failedGamesCount = 0;

  // TextEditingControllers to persist executable paths
  final Map<String, TextEditingController> _executableControllers = {};

  String _searchQuery = '';
  List<GameSetupItem> get _filteredGames => _gameSetupItems.where((item) {
        if (_searchQuery.isEmpty) return true;
        return item.gameName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();

  @override
  void initState() {
    super.initState();
    _loadSavedParentPath();
  }

  void _loadSavedParentPath() async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final savedPath = settingsProvider.parentFolderPath;
    if (savedPath != null && Directory(savedPath).existsSync()) {
      setState(() {
        _parentPath = savedPath;
      });
    }
    _scanFolders();
  }

  @override
  void dispose() {
    // Clean up controllers when the widget is disposed
    for (var controller in _executableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _changeParentDirectory() async {
    try {
      final selectedDirectory = await FilePickerUtils.pickFolder(
        context,
        dialogTitle: 'Select Parent Directory (containing medium_artwork and roms folders)',
      );

      if (mounted && selectedDirectory != null && selectedDirectory.isNotEmpty) {
        final dir = Directory(selectedDirectory);
        if (await dir.exists()) {
          // Verify that the selected directory contains the required folders
          final mediaDir = Directory('${dir.path}/${SettingsProvider.mediaRootFolder}');
          final romsDir = Directory('${dir.path}/${SettingsProvider.romsFolder}');

          if (!await mediaDir.exists()) {
            _showError('Selected directory must contain a "${SettingsProvider.mediaRootFolder}" folder');
            return;
          }

          if (!await romsDir.exists()) {
            _showError('Selected directory must contain a "${SettingsProvider.romsFolder}" folder');
            return;
          }

          setState(() {
            _parentPath = selectedDirectory;
            _gameSetupItems = []; // Clear existing items
            _executableControllers.clear(); // Clear controllers
          });

          // Save the new path
          if (!mounted) return;
          Provider.of<SettingsProvider>(context, listen: false)
              .setParentFolderPath(_parentPath);

          // Scan the new directory structure
          _scanFolders();
        } else {
          _showError('Selected directory does not exist');
        }
      }
    } catch (e) {
      _showError('Error selecting directory: $e');
    }
  }

  void _scanFolders() async {
    if (_parentPath.isEmpty) return;

    setState(() {
      _isLoading = true;
      _gameSetupItems = [];
    });

    try {
      final gamesDir = Directory('$_parentPath/${SettingsProvider.romsFolder}');
      final mediaDir = Directory('$_parentPath/${SettingsProvider.mediaRootFolder}');
      
      if (!gamesDir.existsSync() || !mediaDir.existsSync()) {
        _showError('Required folders not found. Please check the folder structure.');
        setState(() => _isLoading = false);
        return;
      }

      // Get all game folders
      final gameFolders = gamesDir.listSync()
          .whereType<Directory>()
          .toList();

      // Get existing games from settings provider
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      final existingGames = settingsProvider.games;

      // Process each game folder
      for (var gameFolder in gameFolders) {
        final gameName = path.basename(gameFolder.path);
        
        // Check for logo (not required anymore)
        final logoPath = '$_parentPath/${SettingsProvider.mediaRootFolder}/${SettingsProvider.logoFolder}/$gameName.png';
        
        // Optional: Check for video
        final videoPath = '$_parentPath/${SettingsProvider.mediaRootFolder}/${SettingsProvider.videoFolder}/$gameName.mp4';
        
        // Optional: Check for banner
        final bannerPath = '$_parentPath/${SettingsProvider.mediaRootFolder}/${SettingsProvider.mediumDiscFolder}/$gameName.png';

        // Look for existing game config
        final existingGame = existingGames.firstWhere(
          (game) => game.name == gameName,
          orElse: () => GameConfig(
            name: gameName,
            executablePath: '',
            logoPath: File(logoPath).existsSync() ? logoPath : '',
            videoPath: File(videoPath).existsSync() ? videoPath : '',
            storyText: '',
            bannerPath: File(bannerPath).existsSync() ? bannerPath : '',
          ),
        );

        // Create GameSetupItem
        final item = GameSetupItem(
          gameName: gameName,
          logoPath: existingGame.logoPath.isNotEmpty ? existingGame.logoPath : (File(logoPath).existsSync() ? logoPath : ''),
          executablePath: existingGame.executablePath,
          videoPath: existingGame.videoPath.isNotEmpty ? existingGame.videoPath : (File(videoPath).existsSync() ? videoPath : ''),
          storyText: existingGame.storyText,
          bannerPath: existingGame.bannerPath.isNotEmpty ? existingGame.bannerPath : (File(bannerPath).existsSync() ? bannerPath : ''),
        );

        setState(() {
          _gameSetupItems.add(item);
          _executableControllers[gameName] = TextEditingController(text: existingGame.executablePath);
        });
      }
    } catch (e) {
      _showError('Error scanning folders: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String?> _findExecutableInDirectory(String directory, String gameName) async {
    try {
      final dir = Directory(directory);
      final List<FileSystemEntity> entities = await dir.list().toList();
      
      // First, look for exact matches in current directory
      for (var entity in entities) {
        if (entity is File) {
          final fileName = path.basenameWithoutExtension(entity.path).toLowerCase();
          final ext = path.extension(entity.path).toLowerCase();
          if (fileName == gameName.toLowerCase() && 
              ['.exe', '.bat', '.cmd', '.lnk'].contains(ext)) {
            return entity.path;
          }
        }
      }

      // Then recursively search subdirectories
      for (var entity in entities) {
        if (entity is Directory) {
          final result = await _findExecutableInDirectory(entity.path, gameName);
          if (result != null) {
            return result;
          }
        }
      }
    } catch (e) {
      debugPrint('Error searching directory $directory: $e');
    }
    return null;
  }

  Future<void> _pickExecutable(String gameName) async {
    try {
      final result = await FilePickerUtils.pickGameExecutable(context);

      if (result != null) {
        final controller = _executableControllers[gameName];
        if (controller != null && mounted) {
          setState(() {
            controller.text = result;

            // Update the item in the list with new executable path
            final index =
                _gameSetupItems.indexWhere((item) => item.gameName == gameName);
            if (index != -1) {
              _gameSetupItems[index] = _gameSetupItems[index].copyWith(
                executablePath: result,
              );
            }
          });
        }
      }
    } catch (e) {
      _showError('Error picking executable: $e');
    }
  }

  void _saveGames() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _savedGamesCount = 0;
      _failedGamesCount = 0;
    });

    try {
      final settingsProvider =
          Provider.of<SettingsProvider>(context, listen: false);

      // Update all items with current controller values
      for (int i = 0; i < _gameSetupItems.length; i++) {
        final item = _gameSetupItems[i];
        final controller = _executableControllers[item.gameName];
        if (controller != null) {
          _gameSetupItems[i] = item.copyWith(executablePath: controller.text);
        }
      }

      // Filter only items with executable paths
      final validItems = _gameSetupItems
          .where((item) => item.executablePath.isNotEmpty && File(item.executablePath).existsSync())
          .toList();

      // First remove all existing games
      final existingGames = List<GameConfig>.from(settingsProvider.games);
      for (var game in existingGames) {
        settingsProvider.deleteGameByName(game.name);
      }

      // Then add all valid games
      for (final item in validItems) {
        try {
          final gameConfig = GameConfig(
            name: item.gameName,
            executablePath: item.executablePath,
            logoPath: item.logoPath,
            videoPath: item.videoPath,
            storyText: item.storyText,
            bannerPath: item.bannerPath,
          );

          settingsProvider.addGame(gameConfig);
          setState(() => _savedGamesCount++);
        } catch (e) {
          debugPrint('Error saving game ${item.gameName}: $e');
          setState(() => _failedGamesCount++);
        }
      }

      if (_savedGamesCount > 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Saved $_savedGamesCount games successfully${_failedGamesCount > 0 ? ', $_failedGamesCount failed' : ''}'),
            backgroundColor: _failedGamesCount > 0 ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error saving games: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Game Setup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: _changeParentDirectory,
            tooltip: 'Change Parent Directory',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _scanFolders,
            tooltip: 'Refresh Scan',
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.folder_open, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Parent Directory: $_parentPath',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton(
                            onPressed: _changeParentDirectory,
                            child: const Text('Change'),
                          ),
                        ],
                      ),
                      if (_parentPath.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Media Path: $_parentPath/${SettingsProvider.mediaRootFolder}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ROMs Path: $_parentPath/${SettingsProvider.romsFolder}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        'Found ${_gameSetupItems.length} potential games. Associate an executable with each game you want to add.',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: (_gameSetupItems.any((item) =>
                                          _executableControllers[item.gameName]
                                              ?.text
                                              .isNotEmpty ==
                                          true) &&
                                      !_isSaving)
                                  ? _saveGames
                                  : null,
                              icon: const Icon(Icons.save),
                              label: const Text('SAVE ALL GAMES WITH EXECUTABLES'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Search field for filtering games
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Filter games',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _gameSetupItems.isEmpty
                          ? const Center(
                              child: Text(
                                  'No image files found in the media directory.'))
                          : ListView.builder(
                              itemCount: _filteredGames.length,
                              itemBuilder: (context, index) {
                                final item = _filteredGames[index];
                                return _buildGameSetupItem(item);
                              },
                            ),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black
                  .withAlpha(128), // 128 is equivalent to 0.5 opacity
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'Saving games: $_savedGamesCount saved, $_failedGamesCount failed...',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGameSetupItem(GameSetupItem item) {
    final controller = _executableControllers[item.gameName] ?? TextEditingController();
    if (!_executableControllers.containsKey(item.gameName)) {
      _executableControllers[item.gameName] = controller;
    }

    final hasExecutable = controller.text.isNotEmpty && File(controller.text).existsSync();
    final hasLogo = item.logoPath.isNotEmpty && File(item.logoPath).existsSync();
    final hasVideo = item.videoPath.isNotEmpty && File(item.videoPath).existsSync();
    final hasStory = item.storyText.isNotEmpty;

    // Determine if the logo is a logo.png file (preferred) or boxart
    final isLogoFile = hasLogo &&
        (path.basename(item.logoPath).toLowerCase() == 'logo.png' ||
            path.basename(item.logoPath).toLowerCase().contains('logo'));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Logo preview or placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                    color: isLogoFile ? Colors.lightBlue.withOpacity(0.1) : Colors.grey.shade100,
                  ),
                  child: hasLogo
                      ? Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                File(item.logoPath),
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                            if (isLogoFile)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined, color: Colors.grey.shade400, size: 32),
                            const SizedBox(height: 4),
                            Text(
                              'No Logo',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.gameName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            hasExecutable ? Icons.check_circle : Icons.cancel,
                            color: hasExecutable ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text('Executable', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(
                            hasLogo ? Icons.check_circle : Icons.cancel,
                            color: hasLogo
                                ? (isLogoFile ? Colors.blue : Colors.green)
                                : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(isLogoFile ? 'Logo.png' : 'Logo',
                              style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(
                            hasVideo ? Icons.check_circle : Icons.cancel,
                            color: hasVideo ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text('Video', style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 12),
                          Icon(
                            hasStory ? Icons.check_circle : Icons.cancel,
                            color: hasStory ? Colors.green : Colors.grey,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text('Story', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Executable path row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    decoration: const InputDecoration(
                      labelText: 'Executable Path',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      hintText: 'Select executable for this game',
                      errorMaxLines: 2,
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (hasExecutable) return null;
                      if (_isSaving && (value == null || value.isEmpty)) {
                        return 'Select an executable to add this game';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      final index = _gameSetupItems.indexWhere((i) => i.gameName == item.gameName);
                      if (index != -1) {
                        setState(() {
                          _gameSetupItems[index] = _gameSetupItems[index].copyWith(
                            executablePath: value,
                          );
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _pickExecutable(item.gameName),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasExecutable ? Colors.green : null,
                  ),
                  child: const Text('Browse'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Story text editor
            TextFormField(
              initialValue: item.storyText,
              decoration: InputDecoration(
                labelText: 'Story Text',
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: 'Enter story text for the game ticker...',
                suffixIcon: Icon(
                  Icons.text_fields,
                  color: hasStory ? Colors.green : Colors.grey,
                ),
              ),
              maxLines: 3,
              onChanged: (value) {
                final index = _gameSetupItems.indexWhere((i) => i.gameName == item.gameName);
                if (index != -1) {
                  setState(() {
                    _gameSetupItems[index] = _gameSetupItems[index].copyWith(
                      storyText: value,
                    );
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GameSetupItem {
  final String gameName;
  final String logoPath;
  final String executablePath;
  final String videoPath;
  final String storyText;
  final String bannerPath;

  GameSetupItem({
    required this.gameName,
    required this.logoPath,
    required this.executablePath,
    this.videoPath = '',
    this.storyText = '',
    this.bannerPath = '',
  });

  GameSetupItem copyWith({
    String? gameName,
    String? logoPath,
    String? executablePath,
    String? videoPath,
    String? storyText,
    String? bannerPath,
  }) {
    return GameSetupItem(
      gameName: gameName ?? this.gameName,
      logoPath: logoPath ?? this.logoPath,
      executablePath: executablePath ?? this.executablePath,
      videoPath: videoPath ?? this.videoPath,
      storyText: storyText ?? this.storyText,
      bannerPath: bannerPath ?? this.bannerPath,
    );
  }
}
