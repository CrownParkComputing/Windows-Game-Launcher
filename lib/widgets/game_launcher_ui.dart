import 'package:flutter/material.dart';
import 'dart:io';
import '../screens/batch_game_setup_screen.dart';
import '../models/game_config.dart';
import 'resizable_section.dart';
import '../controllers/layout_manager.dart';
import '../settings_provider.dart';

class GameLauncherAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final GameConfig? selectedGame;
  final VoidCallback onEditModeToggle;
  final VoidCallback onOpenGameManager;
  final bool isEditMode;

  const GameLauncherAppBar({
    Key? key,
    required this.selectedGame,
    required this.onEditModeToggle,
    required this.onOpenGameManager,
    required this.isEditMode,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(40);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(40),
      child: Container(
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                selectedGame != null ? selectedGame!.name : 'Game Launcher',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    isEditMode ? Icons.lock : Icons.edit,
                    color: Colors.white,
                  ),
                  onPressed: onEditModeToggle,
                  tooltip: isEditMode ? 'Lock Layout' : 'Edit Layout',
                ),
                TextButton.icon(
                  icon: const Icon(Icons.folder_open, color: Colors.white),
                  label: const Text('Manage Games',
                      style: TextStyle(color: Colors.white)),
                  onPressed: onOpenGameManager,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => exit(0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyGamesPlaceholder extends StatelessWidget {
  final VoidCallback onOpenGameManager;

  const EmptyGamesPlaceholder({
    Key? key,
    required this.onOpenGameManager,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No games available. Add games to get started.',
            style: TextStyle(fontSize: 18, color: Colors.white70),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('MANAGE GAMES'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            onPressed: onOpenGameManager,
          ),
        ],
      ),
    );
  }
}

class GameLayout extends StatelessWidget {
  final LayoutManager layoutManager;
  final SettingsProvider settingsProvider;
  final bool isEditMode;
  final int selectedGameIndex;
  final Function(int) onGameSelected;

  const GameLayout({
    Key? key,
    required this.layoutManager,
    required this.settingsProvider,
    required this.isEditMode,
    required this.selectedGameIndex,
    required this.onGameSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxMarginWidth = screenSize.width * 0.35;
    final maxMarginHeight = screenSize.height * 0.35;

    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Ensure we have valid minimum heights
          final safeTopMarginHeight = layoutManager.topMarginHeight
              .clamp(10.0, constraints.maxHeight * 0.4);
          final safeBottomMarginHeight = layoutManager.bottomMarginHeight
              .clamp(10.0, constraints.maxHeight * 0.4);

          // Ensure the center area has at least a minimum height
          final centerHeight = (constraints.maxHeight -
                  safeTopMarginHeight -
                  safeBottomMarginHeight)
              .clamp(50.0, constraints.maxHeight);

          return Column(
            children: [
              // Top margin
              SizedBox(
                height: safeTopMarginHeight,
                width: constraints.maxWidth,
                child: ResizableSection(
                  width: constraints.maxWidth,
                  height: safeTopMarginHeight,
                  mediaType: settingsProvider.selectedTopImage,
                  isVertical: true,
                  onResize: (delta) {
                    if (isEditMode) {
                      layoutManager.adjustTopMargin(delta, maxMarginHeight);
                    }
                  },
                  sectionKey: 'top',
                  isEditMode: isEditMode,
                  settingsProvider: settingsProvider,
                  selectedGameIndex: selectedGameIndex,
                  onGameSelected: onGameSelected,
                ),
              ),

              // Center section with margins
              SizedBox(
                height: centerHeight,
                child: Row(
                  children: [
                    // Left margin
                    SizedBox(
                      width: layoutManager.leftMarginWidth
                          .clamp(10.0, constraints.maxWidth * 0.4),
                      child: ResizableSection(
                        width: layoutManager.leftMarginWidth
                            .clamp(10.0, constraints.maxWidth * 0.4),
                        height: centerHeight,
                        mediaType: settingsProvider.selectedLeftImage,
                        isVertical: false,
                        onResize: (delta) {
                          if (isEditMode) {
                            layoutManager.adjustLeftMargin(
                                delta, maxMarginWidth);
                          }
                        },
                        sectionKey: 'left',
                        isEditMode: isEditMode,
                        settingsProvider: settingsProvider,
                        selectedGameIndex: selectedGameIndex,
                        onGameSelected: onGameSelected,
                      ),
                    ),

                    // Main view - ensure it has at least a minimum width
                    Expanded(
                      child: _buildMainView(BoxConstraints(
                          minWidth: 50,
                          maxWidth: constraints.maxWidth,
                          minHeight: centerHeight,
                          maxHeight: centerHeight)),
                    ),

                    // Right margin
                    SizedBox(
                      width: layoutManager.rightMarginWidth
                          .clamp(10.0, constraints.maxWidth * 0.4),
                      child: ResizableSection(
                        width: layoutManager.rightMarginWidth
                            .clamp(10.0, constraints.maxWidth * 0.4),
                        height: centerHeight,
                        mediaType: settingsProvider.selectedRightImage,
                        isVertical: false,
                        onResize: (delta) {
                          if (isEditMode) {
                            layoutManager.adjustRightMargin(
                                delta, maxMarginWidth);
                          }
                        },
                        sectionKey: 'right',
                        isEditMode: isEditMode,
                        settingsProvider: settingsProvider,
                        selectedGameIndex: selectedGameIndex,
                        onGameSelected: onGameSelected,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom margin
              SizedBox(
                height: safeBottomMarginHeight,
                width: constraints.maxWidth,
                child: ResizableSection(
                  width: constraints.maxWidth,
                  height: safeBottomMarginHeight,
                  mediaType: settingsProvider.selectedBottomImage,
                  isVertical: true,
                  onResize: (delta) {
                    if (isEditMode) {
                      layoutManager.adjustBottomMargin(delta, maxMarginHeight);
                    }
                  },
                  sectionKey: 'bottom',
                  isEditMode: isEditMode,
                  settingsProvider: settingsProvider,
                  selectedGameIndex: selectedGameIndex,
                  onGameSelected: onGameSelected,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainView(BoxConstraints constraints) {
    return LayoutBuilder(
      builder: (context, centerConstraints) {
        final size = centerConstraints.maxWidth < centerConstraints.maxHeight
            ? centerConstraints.maxWidth
            : centerConstraints.maxHeight;
        return Center(
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black38,
              border: Border.all(color: Colors.grey[850]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ResizableSection(
              width: size,
              height: size,
              mediaType: settingsProvider.selectedMainImage,
              isVertical: false,
              onResize: (delta) {}, // Main view doesn't need resizing
              sectionKey: 'main',
              isEditMode: isEditMode,
              settingsProvider: settingsProvider,
              selectedGameIndex: selectedGameIndex,
              onGameSelected: onGameSelected,
            ),
          ),
        );
      },
    );
  }
}
