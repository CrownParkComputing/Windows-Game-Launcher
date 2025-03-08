import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../settings_provider.dart';
import 'logger.dart';

/// A utility class to manage static image operations
class StaticImageManager {
  static final StaticImageManager _instance = StaticImageManager._internal();
  
  factory StaticImageManager() {
    return _instance;
  }
  
  StaticImageManager._internal();
  
  /// Prompt the user to select a static image from the static_images folder
  Future<String?> pickStaticImage(SettingsProvider settingsProvider, String sectionKey) async {
    try {
      Logger.info('Opening file picker to select static image for section $sectionKey', source: 'StaticImageManager');
      
      // Default to the static_images subfolder in the medium_artwork directory
      final baseDir = '${settingsProvider.effectiveMediaFolderPath}/static_images';
      
      // Make sure the directory exists
      final staticImagesDir = Directory(baseDir);
      if (!staticImagesDir.existsSync()) {
        Logger.info('Creating static_images directory at $baseDir', source: 'StaticImageManager');
        staticImagesDir.createSync(recursive: true);
      }
      
      // Use file_picker to select an image file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
        dialogTitle: 'Select a Static Image',
        initialDirectory: baseDir,
      );
      
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final path = file.path;
        
        if (path != null) {
          Logger.info('User selected static image: $path for section $sectionKey', source: 'StaticImageManager');
          
          // Save the selected static image path
          settingsProvider.setStaticImagePath(sectionKey, path);
          
          // Force save all settings to ensure the static image path is persisted
          settingsProvider.forceSave();
          
          return path;
        }
      } else {
        Logger.info('User canceled static image selection for section $sectionKey', source: 'StaticImageManager');
      }
    } catch (e) {
      Logger.error('Error selecting static image: $e', source: 'StaticImageManager');
    }
    
    return null;
  }
  
  /// Check if a static image is already selected for a section
  bool hasStaticImage(SettingsProvider settingsProvider, String sectionKey) {
    final path = settingsProvider.getStaticImagePath(sectionKey);
    final hasPath = path != null && path.isNotEmpty;
    
    // Also verify the file exists
    if (hasPath) {
      final file = File(path!);
      final exists = file.existsSync();
      
      if (!exists) {
        Logger.warning('Static image path exists but file is missing: $path', source: 'StaticImageManager');
        return false;
      }
      
      return true;
    }
    
    return false;
  }
  
  /// Get the path to the static image for a section, or null if none selected
  String? getStaticImagePath(SettingsProvider settingsProvider, String sectionKey) {
    final path = settingsProvider.getStaticImagePath(sectionKey);
    
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return path;
      } else {
        Logger.warning('Static image file does not exist: $path', source: 'StaticImageManager');
        return null;
      }
    }
    
    return null;
  }
  
  /// Clear the static image for a section
  void clearStaticImage(SettingsProvider settingsProvider, String sectionKey) {
    Logger.info('Clearing static image for section $sectionKey', source: 'StaticImageManager');
    settingsProvider.setStaticImagePath(sectionKey, null);
    settingsProvider.forceSave();
  }
} 