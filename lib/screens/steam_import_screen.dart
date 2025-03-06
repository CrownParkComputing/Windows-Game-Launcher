import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import '../utils/steam_utils.dart';
import '../settings_provider.dart';
import '../models/game_config.dart';

class SteamImportScreen extends StatefulWidget {
  const SteamImportScreen({super.key});

  @override
  State<SteamImportScreen> createState() => _SteamImportScreenState();
}

class _SteamImportScreenState extends State<SteamImportScreen> {
  List<SteamGame> _steamGames = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _selectedGames = {};

  @override
  void initState() {
    super.initState();
    _loadSteamGames();
  }

  Future<void> _loadSteamGames() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final games = await SteamUtils.getInstalledGames();
      setState(() {
        _steamGames = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load Steam games: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _importSelectedGames(BuildContext context) async {
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final selectedGames = _steamGames.where((game) => _selectedGames.contains(game.appId));

    for (var game in selectedGames) {
      // Create artwork directory
      final artworkDir = path.join(
        path.dirname(game.executablePath),
        'artwork',
      );
      
      try {
        await Directory(artworkDir).create(recursive: true);
      } catch (e) {
        // Removed print statement
      }

      // Add game to settings
      final gameConfig = GameConfig(
        name: game.name,
        executablePath: game.executablePath,
        logoPath: path.join(artworkDir, 'cover.jpg'),
        bannerPath: path.join(artworkDir, 'background.jpg'),
      );
      settingsProvider.addGame(gameConfig);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${_selectedGames.length} games'),
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Steam Games'),
        actions: [
          if (_selectedGames.isNotEmpty)
            TextButton.icon(
              onPressed: () => _importSelectedGames(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'Import ${_selectedGames.length} Games',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadSteamGames,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _steamGames.isEmpty
                  ? const Center(
                      child: Text('No Steam games found'),
                    )
                  : ListView.builder(
                      itemCount: _steamGames.length,
                      itemBuilder: (context, index) {
                        final game = _steamGames[index];
                        return CheckboxListTile(
                          title: Text(game.name),
                          subtitle: Text(game.executablePath),
                          value: _selectedGames.contains(game.appId),
                          onChanged: (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedGames.add(game.appId);
                              } else {
                                _selectedGames.remove(game.appId);
                              }
                            });
                          },
                        );
                      },
                    ),
    );
  }
} 