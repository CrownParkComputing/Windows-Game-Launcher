import 'dart:ui';
import 'package:flutter/material.dart';
import '../settings_provider.dart';

/// A widget that displays a glass-like effect in normal mode,
/// and a minimal UI in edit mode to indicate its presence
class TransparentWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool isEditMode;
  final SettingsProvider? settingsProvider;
  
  const TransparentWidget({
    Key? key,
    required this.width,
    required this.height,
    required this.isEditMode,
    this.settingsProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // In normal mode, show either a transparent widget or a glass effect
    if (!isEditMode) {
      // If glass effect is disabled or settingsProvider is not provided, show completely transparent widget
      final bool useGlassEffect = settingsProvider?.useGlassEffect ?? false;
      
      if (!useGlassEffect) {
        // Completely transparent
        return const SizedBox.shrink();
      }
      
      // Glass effect enabled - show a subtle glass effect
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Reduced blur
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(0.05), // Reduced opacity
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 0.5,
              ),
            ),
            // Minimal sheen effect
            child: CustomPaint(
              painter: GlassSheenPainter(subtle: true),
              size: Size(width, height),
            ),
          ),
        ),
      );
    }
    
    // In edit mode, show a minimal UI so the user knows it's there
    final bool useGlassEffect = settingsProvider?.useGlassEffect ?? false;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(
          color: useGlassEffect ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(12),
        color: useGlassEffect ? Colors.white.withOpacity(0.1) : Colors.transparent,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              useGlassEffect ? Icons.blur_on : Icons.visibility_off,
              size: 36,
              color: useGlassEffect ? Colors.white.withOpacity(0.7) : Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              useGlassEffect ? 'GLASS PANEL' : 'TRANSPARENT',
              style: TextStyle(
                color: useGlassEffect ? Colors.white.withOpacity(0.8) : Colors.grey.withOpacity(0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter to add a subtle glass sheen effect
class GlassSheenPainter extends CustomPainter {
  final bool subtle;
  
  GlassSheenPainter({this.subtle = false});
  
  @override
  void paint(Canvas canvas, Size size) {
    if (subtle) {
      // Very subtle highlight for minimal glass effect
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: const Alignment(0.2, 0.2),
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.0),
          ],
          stops: const [0.0, 0.2],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
        
      // Smaller highlight in corner
      final highlightPath = Path()
        ..moveTo(0, 0)
        ..lineTo(size.width * 0.3, 0)
        ..lineTo(0, size.height * 0.3)
        ..close();
        
      canvas.drawPath(highlightPath, paint);
      
      // Very subtle top edge
      final topPaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
        
      canvas.drawLine(
        Offset(size.width * 0.1, 1),
        Offset(size.width * 0.9, 1),
        topPaint,
      );
      
      return;
    }
    
    // Original, more pronounced effect - now only used if subtle is false
    // Draw a subtle diagonal highlight
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: const Alignment(0.3, 0.3),
        colors: [
          Colors.white.withOpacity(0.4),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
    // Create a path for the top-left highlight
    final highlightPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(0, size.height * 0.5)
      ..close();
      
    canvas.drawPath(highlightPath, paint);
    
    // Add a subtle top edge highlight
    final topPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
      
    canvas.drawLine(
      Offset(size.width * 0.05, 2),
      Offset(size.width * 0.95, 2),
      topPaint,
    );
    
    // Add a subtle bottom edge shadow
    final bottomPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
      
    canvas.drawLine(
      Offset(size.width * 0.1, size.height - 1),
      Offset(size.width * 0.9, size.height - 1),
      bottomPaint,
    );
    
    // Add small circular highlight in top-left corner
    final highlightCirclePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(
      Offset(size.width * 0.08, size.height * 0.08),
      size.width * 0.02,
      highlightCirclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 