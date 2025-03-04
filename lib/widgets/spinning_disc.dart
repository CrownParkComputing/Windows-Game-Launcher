import 'dart:io';
import 'package:flutter/material.dart';

class SpinningDisc extends StatefulWidget {
  final String imagePath;
  final double size;

  const SpinningDisc({
    Key? key,
    required this.imagePath,
    this.size = 200,
  }) : super(key: key);

  @override
  _SpinningDiscState createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<SpinningDisc>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RotationTransition(
        turns: _controller,
        child: ClipOval(
          child: Image.file(
            File(widget.imagePath),
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
