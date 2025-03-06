import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../settings_provider.dart';
import '../controllers/game_controller.dart';
import '../controllers/layout_manager.dart';
import '../widgets/game_launcher_ui.dart';
import '../utils/video_manager.dart';
import 'batch_game_setup_screen.dart';

// Add a global key outside the class to access the state
final GlobalKey<_GameLauncherHomeState> _gameLauncherHomeKey = GlobalKey<_GameLauncherHomeState>();

class GameLauncherHome extends StatefulWidget {
  final SettingsProvider settingsProvider;
  // Add a getter for layoutManager that accesses the current state's layoutManager
  LayoutManager? get layoutManager => _gameLauncherHomeKey.currentState?.layoutManager;

  const GameLauncherHome({Key? key, required this.settingsProvider})
      : super(key: key);

  @override
  State<GameLauncherHome> createState() => _GameLauncherHomeState();
}

class _GameLauncherHomeState extends State<GameLauncherHome> {
  // Controllers
  late GameController gameController;
  late LayoutManager layoutManager;

  // State
  bool isEditMode = false;
  late final Player player;
  late final VideoController videoController;

  @override
  void initState() {
    super.initState();

    // Get a reference to a managed player from VideoManager
    player = VideoManager().getPlayer('main_player');
    videoController = VideoController(player);

    // Initialize controllers
    layoutManager = LayoutManager(widget.settingsProvider);
    gameController = GameController(
      games: widget.settingsProvider.games,
      player: player,
    );

    // Load games data
    _loadGames();
  }

  @override
  void dispose() {
    // Save all layout settings before disposing
    layoutManager.saveAllLayoutSettings();
    
    // Let the VideoManager handle player disposal
    gameController.dispose();
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
    });
  }

  // Toggle edit mode for layout customization
  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
      if (!isEditMode) {
        // Save all layout settings when exiting edit mode
        layoutManager.saveAllLayoutSettings();
      }
    });
  }

  // Open game manager screen
  void _openGameManager() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const BatchGameSetupScreen(),
          ),
        )
        .then((_) => _loadGames());
  }

  // Handle keyboard input for navigation
  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          gameController.selectPreviousGame();
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          gameController.selectNextGame();
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        gameController.launchGame(context);
      } else if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.keyM) {
        setState(() {
          gameController.toggleMute();
        });
      }
    }
  }

  // Handle game selection from UI
  void _onGameSelected(int index) {
    setState(() {
      gameController.selectGameByIndex(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: FocusNode(),
      autofocus: true,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: GameLauncherAppBar(
          selectedGame: gameController.selectedGame,
          onEditModeToggle: _toggleEditMode,
          onOpenGameManager: _openGameManager,
          isEditMode: isEditMode,
        ),
        body: gameController.games.isEmpty
            ? EmptyGamesPlaceholder(
                onOpenGameManager: _openGameManager,
              )
            : Column(
                children: [
                  GameLayout(
                    layoutManager: layoutManager,
                    settingsProvider: widget.settingsProvider,
                    isEditMode: isEditMode,
                    selectedGameIndex: gameController.selectedGameIndex,
                    onGameSelected: _onGameSelected,
                  ),
                ],
              ),
      ),
    );
  }
}
