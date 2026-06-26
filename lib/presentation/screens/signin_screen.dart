import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/curved_text_painter.dart';
import '../state/auth_state.dart';
import 'dashboard_screen.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false; // Toggle between Sign In and Sign Up
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();

    // Rotate the curved text ring slowly
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat();

    // Pulse the atmospheric background glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    // Fade-in elements sequentially
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _primaryTextColor => _isDark ? const Color(0xFFF4EFEA) : const Color(0xFF3A3530); // Soft Cream / Deep Charcoal-Taupe
  Color get _secondaryTextColor => _isDark ? const Color(0xFFA89E95) : const Color(0xFF3A3530).withOpacity(0.6); // Muted Taupe
  Color get _cardBgColor => _isDark ? const Color(0xFF2C2621) : const Color(0xFFFFEAD9); // Espresso / Soft Peach
  Color get _scaffoldBgColor => _isDark ? const Color(0xFF1A1816) : const Color(0xFFFDFCFB); // Dark Cocoa / Clean Cream
  Color get _borderColor => _isDark ? const Color(0xFF2C2621) : const Color(0xFFE2D1C3); // Espresso / Beige

  void _handleGoogleSignIn() async {
    try {
      final user = await ref.read(authProvider.notifier).signIn();
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Google Sign-In failed: $e');
      }
    }
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    try {
      AuthUser? user;
      if (_isSignUp) {
        user = await ref.read(authProvider.notifier).signUpWithEmail(name, email, password);
      } else {
        user = await ref.read(authProvider.notifier).signInWithEmail(email, password);
      }

      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Authentication failed: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.outfit(color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleAuthMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _formKey.currentState?.reset();
      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      body: Stack(
        children: [
          // 1. Pulsing Atmospheric Background Glow
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double scale = 1.0 + (_pulseController.value * 0.15);
              final double opacity = 0.05 + (_pulseController.value * 0.04);
              return Positioned(
                top: size.height * 0.05,
                left: -size.width * 0.2,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size.width * 1.4,
                    height: size.width * 1.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE2D1C3).withOpacity(opacity * 2),
                          const Color(0xFFFFEAD9).withOpacity(opacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. Scrollable Content Layer
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Branding Header
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _fadeController,
                        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.architecture_rounded,
                            color: _primaryTextColor,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'CurveType',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: _primaryTextColor,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Central Section: Illustration + Input Form
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compact Showcase Canvas (Logo + Rotating Curved Text Ring)
                        FadeTransition(
                          opacity: CurvedAnimation(
                            parent: _fadeController,
                            curve: const Interval(0.1, 0.6, curve: Curves.easeOut),
                          ),
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                              CurvedAnimation(
                                parent: _fadeController,
                                curve: const Interval(0.1, 0.6, curve: Curves.easeOutBack),
                              ),
                            ),
                            child: SizedBox(
                              width: 180,
                              height: 180,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Rotating Curved Text Ring
                                  AnimatedBuilder(
                                    animation: _rotateController,
                                    builder: (context, child) {
                                      return Transform.rotate(
                                        angle: _rotateController.value * 2 * math.pi,
                                        child: CustomPaint(
                                          size: const Size(170, 170),
                                          painter: CurvedTextPainter(
                                            text: 'SCULPT YOUR WORDS • KINETIC TYPOGRAPHY • ',
                                            fontFamily: 'Outfit',
                                            fontSize: 7.5,
                                            color: _primaryTextColor,
                                            strokeWidth: 0.0,
                                            letterSpacing: 2.2,
                                            curvature: 78.0,
                                            opacity: 0.7,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  // Center Brand Logo Sphere
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _cardBgColor,
                                      border: Border.all(color: _borderColor, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF3A3530).withOpacity(0.05),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.gesture_rounded,
                                        color: _primaryTextColor,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title Text
                        Text(
                          _isSignUp ? 'Create Account' : 'Welcome Back',
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: _primaryTextColor,
                            letterSpacing: -0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isSignUp ? 'Sign up to start designing in motion.' : 'Sign in to access your typography studio.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: _secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // Email / Password Form
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. Name Field (Sign Up Only)
                              if (_isSignUp) ...[
                                _buildTextField(
                                  controller: _nameController,
                                  hintText: 'Full Name',
                                  icon: Icons.person_outline_rounded,
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],

                              // 2. Email Field
                              _buildTextField(
                                controller: _emailController,
                                hintText: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                                  if (!emailRegex.hasMatch(val.trim())) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              // 3. Password Field
                              _buildTextField(
                                controller: _passwordController,
                                hintText: 'Password',
                                icon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: _secondaryTextColor,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (val.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // 4. Primary Submit Button (SIGN IN / SIGN UP)
                              Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF3A3530).withOpacity(0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleSubmit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFE2D1C3),
                                    foregroundColor: const Color(0xFF3A3530),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A3530)),
                                          ),
                                        )
                                      : Text(
                                          _isSignUp ? 'CREATE ACCOUNT' : 'SIGN IN',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Bottom Section: Google Sign-In & Auth Mode Toggler
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _fadeController,
                        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          // Divider "OR"
                          Row(
                            children: [
                              Expanded(child: Divider(color: _borderColor.withOpacity(0.5), thickness: 1)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _secondaryTextColor,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: _borderColor.withOpacity(0.5), thickness: 1)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Branded Google Sign-In Button
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              color: _isDark ? const Color(0xFF2C2621) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _borderColor, width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: _isDark ? Colors.black.withOpacity(0.15) : const Color(0xFF3A3530).withOpacity(0.06),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleGoogleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: _primaryTextColor,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(_primaryTextColor),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CustomPaint(
                                            painter: GoogleLogoPainter(),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Text(
                                          'Continue with Google',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Switch Auth Mode Link
                          TextButton(
                            onPressed: isLoading ? null : _toggleAuthMode,
                            child: RichText(
                              text: TextSpan(
                                text: _isSignUp ? 'Already have an account? ' : 'Don\'t have an account? ',
                                style: GoogleFonts.outfit(color: _secondaryTextColor, fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: _isSignUp ? 'Sign In' : 'Sign Up',
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFE2D1C3),
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Terms disclaimer
                          Text(
                            'By continuing, you agree to our Terms and Privacy Policy.',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: _secondaryTextColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
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

  // Premium Custom TextField Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(color: _primaryTextColor),
      validator: validator,
      cursorColor: const Color(0xFFE2D1C3),
      decoration: InputDecoration(
        filled: true,
        fillColor: _isDark ? const Color(0xFF2C2621) : const Color(0xFFFFEAD9).withOpacity(0.3),
        hintText: hintText,
        hintStyle: GoogleFonts.outfit(color: _secondaryTextColor, fontSize: 15),
        prefixIcon: Icon(icon, color: _secondaryTextColor, size: 20),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE2D1C3), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 12),
      ),
    );
  }
}

// Custom Painter to draw a clean, sharp vector Google "G" logo
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = math.min(w, h) / 2;

    // Paint segments with correct Google Brand colors
    final Paint redPaint = Paint()..color = const Color(0xFFEA4335)..style = PaintingStyle.stroke..strokeWidth = radius * 0.45..strokeCap = StrokeCap.square;
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05)..style = PaintingStyle.stroke..strokeWidth = radius * 0.45..strokeCap = StrokeCap.square;
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853)..style = PaintingStyle.stroke..strokeWidth = radius * 0.45..strokeCap = StrokeCap.square;
    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.stroke..strokeWidth = radius * 0.45..strokeCap = StrokeCap.square;

    // Adjust stroke rect to keep it within boundaries
    final Rect strokeRect = Rect.fromCircle(center: Offset(cx, cy), radius: radius - (radius * 0.225));

    // 1. Red top segment
    canvas.drawArc(strokeRect, -math.pi * 0.8, math.pi * 0.55, false, redPaint);
    // 2. Yellow left segment
    canvas.drawArc(strokeRect, -math.pi * 1.35, math.pi * 0.55, false, yellowPaint);
    // 3. Green bottom segment
    canvas.drawArc(strokeRect, math.pi * 0.2, math.pi * 0.55, false, greenPaint);
    // 4. Blue right segment & horizontal bar
    canvas.drawArc(strokeRect, -math.pi * 0.25, math.pi * 0.45, false, bluePaint);

    // Draw the horizontal bar of the 'G'
    final Paint barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.43
      ..strokeCap = StrokeCap.butt;
    
    canvas.drawLine(
      Offset(cx + radius * 0.1, cy),
      Offset(cx + radius * 0.85, cy),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
