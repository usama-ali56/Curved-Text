import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CurvedTextPainter extends CustomPainter {
  final String text;
  final String fontFamily;
  final double fontSize;
  final Color color;
  final Color? strokeColor;
  final double strokeWidth;
  final double letterSpacing;
  final double curvature; // -100 to 100 (0 is straight)
  final double opacity;

  // New styling properties
  final Color? shadowColor;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final Color? glowColor;
  final double glowRadius;
  final List<Color>? gradientColors;

  CurvedTextPainter({
    required this.text,
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    this.strokeColor,
    required this.strokeWidth,
    required this.letterSpacing,
    required this.curvature,
    required this.opacity,
    this.shadowColor,
    this.shadowBlur = 4.0,
    this.shadowOffsetX = 2.0,
    this.shadowOffsetY = 2.0,
    this.glowColor,
    this.glowRadius = 8.0,
    this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty) return;

    // Build the shadows and glow list
    final List<Shadow> activeShadows = [];
    if (shadowColor != null) {
      activeShadows.add(Shadow(
        color: shadowColor!.withOpacity(opacity),
        offset: Offset(shadowOffsetX, shadowOffsetY),
        blurRadius: shadowBlur,
      ));
    }
    if (glowColor != null) {
      activeShadows.add(Shadow(
        color: glowColor!.withOpacity(opacity),
        offset: Offset.zero,
        blurRadius: glowRadius,
      ));
    }

    // Build base text styles
    final baseFillStyle = TextStyle(
      fontSize: fontSize,
      color: gradientColors == null ? color.withOpacity(opacity) : null,
      shadows: activeShadows.isNotEmpty ? activeShadows : null,
    );

    final fillStyle = _getGoogleFont(fontFamily, baseFillStyle);

    TextStyle? strokeStyle;
    if (strokeColor != null && strokeWidth > 0) {
      final baseStrokeStyle = TextStyle(
        fontSize: fontSize,
        shadows: activeShadows.isNotEmpty ? activeShadows : null,
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = strokeColor!.withOpacity(opacity),
      );
      strokeStyle = _getGoogleFont(fontFamily, baseStrokeStyle);
    }

    // Straight text fallback
    if (curvature.abs() < 1) {
      _paintStraightText(canvas, size, fillStyle, strokeStyle);
      return;
    }

    // Map curvature to radius: 100 -> 150px, 1 -> 15000px
    final double radius = 15000.0 / curvature.abs();

    // Measure character widths
    final List<double> charWidths = [];
    double totalWidth = 0;

    for (int i = 0; i < text.length; i++) {
      final charPainter = TextPainter(
        text: TextSpan(text: text[i], style: fillStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final w = charPainter.width;
      charWidths.add(w);
      totalWidth += w;
    }

    final double extraSpacing = letterSpacing * fontSize * 0.1;
    final double totalSpacing = extraSpacing * (text.length - 1);
    final double totalArcLength = totalWidth + totalSpacing;

    // Convert lengths to angles
    final double totalTheta = totalArcLength / radius;

    // Starting angle to center the text along the vertical apex
    double theta;
    final double centerOfCanvasX = size.width / 2;
    double centerOfCircleY;

    if (curvature < 0) {
      // Curved upwards (rainbow shape). Circle center is below text.
      centerOfCircleY = size.height / 2 + radius - (fontSize / 2);
      theta = -math.pi / 2 - (totalTheta / 2);
    } else {
      // Curved downwards (smile shape). Circle center is above text.
      centerOfCircleY = size.height / 2 - radius + (fontSize / 2);
      theta = math.pi / 2 + (totalTheta / 2); // Start on the left (7 o'clock)
    }

    // Draw characters one by one
    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final double charW = charWidths[i];
      final double charTheta = charW / radius;

      // Middle angle of the character
      double midTheta;
      double rotation;

      if (curvature < 0) {
        midTheta = theta + (charTheta / 2);
        rotation = midTheta + math.pi / 2;
      } else {
        midTheta = theta - (charTheta / 2); // subtract since we go counter-clockwise
        rotation = midTheta - math.pi / 2;
      }

      // Character position on the circle
      final double charX = centerOfCanvasX + radius * math.cos(midTheta);
      final double charY = centerOfCircleY + radius * math.sin(midTheta);

      canvas.save();
      canvas.translate(charX, charY);
      canvas.rotate(rotation);

      // Draw the character centered at the baseline
      _paintChar(canvas, char, -charW / 2, -fontSize / 2, fillStyle, strokeStyle);

      canvas.restore();

      // Advance angle
      if (curvature < 0) {
        theta += charTheta + (extraSpacing / radius);
      } else {
        theta -= charTheta + (extraSpacing / radius); // subtract to go counter-clockwise
      }
    }
  }

  void _paintStraightText(
    Canvas canvas,
    Size size,
    TextStyle fillStyle,
    TextStyle? strokeStyle,
  ) {
    final textSpan = TextSpan(text: text, style: fillStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final x = (size.width - textPainter.width) / 2;
    final y = (size.height - textPainter.height) / 2;

    // Apply linear gradient across straight text length (top to bottom)
    TextStyle activeFillStyle = fillStyle;
    if (gradientColors != null && gradientColors!.length >= 2) {
      activeFillStyle = fillStyle.copyWith(
        foreground: Paint()
          ..shader = ui.Gradient.linear(
            const Offset(0, 0),
            Offset(0, fontSize),
            gradientColors!.map((c) => c.withOpacity(opacity)).toList(),
            List.generate(gradientColors!.length, (index) => index / (gradientColors!.length - 1)),
          ),
      );
    }

    canvas.save();
    canvas.translate(x, y);

    if (strokeStyle != null) {
      final strokePainter = TextPainter(
        text: TextSpan(text: text, style: strokeStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      strokePainter.paint(canvas, Offset.zero);
    }

    final fillPainter = TextPainter(
      text: TextSpan(text: text, style: activeFillStyle),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    fillPainter.paint(canvas, Offset.zero);

    canvas.restore();
  }

  void _paintChar(
    Canvas canvas,
    String char,
    double dx,
    double dy,
    TextStyle fillStyle,
    TextStyle? strokeStyle,
  ) {
    // Apply linear gradient shader relative to dy coordinate
    TextStyle activeFillStyle = fillStyle;
    if (gradientColors != null && gradientColors!.length >= 2) {
      activeFillStyle = fillStyle.copyWith(
        foreground: Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, dy),
            Offset(0, dy + fontSize),
            gradientColors!.map((c) => c.withOpacity(opacity)).toList(),
            List.generate(gradientColors!.length, (index) => index / (gradientColors!.length - 1)),
          ),
      );
    }

    if (strokeStyle != null) {
      final strokePainter = TextPainter(
        text: TextSpan(text: char, style: strokeStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      strokePainter.paint(canvas, Offset(dx, dy));
    }

    final fillPainter = TextPainter(
      text: TextSpan(text: char, style: activeFillStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    fillPainter.paint(canvas, Offset(dx, dy));
  }

  TextStyle _getGoogleFont(String familyName, TextStyle baseStyle) {
    try {
      return GoogleFonts.getFont(familyName, textStyle: baseStyle);
    } catch (e) {
      return baseStyle.copyWith(fontFamily: 'Outfit');
    }
  }

  bool _listEquals(List<Color>? a, List<Color>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool shouldRepaint(covariant CurvedTextPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.fontFamily != fontFamily ||
        oldDelegate.fontSize != fontSize ||
        oldDelegate.color != color ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.letterSpacing != letterSpacing ||
        oldDelegate.curvature != curvature ||
        oldDelegate.opacity != opacity ||
        oldDelegate.shadowColor != shadowColor ||
        oldDelegate.shadowBlur != shadowBlur ||
        oldDelegate.shadowOffsetX != shadowOffsetX ||
        oldDelegate.shadowOffsetY != shadowOffsetY ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.glowRadius != glowRadius ||
        !_listEquals(oldDelegate.gradientColors, gradientColors);
  }
}
