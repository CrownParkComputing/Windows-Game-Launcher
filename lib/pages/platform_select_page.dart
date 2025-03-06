import 'package:flutter/material.dart';

class PlatformSelectPage extends StatefulWidget {
  const PlatformSelectPage({Key? key}) : super(key: key);

  @override
  State<PlatformSelectPage> createState() => _PlatformSelectPageState();
}

class _PlatformSelectPageState extends State<PlatformSelectPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[900]!,
              Colors.black,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Background animated pattern
            ...List.generate(20, (index) {
              final top = index * 50.0;
              return Positioned(
                top: top,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.1,
                      child: Transform.translate(
                        offset: Offset(
                          50 * _controller.value * (index % 2 == 0 ? 1 : -1),
                          0,
                        ),
                        child: Container(
                          height: 2,
                          color: Colors.blue[400],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title with fade-in animation
                  FadeTransition(
                    opacity: _fadeInAnimation,
                    child: const Text(
                      'GAME LAUNCHER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            color: Colors.blue,
                            blurRadius: 10,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Platform button with slide-up animation
                  SlideTransition(
                    position: _slideAnimation,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => setState(() => _isHovered = true),
                      onExit: (_) => setState(() => _isHovered = false),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/main');
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isHovered ? 320 : 300,
                          height: _isHovered ? 90 : 80,
                          decoration: BoxDecoration(
                            color: _isHovered ? Colors.blue[600] : Colors.blue[700],
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(_isHovered ? 0.7 : 0.5),
                                spreadRadius: _isHovered ? 4 : 2,
                                blurRadius: _isHovered ? 15 : 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.blue[300]!,
                              width: _isHovered ? 3 : 2,
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.computer,
                                  color: Colors.white,
                                  size: _isHovered ? 36 : 32,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'PC GAMES',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: _isHovered ? 28 : 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Version text at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: FadeTransition(
                opacity: _fadeInAnimation,
                child: const Text(
                  'Version 1.0',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 