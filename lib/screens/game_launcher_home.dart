import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../settings_provider.dart';
import '../controllers/game_controller.dart';
import '../controllers/layout_manager.dart';
import '../widgets/game_launcher_ui.dart';
import 'batch_game_setup_screen.dart';
import '../utils/video_manager.dart';
import '../utils/background_image_manager.dart';
import '../utils/logger.dart';

// Global key for accessing the state
final GlobalKey<_GameLauncherHomeState> gameLauncherHomeKey = GlobalKey<_GameLauncherHomeState>();

class GameLauncherHome extends StatefulWidget {
  final SettingsProvider settingsProvider;
  
  const GameLauncherHome({
    Key? key,
    required this.settingsProvider,
  }) : super(key: key);

  @override
  _GameLauncherHomeState createState() => _GameLauncherHomeState();
}

class _GameLauncherHomeState extends State<GameLauncherHome> {
  late GameController gameController;
  late LayoutManager layoutManager;
  late Player player;
  late VideoController videoController;
  bool isEditMode = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize media kit
    player = Player();
    videoController = VideoController(player);
    
    // Initialize controllers
    layoutManager = LayoutManager(settingsProvider: widget.settingsProvider);
    gameController = GameController(
      games: widget.settingsProvider.games,
      player: player,
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGames();
    });
  }
  
  @override
  void dispose() {
    // Save layout settings on dispose
    layoutManager.saveAllLayoutSettings();
    player.dispose();
    super.dispose();
  }
  
  // Load games from settings provider
  void _loadGames() {
    setState(() {
      gameController = GameController(
        games: widget.settingsProvider.games,
        player: player,
      );
      gameController.loadGameMedia();
      Logger.debug('${widget.settingsProvider.games.length} games loaded', source: 'GameLauncherHome');
    });
  }
  
  // Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
      Logger.debug('Edit mode toggled to: $isEditMode', source: 'GameLauncherHome');
      if (!isEditMode) {
        // Save all layout settings when exiting edit mode
        layoutManager.saveAllLayoutSettings();
      }
    });
  }
  
  // Open game manager screen
  void _openGameManager() async {
    await Navigator.of(context)
      .push(
        MaterialPageRoute(
          builder: (context) => const BatchGameSetupScreen(),
        ),
      )
      .then((_) => _loadGames());
  }
  
  // Toggle glass effect
  void _toggleGlassEffect() {
    widget.settingsProvider.toggleGlassEffect();
    Logger.debug('Glass effect toggled to: ${widget.settingsProvider.useGlassEffect}', source: 'GameLauncherHome');
    setState(() {});
  }
  
  // Handle keyboard input
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Handle arrow keys for navigating between games
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        gameController.selectPreviousGame();
        setState(() {});
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        gameController.selectNextGame();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final settingsProvider = widget.settingsProvider;
    final backgroundManager = BackgroundImageManager();
    
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: GameLauncherAppBar(
          selectedGame: widget.settingsProvider.games.isNotEmpty && gameController.selectedGameIndex < widget.settingsProvider.games.length
              ? widget.settingsProvider.games[gameController.selectedGameIndex]
              : null,
          onEditModeToggle: _toggleEditMode,
          onOpenGameManager: _openGameManager,
          isEditMode: isEditMode,
          onSelectBackground: backgroundManager.hasBackgroundImage(settingsProvider)
              ? () => _showBackgroundImageOptions(context)
              : () => _selectBackgroundImage(),
          hasBackgroundImage: backgroundManager.hasBackgroundImage(settingsProvider),
          useGlassEffect: widget.settingsProvider.useGlassEffect,
          onToggleGlassEffect: _toggleGlassEffect,
        ),
        body: Stack(
          children: [
            // Background image (behind everything)
            backgroundManager.buildBackgroundImage(settingsProvider),
            
            // Main layout
            widget.settingsProvider.games.isEmpty
                ? EmptyGamesPlaceholder(onOpenGameManager: _openGameManager)
                : GameLayout(
                    layoutManager: layoutManager,
                    settingsProvider: widget.settingsProvider,
                    isEditMode: isEditMode,
                    selectedGameIndex: gameController.selectedGameIndex,
                    onGameSelected: _onGameSelected,
                  ),
                  
            // Show edit mode indicator
            if (isEditMode)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'EDIT MODE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  // Handle game selection from UI
  void _onGameSelected(int index) {
    setState(() {
      gameController.selectGameByIndex(index);
    });
  }
  
  // Method to select a background image
  Future<void> _selectBackgroundImage() async {
    try {
      final backgroundManager = BackgroundImageManager();
      final imagePath = await backgroundManager.pickBackgroundImage(widget.settingsProvider);
      
      if (imagePath != null) {
        // Image was selected and saved, force a rebuild
        setState(() {});
      }
    } catch (e) {
      Logger.error('Error selecting background image: $e', source: 'GameLauncherHome');
    }
  }
  
  // Show background image options (change or remove)
  void _showBackgroundImageOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Image'),
        content: const Text('What would you like to do with the background image?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _selectBackgroundImage();
            },
            child: const Text('Change'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear the background image
              final backgroundManager = BackgroundImageManager();
              backgroundManager.clearBackgroundImage(widget.settingsProvider);
              setState(() {});
            },
            child: const Text('Remove'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
