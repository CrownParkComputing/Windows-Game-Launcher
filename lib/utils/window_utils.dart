import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart' as window_size;

// Define window size options
enum WindowSize { medium, maximum }

class WindowUtils {
  // Define window sizes
  static final Map<WindowSize, Size> windowSizes = {
    WindowSize.medium: const Size(1920, 1080),
    WindowSize.maximum: Size.infinite,
  };

  // Initialize window settings
  static void initializeWindow() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      window_size.getScreenList().then((screens) {
        if (screens.isNotEmpty) {
          final screen = screens[0];
          final width = screen.visibleFrame.width;
          final height = screen.visibleFrame.height;

          // Set initial window size to 80% of screen size
          final windowWidth = width * 0.8;
          final windowHeight = height * 0.8;

          window_size.setWindowFrame(
            Rect.fromCenter(
              center: Offset(width / 2, height / 2),
              width: windowWidth,
              height: windowHeight,
            ),
          );

          // Set minimum window size
          window_size.setWindowMinSize(const Size(800, 600));
          window_size.setWindowMaxSize(Size.infinite);
        }
      });
    }
  }

  // Set window size based on selection
  static void setWindowSize(WindowSize size) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      window_size.getWindowInfo().then((window) {
        if (size == WindowSize.maximum) {
          // For maximum size, use the screen dimensions from window info
          final frame = Rect.fromLTWH(0, 0, window.screen!.visibleFrame.width,
              window.screen!.visibleFrame.height);
          window_size.setWindowFrame(frame);
        } else {
          // For other sizes, set specific dimensions
          final Size windowSize = windowSizes[size]!;
          final Rect frame = Rect.fromCenter(
            center: Offset(windowSize.width / 2, windowSize.height / 2),
            width: windowSize.width,
            height: windowSize.height,
          );
          window_size.setWindowFrame(frame);
        }
      });
    }
  }
}
