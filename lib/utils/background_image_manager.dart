import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../settings_provider.dart';
import 'logger.dart';

/// A utility class for managing the background image
class BackgroundImageManager {
  static final BackgroundImageManager _instance = BackgroundImageManager._internal();
  
  factory BackgroundImageManager() {
    return _instance;
  }
  
  BackgroundImageManager._internal();
  
  /// Check if a background image is set
  bool hasBackgroundImage(SettingsProvider settingsProvider) {
    final path = settingsProvider.backgroundImagePath;
    if (path == null || path.isEmpty) {
      return false;
    }
    
    // Check if the file exists
    final file = File(path);
    return file.existsSync();
  }
  
  /// Pick a background image and save it to settings
  Future<String?> pickBackgroundImage(SettingsProvider settingsProvider) async {
    try {
      Logger.info('Opening file picker to select background image', source: 'BackgroundImageManager');
      
      // Use file_picker to select an image file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        dialogTitle: 'Select a Background Image',
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path;
        
        if (path != null) {
          Logger.info('User selected background image: $path', source: 'BackgroundImageManager');
          
          // Save the selected background image path
          settingsProvider.setBackgroundImagePath(path);
          
          return path;
        }
      } else {
        Logger.info('User canceled background image selection', source: 'BackgroundImageManager');
      }
    } catch (e) {
      Logger.error('Error selecting background image: $e', source: 'BackgroundImageManager');
    }
    
    return null;
  }
  
  /// Clear the background image
  void clearBackgroundImage(SettingsProvider settingsProvider) {
    Logger.info('Clearing background image', source: 'BackgroundImageManager');
    settingsProvider.setBackgroundImagePath(null);
  }
  
  /// Get a Widget that displays the background image
  Widget buildBackgroundImage(SettingsProvider settingsProvider, {BoxFit fit = BoxFit.cover}) {
    final path = settingsProvider.backgroundImagePath;
    if (path == null || path.isEmpty) {
      return Container(color: Colors.black);
    }
    
    final file = File(path);
    if (!file.existsSync()) {
      Logger.warning('Background image file does not exist: $path', source: 'BackgroundImageManager');
      return Container(color: Colors.black);
    }
    
    // Return an image that covers the entire screen
    return Image.file(
      file,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        Logger.error('Error loading background image: $error', source: 'BackgroundImageManager');
        return Container(color: Colors.black);
      },
    );
  }
} 