class ImageSettings {
  final double brightness; // -1.0 to 1.0 (0.0 is original)
  final double contrast; // 0.5 to 2.0 (1.0 is original)
  final double saturation; // 0.0 to 2.0 (1.0 is original)
  final double rotation; // In degrees: 0, 90, 180, 270
  final bool isFlippedHorizontal;
  final bool isFlippedVertical;
  final double cropLeft; // 0.0 to 1.0
  final double cropTop; // 0.0 to 1.0
  final double cropRight; // 0.0 to 1.0
  final double cropBottom; // 0.0 to 1.0

  ImageSettings({
    this.brightness = 0.0,
    this.contrast = 1.0,
    this.saturation = 1.0,
    this.rotation = 0.0,
    this.isFlippedHorizontal = false,
    this.isFlippedVertical = false,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 1.0,
    this.cropBottom = 1.0,
  });

  ImageSettings copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? rotation,
    bool? isFlippedHorizontal,
    bool? isFlippedVertical,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) {
    return ImageSettings(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      rotation: rotation ?? this.rotation,
      isFlippedHorizontal: isFlippedHorizontal ?? this.isFlippedHorizontal,
      isFlippedVertical: isFlippedVertical ?? this.isFlippedVertical,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'brightness': brightness,
      'contrast': contrast,
      'saturation': saturation,
      'rotation': rotation,
      'isFlippedHorizontal': isFlippedHorizontal ? 1 : 0,
      'isFlippedVertical': isFlippedVertical ? 1 : 0,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropRight': cropRight,
      'cropBottom': cropBottom,
    };
  }

  factory ImageSettings.fromMap(Map<String, dynamic> map) {
    return ImageSettings(
      brightness: (map['brightness'] as num?)?.toDouble() ?? 0.0,
      contrast: (map['contrast'] as num?)?.toDouble() ?? 1.0,
      saturation: (map['saturation'] as num?)?.toDouble() ?? 1.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
      isFlippedHorizontal: map['isFlippedHorizontal'] == 1,
      isFlippedVertical: map['isFlippedVertical'] == 1,
      cropLeft: (map['cropLeft'] as num?)?.toDouble() ?? 0.0,
      cropTop: (map['cropTop'] as num?)?.toDouble() ?? 0.0,
      cropRight: (map['cropRight'] as num?)?.toDouble() ?? 1.0,
      cropBottom: (map['cropBottom'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
