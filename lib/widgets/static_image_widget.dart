import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/logger.dart';
import '../settings_provider.dart';
import '../utils/static_image_manager.dart';

class StaticImageWidget extends StatefulWidget {
  final double width;
  final double height;
  final String sectionKey;
  final bool isEditMode;
  final SettingsProvider settingsProvider;
  
  const StaticImageWidget({
    Key? key,
    required this.width,
    required this.height,
    required this.sectionKey,
    required this.isEditMode,
    required this.settingsProvider,
  }) : super(key: key);

  @override
  State<StaticImageWidget> createState() => _StaticImageWidgetState();
}

class _StaticImageWidgetState extends State<StaticImageWidget> with SingleTickerProviderStateMixin {
  String? _imagePath;
  bool _isLoading = false;
  bool _hasError = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // Set up animation controller for hover effects
    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Load the initial image path
    _loadImagePath();
    
    // Listen for changes to the static image path
    widget.settingsProvider.addListener(_handleSettingsChanged);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    widget.settingsProvider.removeListener(_handleSettingsChanged);
    super.dispose();
  }
  
  void _handleSettingsChanged() {
    _loadImagePath();
  }
  
  void _loadImagePath() {
    final StaticImageManager imageManager = StaticImageManager();
    final String? path = imageManager.getStaticImagePath(widget.settingsProvider, widget.sectionKey);
    
    setState(() {
      _imagePath = path;
      _hasError = false;
    });
  }
  
  Future<void> _selectImage() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final StaticImageManager imageManager = StaticImageManager();
      final String? path = await imageManager.pickStaticImage(widget.settingsProvider, widget.sectionKey);
      
      if (path != null) {
        setState(() {
          _imagePath = path;
          _hasError = false;
        });
      }
    } catch (e) {
      Logger.error('Error selecting static image: $e', source: 'StaticImageWidget');
      setState(() {
        _hasError = true;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _clearImage() {
    final StaticImageManager imageManager = StaticImageManager();
    imageManager.clearStaticImage(widget.settingsProvider, widget.sectionKey);
    
    setState(() {
      _imagePath = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }
    
    if (_imagePath == null) {
      return _buildEmptyState();
    }
    
    final bool fileExists = File(_imagePath!).existsSync();
    if (!fileExists || _hasError) {
      return _buildErrorState();
    }
    
    return _buildImageDisplay();
  }
  
  Widget _buildLoadingState() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading image...',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: widget.isEditMode 
            ? Border.all(color: Colors.blue.withOpacity(0.5), width: 2) 
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'No static image selected',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (widget.isEditMode)
              ElevatedButton.icon(
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Select Image'),
                onPressed: _selectImage,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.7), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.broken_image,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error loading image',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              _imagePath ?? 'Unknown path',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_photo_alternate),
                  label: const Text('Select New Image'),
                  onPressed: _selectImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Clear'),
                  onPressed: _clearImage,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildImageDisplay() {
    return MouseRegion(
      onEnter: (_) => _animationController.forward(),
      onExit: (_) => _animationController.reverse(),
      child: GestureDetector(
        onTap: widget.isEditMode ? _selectImage : null,
        child: Stack(
          children: [
            // Animated image container
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isEditMode ? _scaleAnimation.value : 1.0,
                  child: Container(
                    width: widget.width,
                    height: widget.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: widget.isEditMode 
                          ? Border.all(
                              color: Colors.blue.withOpacity(0.5 + (_animationController.value * 0.5)), 
                              width: 2 + (_animationController.value * 2)
                            ) 
                          : null,
                      boxShadow: widget.isEditMode ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.2 + (_animationController.value * 0.3)),
                          blurRadius: 8 + (_animationController.value * 8),
                          spreadRadius: 2 + (_animationController.value * 2),
                        )
                      ] : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                        width: widget.width,
                        height: widget.height,
                      ),
                    ),
                  ),
                );
              },
            ),
            
            // Edit controls overlay (only in edit mode)
            if (widget.isEditMode)
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedOpacity(
                  opacity: _animationController.value,
                  duration: const Duration(milliseconds: 150),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _selectImage,
                        tooltip: 'Change Image',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: _clearImage,
                        tooltip: 'Remove Image',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 