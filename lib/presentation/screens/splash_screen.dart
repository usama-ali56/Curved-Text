import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/database_helper.dart';
import '../state/auth_state.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';
import 'signin_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();

    // Pulse animation for logo glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Continuous rotation for sweep loader
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Fade-in animation for layout
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final onboardingCompleted = await DatabaseHelper.instance.getSetting('completed_onboarding');

    Widget nextScreen;
    if (onboardingCompleted == 'true') {
      final user = await ref.read(authProvider.notifier).signInSilently();
      if (user != null) {
        nextScreen = const DashboardScreen();
      } else {
        nextScreen = const SignInScreen();
      }
    } else {
      nextScreen = const OnboardingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
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

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor = isDarkTheme ? const Color(0xFFF4EFEA) : const Color(0xFF3A3530); // Soft Cream / Deep Charcoal-Taupe
    final Color captionColor = isDarkTheme ? const Color(0xFFF4EFEA).withOpacity(0.5) : const Color(0xFF3A3530).withOpacity(0.5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background Atmospheric Glow (Subtle radial warm taupe accent)
          Positioned.fill(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE2D1C3).withOpacity(0.1),
                ),
              ),
            ),
          ),
          
          // Main Content
          Positioned.fill(
            child: FadeTransition(
              opacity: _fadeController,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo + Title
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing Glowing Logo
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final double scale = 1.0 + (_pulseController.value * 0.02);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: CustomPaint(
                                  painter: BrandLogoPainter(
                                    pulseValue: _pulseController.value,
                                    isDark: isDarkTheme,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        // App Title in Deep Charcoal-Taupe
                        Text(
                          'CurveType',
                          style: GoogleFonts.outfit(
                            fontSize: 44,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            letterSpacing: -0.03,
                          ),
                        ),
                      ],
                    ),
                    
                    // Sweep Loader & Subtitle
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Elegant Sweep Loader
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF3A3530).withOpacity(0.05),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _rotateController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _rotateController.value * 2 * math.pi,
                                  child: SizedBox(
                                    width: 52,
                                    height: 52,
                                    child: CustomPaint(
                                      painter: SweepLoaderPainter(),
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFE2D1C3),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFE2D1C3).withOpacity(0.8),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        
                        // Caption Text
                        Text(
                          'CREATIVE STUDIO',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: captionColor,
                            letterSpacing: 4.0,
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrandLogoPainter extends CustomPainter {
  final double pulseValue;
  final bool isDark;
  BrandLogoPainter({required this.pulseValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final side = size.width * 0.72; // size of the rounded square box
    final rect = Rect.fromCenter(center: center, width: side, height: side);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(side * 0.28));

    // 1. Dynamic background glow pulsing in sync
    final glowPaint = Paint()
      ..color = const Color(0xFFE2D1C3).withOpacity(0.15 + (pulseValue * 0.10))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    
    canvas.drawRRect(rrect, glowPaint);

    // 2. Draw the Soft Peach rounded square box
    final boxPaint = Paint()
      ..color = const Color(0xFFFFEAD9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(rrect, boxPaint);

    // 2b. Draw a subtle warm taupe outline
    final borderPaint = Paint()
      ..color = const Color(0xFFE2D1C3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(rrect, borderPaint);

    // 3. Draw the Charcoal-Taupe drafting compass vector icon inside the box
    final iconPaint = Paint()
      ..color = const Color(0xFF3A3530)
      ..strokeWidth = side * 0.085
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double cx = center.dx;
    final double cy = center.dy;
    
    // Position lines relative to center to form drafting compass
    final double topY = cy - side * 0.20;
    final double bottomY = cy + side * 0.22;
    final double leftX = cx - side * 0.18;
    final double rightX = cx + side * 0.18;
    
    // Draw the two diagonal legs
    canvas.drawLine(Offset(cx, topY), Offset(leftX, bottomY), iconPaint);
    canvas.drawLine(Offset(cx, topY), Offset(rightX, bottomY), iconPaint);
    
    // Draw the horizontal compass brace
    final bracePaint = Paint()
      ..color = const Color(0xFF3A3530)
      ..strokeWidth = side * 0.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(cx - side * 0.11, cy + side * 0.05),
      Offset(cx + side * 0.11, cy + side * 0.05),
      bracePaint,
    );

    // Draw the top hinge pin circle
    final hingePaint = Paint()
      ..color = const Color(0xFF3A3530)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(cx, topY - side * 0.04), side * 0.065, hingePaint);
  }

  @override
  bool shouldRepaint(covariant BrandLogoPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue;
  }
}

class SweepLoaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = const Color(0xFFE2D1C3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double radius = size.width / 2;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(radius, radius), radius: radius),
      -math.pi / 2, // start at top
      math.pi / 2,  // 90 degrees arc length
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant SweepLoaderPainter oldDelegate) => false;
}
