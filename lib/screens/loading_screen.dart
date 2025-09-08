import 'package:flutter/material.dart';
import 'dart:async';

class LoadingScreen extends StatefulWidget {
  final Widget nextScreen;
  final String loadingText;
  final int durationSeconds;

  const LoadingScreen({
    Key? key,
    required this.nextScreen,
    this.loadingText = 'Memuat aplikasi...',
    this.durationSeconds = 3,
  }) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _textController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _progress;
  late Animation<double> _textOpacity;

  String _currentText = '';
  Timer? _textTimer;
  int _textIndex = 0;

  final List<String> _loadingMessages = [
    'Menyiapkan database...',
    'Memuat produk...',
    'Mengecek stok...',
    'Hampir selesai...',
  ];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startLoadingSequence();
  }

  void _initAnimations() {
    // Logo animation
    _logoController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _logoScale = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    ));

    // Progress animation
    _progressController = AnimationController(
      duration: Duration(seconds: widget.durationSeconds),
      vsync: this,
    );

    _progress = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Text animation
    _textController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _textOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_textController);
  }

  void _startLoadingSequence() async {
    // Start logo animation
    _logoController.forward();

    // Wait a bit then start progress
    await Future.delayed(Duration(milliseconds: 500));
    _progressController.forward();

    // Start text cycling
    _startTextCycling();

    // Navigate to next screen after loading completes
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToNextScreen();
      }
    });
  }

  void _startTextCycling() {
    _textTimer = Timer.periodic(Duration(milliseconds: 800), (timer) {
      if (_textIndex < _loadingMessages.length) {
        setState(() {
          _currentText = _loadingMessages[_textIndex];
        });
        _textController.reset();
        _textController.forward();
        _textIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  void _navigateToNextScreen() async {
    await Future.delayed(Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    _textController.dispose();
    _textTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _logoScale.value,
                          child: Transform.rotate(
                            angle: _logoRotation.value * 0.1,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.store,
                                color: Colors.red,
                                size: 60,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 30),

                    // App Name
                    Text(
                      'SRC Rudi',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 10),

                    Text(
                      'Sistem Kasir Toko Kelontong',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),

                    SizedBox(height: 50),

                    // Progress Bar Container
                    Container(
                      width: 250,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: AnimatedBuilder(
                        animation: _progress,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: _progress.value,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 20),

                    // Progress Percentage
                    AnimatedBuilder(
                      animation: _progress,
                      builder: (context, child) {
                        return Text(
                          '${(_progress.value * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 30),

                    // Loading Text
                    Container(
                      height: 50,
                      child: AnimatedBuilder(
                        animation: _textOpacity,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _textOpacity.value,
                            child: Text(
                              _currentText,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  // Loading Dots Animation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          double delay = index * 0.2;
                          double progress = (_progressController.value - delay).clamp(0.0, 1.0);
                          double opacity = (progress * 2).clamp(0.0, 1.0);
                          if (progress > 0.5) {
                            opacity = 2 - (progress * 2);
                          }
                          
                          return Container(
                            margin: EdgeInsets.symmetric(horizontal: 3),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(opacity),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      );
                    }),
                  ),

                  SizedBox(height: 20),

                  // Version Info
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}