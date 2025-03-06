import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit/media_kit.dart';
import 'settings_provider.dart';
import 'screens/game_launcher_home.dart';
import 'screens/batch_game_setup_screen.dart';
import 'utils/window_utils.dart';
import 'utils/video_manager.dart';
import 'pages/platform_select_page.dart';
import 'screens/main_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:window_manager/window_manager.dart';
import 'widgets/custom_window_controls.dart';

// Global navigator key for accessing context anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Main entry point for the Windows Game Launcher application
void main() {
  runZonedGuarded(() async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize window manager first
    await windowManager.ensureInitialized();
    await windowManager.setSize(const Size(1536, 864));
    await windowManager.setMinimumSize(const Size(800, 600));
    await windowManager.center();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.show();

    // Load settings - note that SettingsProvider constructor initializes settings automatically
    final settingsProvider = SettingsProvider();

    // Run the app first
    runApp(
      ChangeNotifierProvider.value(
        value: settingsProvider,
        child: const GameLauncherApp(),
      ),
    );

    // Initialize media components after the app is running
    await Future.delayed(const Duration(milliseconds: 100));
    MediaKit.ensureInitialized();
    await VideoManager().initialize();

  }, (error, stack) {
    debugPrint('Error during initialization: $error');
    debugPrint(stack.toString());
  });
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
    super.didChangeAppLifecycleState(state);
    // Save layout settings when app is paused or inactive
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Get the settings provider
      final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
      // Save layout settings directly through the settings provider
      settingsProvider.saveLayoutPreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Game Launcher',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            return Scaffold(
              appBar: const CustomWindowAppBar(),
              body: Builder(
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
                  return const PlatformSelectPage();
                },
              ),
            );
          },
        ),
        '/main': (context) => const Scaffold(
          appBar: CustomWindowAppBar(),
          body: MainScreen(),
        ),
      },
    );
  }
}
