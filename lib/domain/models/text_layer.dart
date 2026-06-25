import 'dart:convert';

class TextLayer {
  final String id;
  final String text;
  final double x; // Relative X coordinate (0.0 to 1.0)
  final double y; // Relative Y coordinate (0.0 to 1.0)
  final double scale;
  final double rotation; // In radians
  final double curvature; // -100 to 100 (0 is straight, negative curves up, positive curves down)
  final String fontFamily;
  final double fontSize;
  final int colorValue; // ARGB hex value
  final int? strokeColorValue; // ARGB hex value, null means no border
  final double strokeWidth;
  final double letterSpacing;
  final double opacity; // 0.0 to 1.0

  // New text styles properties
  final int? shadowColorValue;
  final double shadowBlur;
  final double shadowOffsetX;
  final double shadowOffsetY;
  final int? glowColorValue;
  final double glowRadius;
  final List<int>? gradientColors;

  TextLayer({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.curvature = 0.0,
    this.fontFamily = 'Outfit',
    this.fontSize = 24.0,
    this.colorValue = 0xFFFFFFFF,
    this.strokeColorValue,
    this.strokeWidth = 2.0,
    this.letterSpacing = 0.0,
    this.opacity = 1.0,
    this.shadowColorValue,
    this.shadowBlur = 4.0,
    this.shadowOffsetX = 2.0,
    this.shadowOffsetY = 2.0,
    this.glowColorValue,
    this.glowRadius = 8.0,
    this.gradientColors,
  });

  TextLayer copyWith({
    String? id,
    String? text,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    double? curvature,
    String? fontFamily,
    double? fontSize,
    int? colorValue,
    int? strokeColorValue,
    double? strokeWidth,
    double? letterSpacing,
    double? opacity,
    int? shadowColorValue,
    double? shadowBlur,
    double? shadowOffsetX,
    double? shadowOffsetY,
    int? glowColorValue,
    double? glowRadius,
    List<int>? gradientColors,
    bool clearShadow = false,
    bool clearGlow = false,
    bool clearGradient = false,
  }) {
    return TextLayer(
      id: id ?? this.id,
      text: text ?? this.text,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      curvature: curvature ?? this.curvature,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      colorValue: colorValue ?? this.colorValue,
      strokeColorValue: strokeColorValue ?? this.strokeColorValue,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      opacity: opacity ?? this.opacity,
      shadowColorValue: clearShadow ? null : (shadowColorValue ?? this.shadowColorValue),
      shadowBlur: shadowBlur ?? this.shadowBlur,
      shadowOffsetX: shadowOffsetX ?? this.shadowOffsetX,
      shadowOffsetY: shadowOffsetY ?? this.shadowOffsetY,
      glowColorValue: clearGlow ? null : (glowColorValue ?? this.glowColorValue),
      glowRadius: glowRadius ?? this.glowRadius,
      gradientColors: clearGradient ? null : (gradientColors ?? this.gradientColors),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'x': x,
      'y': y,
      'scale': scale,
      'rotation': rotation,
      'curvature': curvature,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'colorValue': colorValue,
      'strokeColorValue': strokeColorValue,
      'strokeWidth': strokeWidth,
      'letterSpacing': letterSpacing,
      'opacity': opacity,
      'styleMetadata': jsonEncode({
        'shadowColor': shadowColorValue,
        'shadowBlur': shadowBlur,
        'shadowOffsetX': shadowOffsetX,
        'shadowOffsetY': shadowOffsetY,
        'glowColor': glowColorValue,
        'glowRadius': glowRadius,
        'gradientColors': gradientColors,
      }),
    };
  }

  factory TextLayer.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> metadata = {};
    if (map['styleMetadata'] != null) {
      try {
        metadata = jsonDecode(map['styleMetadata'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return TextLayer(
      id: map['id'] as String,
      text: map['text'] as String,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      scale: (map['scale'] as num).toDouble(),
      rotation: (map['rotation'] as num).toDouble(),
      curvature: (map['curvature'] as num).toDouble(),
      fontFamily: map['fontFamily'] as String? ?? 'Outfit',
      fontSize: (map['fontSize'] as num).toDouble(),
      colorValue: map['colorValue'] as int,
      strokeColorValue: map['strokeColorValue'] as int?,
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
      letterSpacing: (map['letterSpacing'] as num).toDouble(),
      opacity: (map['opacity'] as num).toDouble(),
      shadowColorValue: metadata['shadowColor'] as int?,
      shadowBlur: (metadata['shadowBlur'] as num?)?.toDouble() ?? 4.0,
      shadowOffsetX: (metadata['shadowOffsetX'] as num?)?.toDouble() ?? 2.0,
      shadowOffsetY: (metadata['shadowOffsetY'] as num?)?.toDouble() ?? 2.0,
      glowColorValue: metadata['glowColor'] as int?,
      glowRadius: (metadata['glowRadius'] as num?)?.toDouble() ?? 8.0,
      gradientColors: (metadata['gradientColors'] as List?)?.map((c) => c as int).toList(),
    );
  }
}
