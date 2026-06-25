import 'text_layer.dart';
import 'image_settings.dart';

class Project {
  final String id;
  final String name;
  final String imagePath; // Absolute local file path
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TextLayer> textLayers;
  final ImageSettings imageSettings;

  Project({
    required this.id,
    required this.name,
    required this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.textLayers = const [],
    ImageSettings? imageSettings,
  }) : this.imageSettings = imageSettings ?? ImageSettings();

  Project copyWith({
    String? id,
    String? name,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<TextLayer>? textLayers,
    ImageSettings? imageSettings,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      textLayers: textLayers ?? this.textLayers,
      imageSettings: imageSettings ?? this.imageSettings,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'imageSettings': imageSettings.toMap(),
    };
  }

  factory Project.fromMap(Map<String, dynamic> map, List<TextLayer> textLayers) {
    return Project(
      id: map['id'] as String,
      name: map['name'] as String,
      imagePath: map['imagePath'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      textLayers: textLayers,
      imageSettings: map['imageSettings'] is Map
          ? ImageSettings.fromMap(Map<String, dynamic>.from(map['imageSettings'] as Map))
          : ImageSettings(),
    );
  }
}
