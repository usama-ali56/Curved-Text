import 'package:flutter_test/flutter_test.dart';
import 'package:curvetype/domain/models/project.dart';
import 'package:curvetype/domain/models/text_layer.dart';
import 'package:curvetype/domain/models/image_settings.dart';

void main() {
  group('CurveType Model Tests', () {
    test('TextLayer serialization & deserialization', () {
      final layer = TextLayer(
        id: 'layer-1',
        text: 'CURVETYPE',
        x: 0.5,
        y: 0.5,
        scale: 1.2,
        rotation: 0.5,
        curvature: 45.0,
        fontFamily: 'Outfit',
        fontSize: 32.0,
        colorValue: 0xFFFFFFFF,
        shadowColorValue: 0xFF000000,
        shadowBlur: 5.0,
        shadowOffsetX: 3.0,
        shadowOffsetY: 3.0,
        glowColorValue: 0xFFFF00FF,
        glowRadius: 12.0,
        gradientColors: [0xFFFF0000, 0xFF0000FF],
      );

      final map = layer.toMap();
      expect(map['id'], 'layer-1');
      expect(map['text'], 'CURVETYPE');
      expect(map['scale'], 1.2);
      expect(map['curvature'], 45.0);
      expect(map['styleMetadata'] != null, true);

      final fromMap = TextLayer.fromMap(map);
      expect(fromMap.id, 'layer-1');
      expect(fromMap.text, 'CURVETYPE');
      expect(fromMap.scale, 1.2);
      expect(fromMap.curvature, 45.0);
      expect(fromMap.shadowColorValue, 0xFF000000);
      expect(fromMap.shadowBlur, 5.0);
      expect(fromMap.shadowOffsetX, 3.0);
      expect(fromMap.shadowOffsetY, 3.0);
      expect(fromMap.glowColorValue, 0xFFFF00FF);
      expect(fromMap.glowRadius, 12.0);
      expect(fromMap.gradientColors, [0xFFFF0000, 0xFF0000FF]);
    });

    test('ImageSettings serialization & deserialization', () {
      final settings = ImageSettings(
        brightness: 0.2,
        contrast: 1.1,
        saturation: 1.0,
        rotation: 90.0,
        isFlippedHorizontal: true,
        cropLeft: 0.1,
        cropRight: 0.9,
      );

      final map = settings.toMap();
      expect(map['brightness'], 0.2);
      expect(map['contrast'], 1.1);
      expect(map['rotation'], 90.0);
      expect(map['isFlippedHorizontal'], 1);

      final fromMap = ImageSettings.fromMap(map);
      expect(fromMap.brightness, 0.2);
      expect(fromMap.contrast, 1.1);
      expect(fromMap.rotation, 90.0);
      expect(fromMap.isFlippedHorizontal, true);
      expect(fromMap.cropLeft, 0.1);
      expect(fromMap.cropRight, 0.9);
    });

    test('Project model and copyWith utility', () {
      final project = Project(
        id: 'proj-1',
        name: 'My Masterpiece',
        imagePath: '/path/to/image.png',
        createdAt: DateTime(2026, 6, 23),
        updatedAt: DateTime(2026, 6, 23),
        textLayers: [],
        imageSettings: ImageSettings(brightness: 0.1),
      );

      final updated = project.copyWith(name: 'Renamed Masterpiece');
      expect(updated.id, 'proj-1');
      expect(updated.name, 'Renamed Masterpiece');
      expect(updated.imageSettings.brightness, 0.1);
    });
  });
}
