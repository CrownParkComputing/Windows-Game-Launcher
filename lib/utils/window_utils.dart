import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

// Define window size options
enum WindowSize { medium, maximum }

class WindowUtils {
  // Define window sizes
  static final Map<WindowSize, Size> windowSizes = {
    WindowSize.medium: const Size(1536, 864), // 80% of 1920x1080
    WindowSize.maximum: Size.infinite,
  };

  // Initialize window settings
  static Future<void> initializeWindow() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await windowManager.ensureInitialized();

        // Basic window setup
        await windowManager.setSize(windowSizes[WindowSize.medium]!);
        await windowManager.setMinimumSize(const Size(800, 600));
        await windowManager.center();
        await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
        await windowManager.show();
      }
    } catch (e) {
      debugPrint('Error initializing window: $e');
    }
  }

  // Set window size based on selection
  static Future<void> setWindowSize(WindowSize size) async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        if (size == WindowSize.maximum) {
          await windowManager.maximize();
        } else {
          final Size windowSize = windowSizes[size]!;
          await windowManager.unmaximize(); // Ensure window is not maximized
          await windowManager.setSize(windowSize);
          await windowManager.center();
        }
      }
    } catch (e) {
      debugPrint('Error setting window size: $e');
    }
  }

  // Start window dragging
  static void startWindowDrag() {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        windowManager.startDragging();
      }
    } catch (e) {
      debugPrint('Error starting window drag: $e');
    }
  }

  // Toggle window maximize/restore
  static Future<void> toggleMaximize() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final isMaximized = await windowManager.isMaximized();
        if (isMaximized) {
          await setWindowSize(WindowSize.medium);
        } else {
          await setWindowSize(WindowSize.maximum);
        }
      }
    } catch (e) {
      debugPrint('Error toggling maximize: $e');
    }
  }

  // Restore window to medium size
  static Future<void> restore() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await setWindowSize(WindowSize.medium);
      }
    } catch (e) {
      debugPrint('Error restoring window: $e');
    }
  }
}
