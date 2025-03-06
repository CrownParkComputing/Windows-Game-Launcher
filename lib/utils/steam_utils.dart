import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:process_run/shell.dart';

class SteamGame {
  final String name;
  final String appId;
  final String executablePath;
  final String installDir;

  SteamGame({
    required this.name,
    required this.appId,
    required this.executablePath,
    required this.installDir,
  });
}

class SteamUtils {
  static final List<String> _defaultSteamPaths = [
    'C:\\Program Files (x86)\\Steam',
    'C:\\Program Files\\Steam',
    'D:\\Steam',
  ];

  static Future<String?> findSteamPath() async {
    // First check registry for Steam installation path
    try {
      var shell = Shell();
      var result = await shell.run(
        'reg query "HKEY_LOCAL_MACHINE\\SOFTWARE\\WOW6432Node\\Valve\\Steam" /v "InstallPath"',
      );
      
      if (result.first.exitCode == 0) {
        final output = result.first.stdout.toString();
        final match = RegExp(r'REG_SZ\s+(.+)').firstMatch(output);
        if (match != null) {
          return match.group(1)?.trim();
        }
      }
    } catch (e) {
      // Removed print statement
    }

    // If registry check fails, try default paths
    for (var steamPath in _defaultSteamPaths) {
      if (await Directory(steamPath).exists()) {
        return steamPath;
      }
    }

    return null;
  }

  static Future<List<String>> findLibraryFolders(String steamPath) async {
    final List<String> libraryFolders = [steamPath];
    final libraryFoldersFile = File(path.join(
      steamPath,
      'steamapps',
      'libraryfolders.vdf',
    ));

    if (await libraryFoldersFile.exists()) {
      final content = await libraryFoldersFile.readAsString();
      // Parse VDF format to find additional library paths
      final pathRegex = RegExp(r'"path"\s*"([^"]+)"');
      final matches = pathRegex.allMatches(content);
      
      for (var match in matches) {
        if (match.group(1) != null) {
          libraryFolders.add(match.group(1)!.replaceAll(r'\\', '\\'));
        }
      }
    }

    return libraryFolders;
  }

  static Future<List<SteamGame>> getInstalledGames() async {
    final List<SteamGame> games = [];
    final steamPath = await findSteamPath();
    
    if (steamPath == null) {
      // Removed print statement
      return games;
    }

    final libraryFolders = await findLibraryFolders(steamPath);

    for (var libraryPath in libraryFolders) {
      final appsPath = path.join(libraryPath, 'steamapps');
      final dir = Directory(appsPath);
      
      if (!await dir.exists()) continue;

      await for (var entity in dir.list()) {
        if (entity is File && path.basename(entity.path).startsWith('appmanifest_')) {
          try {
            final content = await File(entity.path).readAsString();
            
            // Extract app ID from filename
            final appId = path.basename(entity.path)
                .replaceAll('appmanifest_', '')
                .replaceAll('.acf', '');

            // Extract game name and install dir from manifest
            final nameMatch = RegExp(r'"name"\s*"([^"]+)"').firstMatch(content);
            final installDirMatch = RegExp(r'"installdir"\s*"([^"]+)"').firstMatch(content);

            if (nameMatch != null && installDirMatch != null) {
              final name = nameMatch.group(1)!;
              final installDir = path.join(
                appsPath,
                'common',
                installDirMatch.group(1)!,
              );

              // Find the main executable (usually matches the install directory name)
              final executablePath = await _findGameExecutable(installDir);
              
              if (executablePath != null) {
                games.add(SteamGame(
                  name: name,
                  appId: appId,
                  executablePath: executablePath,
                  installDir: installDir,
                ));
              }
            }
          } catch (e) {
            // Removed print statement
          }
        }
      }
    }

    return games;
  }

  static Future<String?> _findGameExecutable(String installDir) async {
    final dir = Directory(installDir);
    if (!await dir.exists()) return null;

    // List of common executable locations and patterns
    final executablePatterns = [
      RegExp(r'\.exe$', caseSensitive: false),
      RegExp(r'launcher\.exe$', caseSensitive: false),
      RegExp(r'game\.exe$', caseSensitive: false),
    ];

    List<FileSystemEntity> allFiles = [];
    await for (var entity in dir.list(recursive: true)) {
      if (entity is File) {
        for (var pattern in executablePatterns) {
          if (pattern.hasMatch(entity.path)) {
            allFiles.add(entity);
            break;
          }
        }
      }
    }

    // Sort files to prioritize executables in the root directory
    allFiles.sort((a, b) {
      final aDepth = path.split(a.path).length;
      final bDepth = path.split(b.path).length;
      return aDepth.compareTo(bDepth);
    });

    if (allFiles.isNotEmpty) {
      return allFiles.first.path;
    }

    return null;
  }
} 