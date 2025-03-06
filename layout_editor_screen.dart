import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LayoutEditorScreen extends StatefulWidget {
  const LayoutEditorScreen({super.key});
  // ... (existing code)
}

class _LayoutEditorScreenState extends State<LayoutEditorScreen> {
  // ... (existing code)

  Widget _buildSection(String sectionKey) {
    final mediaType = _getSectionMediaType(sectionKey);
    final staticImagePath = widget.settingsProvider.getStaticImagePath(sectionKey);

    if (mediaType == 'static_image' && staticImagePath != null && staticImagePath.isNotEmpty) {
      return Image.file(File(staticImagePath));
    } else if (mediaType == 'logo' && staticImagePath != null && staticImagePath.isNotEmpty) {
      // If the media type is 'logo' but we have a static image path, use the static image
      return Image.file(File(staticImagePath));
    } else {
      // Existing rendering logic for other media types
      switch (mediaType) {
        case 'logo':
          return Image.asset('assets/images/logo.png');
        case 'artwork_front':
          return Image.asset('assets/images/artwork_front.png');
        case 'artwork_3d':
          return Image.asset('assets/images/artwork_3d.png');
        case 'fanart':
          return Image.asset('assets/images/fanart.jpg');
        case 'video':
          // Get the video aspect ratio from settings or use default 16:9
          final aspectRatio = widget.settingsProvider.getVideoAspectRatio(sectionKey) ?? 16/9;
          
          // Get the layout dimensions for the section
          double containerWidth, containerHeight;
          switch(sectionKey) {
            case 'left':
              containerWidth = widget.settingsProvider.leftMarginWidth;
              containerHeight = MediaQuery.of(context).size.height - 
                              widget.settingsProvider.topMarginHeight -
                              widget.settingsProvider.bottomMarginHeight;
              break;
            case 'right':
              containerWidth = widget.settingsProvider.rightMarginWidth;
              containerHeight = MediaQuery.of(context).size.height - 
                              widget.settingsProvider.topMarginHeight -
                              widget.settingsProvider.bottomMarginHeight;
              break;
            case 'top':
              containerWidth = MediaQuery.of(context).size.width;
              containerHeight = widget.settingsProvider.topMarginHeight;
              break;
            case 'top_left':
              containerWidth = widget.settingsProvider.topLeftWidth;
              containerHeight = widget.settingsProvider.topMarginHeight;
              break;
            case 'top_center':
              containerWidth = widget.settingsProvider.topCenterWidth;
              containerHeight = widget.settingsProvider.topMarginHeight;
              break;
            case 'top_right':
              containerWidth = widget.settingsProvider.topRightWidth;
              containerHeight = widget.settingsProvider.topMarginHeight;
              break;
            case 'bottom':
              containerWidth = MediaQuery.of(context).size.width;
              containerHeight = widget.settingsProvider.bottomMarginHeight;
              break;
            case 'main':
              containerWidth = MediaQuery.of(context).size.width - 
                            widget.settingsProvider.leftMarginWidth -
                            widget.settingsProvider.rightMarginWidth;
              containerHeight = MediaQuery.of(context).size.height - 
                              widget.settingsProvider.topMarginHeight -
                              widget.settingsProvider.bottomMarginHeight;
              break;
            default:
              containerWidth = 200;
              containerHeight = 200;
          }
          
          final containerAspectRatio = containerWidth / containerHeight;
          
          double videoWidth, videoHeight;
          
          // Adjust dimensions to maintain aspect ratio
          if (containerAspectRatio > aspectRatio) {
            // Container is wider than the video aspect ratio
            videoHeight = containerHeight;
            videoWidth = videoHeight * aspectRatio;
          } else {
            // Container is taller than the video aspect ratio
            videoWidth = containerWidth;
            videoHeight = videoWidth / aspectRatio;
          }
          
          print("Video widget in section $sectionKey:");
          print("  Container dimensions: $containerWidth x $containerHeight (ratio: $containerAspectRatio)");
          print("  Video dimensions: $videoWidth x $videoHeight (ratio: $aspectRatio)");
          
          return Center(
            child: SizedBox(
              width: videoWidth,
              height: videoHeight,
              child: VideoPlayer(_videoController),
            ),
          );
        default:
          return Container();
      }
    }
  }

  // ... (rest of the existing code)
} 