import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'settings_provider.dart';
import 'screens/game_launcher_home.dart';
import 'screens/batch_game_setup_screen.dart';
import 'utils/window_utils.dart';
import 'utils/video_manager.dart';

// Global navigator key for accessing context anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Main entry point for the Windows Game Launcher application
// Triggers automatic build and release process
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize MediaKit - fixed to avoid void expression error
  MediaKit.ensureInitialized();

  // Initialize our video manager
  await VideoManager().initialize();

  // Initialize window settings
  WindowUtils.initializeWindow();

  // Load settings - note that SettingsProvider constructor initializes settings automatically
  final settingsProvider = SettingsProvider();

  runApp(
    ChangeNotifierProvider.value(
      value: settingsProvider,
      child: const GameLauncherApp(),
    ),
  );
}

class GameLauncherApp extends StatefulWidget {
  const GameLauncherApp({super.key});

  @override
  State<GameLauncherApp> createState() => _GameLauncherAppState();
}

class _GameLauncherAppState extends State<GameLauncherApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register this object as an observer for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Remove the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Get the settings provider
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    
    // Save all layout settings when the app is paused, inactive, or detached
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.inactive || 
        state == AppLifecycleState.detached) {
      print("App lifecycle changed to $state - saving all layout settings");
      
      // Save all layout settings directly through the settings provider
      settingsProvider.saveLayoutPreferences(
        leftMarginWidth: settingsProvider.leftMarginWidth,
        rightMarginWidth: settingsProvider.rightMarginWidth,
        topMarginHeight: settingsProvider.topMarginHeight,
        bottomMarginHeight: settingsProvider.bottomMarginHeight,
        topLeftWidth: settingsProvider.topLeftWidth,
        topCenterWidth: settingsProvider.topCenterWidth,
        topRightWidth: settingsProvider.topRightWidth,
        selectedLeftImage: settingsProvider.selectedLeftImage,
        selectedRightImage: settingsProvider.selectedRightImage,
        selectedTopImage: settingsProvider.selectedTopImage,
        selectedTopLeftImage: settingsProvider.selectedTopLeftImage,
        selectedTopCenterImage: settingsProvider.selectedTopCenterImage,
        selectedTopRightImage: settingsProvider.selectedTopRightImage,
        selectedBottomImage: settingsProvider.selectedBottomImage,
        selectedMainImage: settingsProvider.selectedMainImage,
        isCarouselMap: settingsProvider.isCarouselMap,
        alignmentMap: settingsProvider.alignmentMap,
        backgroundColorMap: settingsProvider.backgroundColorMap,
        showTicker: settingsProvider.showTicker,
        tickerAlignment: settingsProvider.tickerAlignment,
        carouselItemCount: settingsProvider.carouselItemCount,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Launcher',
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          return Builder(
            builder: (context) {
              // Check if any games are configured
              if (!settingsProvider.hasConfiguredGames) {
                // Use a microtask to ensure the dialog shows after the app is built
                Future.microtask(() {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => AlertDialog(
                      title: const Text('Welcome to Game Launcher'),
                      content: const Text(
                          'Let\'s set up your games collection to get started.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BatchGameSetupScreen(),
                              ),
                            );
                          },
                          child: const Text('Setup Games'),
                        ),
                      ],
                    ),
                  );
                });
              }
              return GameLauncherHome(settingsProvider: settingsProvider);
            },
          );
        },
      ),
    );
  }
}
