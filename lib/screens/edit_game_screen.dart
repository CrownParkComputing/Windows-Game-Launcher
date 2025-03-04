import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/file_picker_utils.dart';
import '../models/game_config.dart';
import '../settings_provider.dart';

class EditGameScreen extends StatefulWidget {
  final GameConfig game;
  final int gameIndex;

  const EditGameScreen({
    Key? key,
    required this.game,
    required this.gameIndex,
  }) : super(key: key);

  @override
  _EditGameScreenState createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _executablePathController;
  late TextEditingController _logoPathController;
  late TextEditingController _videoPathController;
  late TextEditingController _storyTextController;

  final String _artworkBasePath = r'E:\Driving\medium_artwork';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.game.name);
    _executablePathController =
        TextEditingController(text: widget.game.executablePath);
    _logoPathController = TextEditingController(text: widget.game.logoPath);
    _videoPathController = TextEditingController(text: widget.game.videoPath);
    _storyTextController = TextEditingController(text: widget.game.storyText);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _executablePathController.dispose();
    _logoPathController.dispose();
    _videoPathController.dispose();
    _storyTextController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(
      TextEditingController controller, String fileType) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? result;
      if (fileType == 'executable') {
        result = await FilePickerUtils.pickGameExecutable(context);
      } else if (fileType == 'image') {
        result = await FilePickerUtils.pickImageFile(
          context,
          initialDirectory: _artworkBasePath,
        );
      } else if (fileType == 'video') {
        result = await FilePickerUtils.pickVideoFile(context);
      } else if (fileType == 'text') {
        result = await FilePickerUtils.pickStoryFile(context);
      }

      if (result != null) {
        setState(() {
          controller.text = result!; // Using ! since we know it's not null here
        });
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _browseArtworkDirectory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (Directory(_artworkBasePath).existsSync()) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Artwork Directory'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: _buildDirectoryExplorer(_artworkBasePath),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Directory not found: $_artworkBasePath'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDirectoryExplorer(String path) {
    try {
      final dir = Directory(path);
      final List<FileSystemEntity> entities = dir.listSync()
        ..sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));

      return ListView.builder(
        itemCount: entities.length,
        itemBuilder: (context, index) {
          final entity = entities[index];
          final name = entity.path.split(Platform.pathSeparator).last;
          final isDirectory = entity is Directory;

          return ListTile(
            leading: Icon(isDirectory ? Icons.folder : _getFileIcon(name)),
            title: Text(name),
            onTap: () {
              if (isDirectory) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: Text(name)),
                      body: _buildDirectoryExplorer(entity.path),
                    ),
                  ),
                );
              } else {
                // Handle file selection based on type
                if (name.toLowerCase().endsWith('.jpg') ||
                    name.toLowerCase().endsWith('.jpeg') ||
                    name.toLowerCase().endsWith('.png') ||
                    name.toLowerCase().endsWith('.gif') ||
                    name.toLowerCase().endsWith('.webp') ||
                    name.toLowerCase().endsWith('.bmp')) {
                  setState(() {
                    _logoPathController.text = entity.path;
                  });
                } else if (name.toLowerCase().endsWith('.mp4') ||
                    name.toLowerCase().endsWith('.webm') ||
                    name.toLowerCase().endsWith('.mov') ||
                    name.toLowerCase().endsWith('.avi') ||
                    name.toLowerCase().endsWith('.mkv') ||
                    name.toLowerCase().endsWith('.wmv')) {
                  setState(() {
                    _videoPathController.text = entity.path;
                  });
                } else if (name.toLowerCase().endsWith('.txt')) {
                  setState(() {
                    _storyTextController.text = await File(entity.path).readAsString();
                  });
                }
                Navigator.of(context).pop();
              }
            },
          );
        },
      );
    } catch (e) {
      return Center(child: Text('Error loading directory: $e'));
    }
  }

  IconData _getFileIcon(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.jpg') ||
        lowerName.endsWith('.jpeg') ||
        lowerName.endsWith('.png') ||
        lowerName.endsWith('.gif') ||
        lowerName.endsWith('.webp') ||
        lowerName.endsWith('.bmp')) {
      return Icons.image;
    } else if (lowerName.endsWith('.mp4') ||
        lowerName.endsWith('.webm') ||
        lowerName.endsWith('.mov') ||
        lowerName.endsWith('.avi') ||
        lowerName.endsWith('.mkv') ||
        lowerName.endsWith('.wmv')) {
      return Icons.movie;
    } else if (lowerName.endsWith('.txt')) {
      return Icons.description;
    } else {
      return Icons.insert_drive_file;
    }
  }

  void _saveGame() {
    if (_formKey.currentState!.validate()) {
      final updatedGame = GameConfig(
        name: _nameController.text,
        executablePath: _executablePathController.text,
        logoPath: _logoPathController.text,
        videoPath: _videoPathController.text,
        storyText: _storyTextController.text,
      );

      Provider.of<SettingsProvider>(context, listen: false)
          .updateGame(widget.gameIndex, updatedGame);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Game'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: _browseArtworkDirectory,
            tooltip: 'Browse Artwork Directory',
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Game Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a game name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _executablePathController,
                            decoration: const InputDecoration(
                              labelText: 'Executable Path',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the executable path';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _pickFile(
                              _executablePathController, 'executable'),
                          child: const Text('Browse'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _logoPathController,
                            decoration: const InputDecoration(
                              labelText: 'Logo Path (Optional)',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Images from E:\\Driving\\medium_artwork',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _pickFile(_logoPathController, 'image'),
                          child: const Text('Browse'),
                        ),
                      ],
                    ),
                    if (_logoPathController.text.isNotEmpty &&
                        File(_logoPathController.text).existsSync())
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Image.file(
                            File(_logoPathController.text),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _videoPathController,
                            decoration: const InputDecoration(
                              labelText: 'Video Path (Optional)',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Videos from E:\\Driving\\medium_artwork (will play continuously)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () =>
                              _pickFile(_videoPathController, 'video'),
                          child: const Text('Browse'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _storyTextController,
                            maxLines: 10,
                            decoration: const InputDecoration(
                              labelText: 'Story Text',
                              border: OutlineInputBorder(),
                              hintText: 'Enter story text for this game',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _pickFile(_storyTextController, 'text'),
                          child: const Text('Browse'),
                        ),
                      ],
                    ),
                    if (_storyTextController.text.isNotEmpty)
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(_storyTextController.text),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: _saveGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: Text('Save Changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
