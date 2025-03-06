import 'package:flutter/material.dart';
import '../utils/window_utils.dart';

class CustomWindowAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomWindowAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(32);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        WindowUtils.startWindowDrag();
      },
      child: Container(
        color: Colors.grey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: GestureDetector(
                onDoubleTap: () => WindowUtils.toggleMaximize(),
                child: const SizedBox(
                  height: double.infinity,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.crop_square, size: 16),
              onPressed: () => WindowUtils.toggleMaximize(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
} 