import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// A utility class to handle file picking operations
class FilePickerUtils {
  /// Pick an executable file for a game
  static Future<String?> pickGameExecutable(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Game Executable',
        type: FileType.custom,
        allowedExtensions: ['exe', 'bat', 'cmd', 'lnk'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
    } catch (e) {
      // Removed debugPrint statement
    }
    return null;
  }

  /// Pick an image file for game artwork
  static Future<String?> pickImageFile(BuildContext context,
      {String? mediaType, String? initialDirectory}) {
    String title = 'Select Image File';
    if (mediaType != null) {
      title = 'Select ${mediaType.replaceAll('_', ' ').toUpperCase()} Image';
    }

    return _pickFile(
      context: context,
      dialogTitle: title,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
      initialDirectory: initialDirectory,
    );
  }

  /// Pick a video file for a game
  static Future<String?> pickVideoFile(BuildContext context) {
    return _pickFile(
      context: context,
      dialogTitle: 'Select Video File',
      allowedExtensions: ['mp4', 'webm', 'mov', 'avi', 'mkv', 'wmv'],
    );
  }

  /// Pick a text file for game story
  static Future<String?> pickStoryFile(BuildContext context) {
    return _pickFile(
      context: context,
      dialogTitle: 'Select Story Text File',
      allowedExtensions: ['txt', 'md', 'rtf'],
    );
  }

  /// General file picking method
  static Future<String?> _pickFile({
    required BuildContext context,
    required String dialogTitle,
    required List<String> allowedExtensions,
    String? initialDirectory,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: dialogTitle,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
        initialDirectory: initialDirectory,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first.path;
      }
    } catch (e) {
      // Removed debugPrint statement
    }
    return null;
  }

  /// Pick multiple game executables at once
  static Future<List<String>> pickMultipleGameExecutables(
      BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Select Game Executables',
        type: FileType.custom,
        allowedExtensions: ['exe', 'bat', 'cmd', 'lnk'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.map((file) => file.path!).toList();
      }
    } catch (e) {
      // Removed debugPrint statement
    }
    return [];
  }

  /// Pick a folder
  static Future<String?> pickFolder(BuildContext context,
      {String? dialogTitle}) async {
    try {
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: dialogTitle ?? 'Select Folder',
      );
      return result;
    } catch (e) {
      // Removed debugPrint statement
    }
    return null;
  }
}
