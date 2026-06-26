import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/database_helper.dart';
import 'dashboard_screen.dart';
import 'signin_screen.dart';
import '../widgets/curved_text_painter.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _rotationController;
  int _currentPage = 0;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  Color get primaryColor => isDark ? const Color(0xFFF4EFEA) : const Color(0xFF3A3530);
  Color get secondaryColor => isDark ? const Color(0xFFA89E95) : const Color(0xFF3A3530).withOpacity(0.6);
  Color get cardColor => isDark ? const Color(0xFF2C2621) : const Color(0xFFFFEAD9);
  Color get scaffoldColor => isDark ? const Color(0xFF1A1816) : const Color(0xFFFDFCFB);
  Color get borderColor => isDark ? const Color(0xFF2C2621) : const Color(0xFFE2D1C3);

  @override
  void initState() {
    super.initState();
    // Continuous slow rotation for the circular curved text on slide 1
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await DatabaseHelper.instance.setSetting('completed_onboarding', 'true');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const SignInScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: scaleAnimation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Stack(
        children: [
          // Background Atmospheric blur glowing circles (warm taupe)
          Positioned(
            top: 100,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE2D1C3).withOpacity(isDark ? 0.06 : 0.15),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE2D1C3).withOpacity(isDark ? 0.04 : 0.1),
              ),
            ),
          ),

          // Main Layout Content
          Column(
            children: [
              // Header Controls (with top safe area padding)
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App branding
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.architecture_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'CurveType',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      // Skip button
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(
                          'SKIP',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: secondaryColor,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // PageView slides (expanded to take remaining vertical space)
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildSlide1(),
                    _buildSlide2(),
                    _buildSlide3(),
                  ],
                ),
              ),

              // Bottom Controls & Descriptions (Soft Peach Card Layer)
              Container(
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 32.0,
                  bottom: MediaQuery.of(context).padding.bottom + 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        _getSlideTitle(_currentPage),
                        key: ValueKey<int>(_currentPage),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Description
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 310),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          _getSlideDescription(_currentPage),
                          key: ValueKey<int>(_currentPage),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: secondaryColor,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Pagination Dots - Warm Taupe Active, Clean Cream Inactive
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final bool isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 6,
                          width: isActive ? 20 : 6,
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xFFE2D1C3) : scaffoldColor,
                            borderRadius: BorderRadius.circular(3),
                            border: isActive ? null : Border.all(color: const Color(0xFFE2D1C3), width: 0.5),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFE2D1C3).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // High-performance Warm Taupe Pill button with 20px corners
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentPage == 2 ? 220 : 180,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black.withOpacity(0.15) : const Color(0xFF3A3530).withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2D1C3),
                          foregroundColor: const Color(0xFF3A3530),
                          elevation: 0, // handled by box decoration shadow
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage == 2 ? 'GET STARTED' : 'NEXT',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedSlide(
                              offset: Offset(_currentPage == 2 ? 0.2 : 0.0, 0),
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _currentPage == 2 ? Icons.done_all_rounded : Icons.east_rounded,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlideContainer({required Widget child}) {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double targetHeight = math.min(350.0, constraints.maxHeight * 0.95);
          final double targetWidth = targetHeight * (280.0 / 350.0);
          
          return Container(
            width: targetWidth,
            height: targetHeight,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20), // Kinetic Curve standard 20px radius
              border: Border.all(color: borderColor, width: 1.5), // Subtle taupe boundary border
              boxShadow: [
                BoxShadow(
                  color: isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF3A3530).withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlide1() {
    return _buildSlideContainer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Nordic fjord image background
          Image.asset(
            'assets/images/onboarding_bg.png',
            fit: BoxFit.cover,
          ),
          // Subtle dark-cream gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  scaffoldColor.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Rotating Curved Text layer overlay
          Center(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: CurvedTextPainter(
                      text: 'SCULPT YOUR WORDS • SCULPT YOUR WORDS • ',
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      color: primaryColor, // Charcoal-Taupe / Cream
                      strokeWidth: 0.0,
                      letterSpacing: 2.2,
                      curvature: 90.0, // circular curvature
                      opacity: 1.0,
                    ),
                  ),
                );
              },
            ),
          ),
          // Center interaction indicator
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardColor,
                border: Border.all(color: primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.1),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.gesture,
                  color: primaryColor,
                  size: 24,
                ),
              ),
            ),
          ),
          // Floating interaction badge
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Text(
                  'INTERACTIVE CANVAS',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    return _buildSlideContainer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Nordic fjord background with simulated filters (brighter, higher contrast)
          ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              1.2, 0, 0, 0, 10,
              0, 1.2, 0, 0, 10,
              0, 0, 1.2, 0, 10,
              0, 0, 0, 1, 0,
            ]),
            child: Image.asset(
              'assets/images/onboarding_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  scaffoldColor.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Floating Sliders HUD overlay
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSimulatedSlider('BRIGHTNESS', 0.6),
                const SizedBox(height: 12),
                _buildSimulatedSlider('CONTRAST', 0.8),
                const SizedBox(height: 12),
                _buildSimulatedSlider('SATURATION', 0.4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide3() {
    return _buildSlideContainer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/onboarding_bg.png',
            fit: BoxFit.cover,
          ),
          Container(
            color: scaffoldColor.withOpacity(0.3),
          ),
          // Download Arrow Animation & Checkmark
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardColor,
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: primaryColor,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'EXPORT SUCCESSFUL',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Saved to Photo Gallery',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: secondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulatedSlider(String label, double progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 4,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: scaffoldColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2D1C3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getSlideTitle(int page) {
    switch (page) {
      case 0:
        return 'Sculpt Your Words';
      case 1:
        return 'Precision Editing';
      case 2:
        return 'Instant Export';
      default:
        return '';
    }
  }

  String _getSlideDescription(int page) {
    switch (page) {
      case 0:
        return 'Curve, rotate, and style your text in real time with intuitive gestures.';
      case 1:
        return 'Adjust contrast, brightness, saturation, and crop to create the perfect background.';
      case 2:
        return 'Save your creations at multiple quality levels directly to your device photo gallery.';
      default:
        return '';
    }
  }
}
