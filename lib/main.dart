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

class GameLauncherApp extends StatelessWidget {
  const GameLauncherApp({super.key});

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
