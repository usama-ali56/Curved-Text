import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curvetype/presentation/state/editor_state.dart';
import 'package:curvetype/domain/models/project.dart';
import 'package:curvetype/domain/models/text_layer.dart';
import 'package:curvetype/domain/models/image_settings.dart';

void main() {
  test('EditorStateNotifier undo/redo test', () {
    final container = ProviderContainer();
    final notifier = container.read(editorProvider.notifier);
    
    final project = Project(
      id: 'proj-1',
      name: 'Test Project',
      imagePath: '/path/to/image.png',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      textLayers: [
        TextLayer(
          id: 'layer-1',
          text: 'INITIAL TEXT',
          x: 0.5,
          y: 0.5,
          scale: 1.0,
          rotation: 0.0,
          curvature: 0.0,
          fontFamily: 'Outfit',
          fontSize: 32.0,
          colorValue: 0xFFFFFFFF,
        )
      ],
      imageSettings: ImageSettings(),
    );
    
    notifier.loadProject(project);
    
    // Initial state
    expect(container.read(editorProvider).undoStack.isEmpty, true);
    expect(container.read(editorProvider).redoStack.isEmpty, true);
    
    // Update layer text
    final updatedLayer = project.textLayers.first.copyWith(text: 'UPDATED TEXT');
    notifier.updateTextLayer(updatedLayer);
    
    // Check history after update
    final state1 = container.read(editorProvider);
    expect(state1.undoStack.length, 1);
    expect(state1.undoStack.first.textLayers.first.text, 'INITIAL TEXT');
    expect(state1.project!.textLayers.first.text, 'UPDATED TEXT');
    expect(state1.redoStack.isEmpty, true);
    
    // Undo
    notifier.undo();
    final state2 = container.read(editorProvider);
    expect(state2.project!.textLayers.first.text, 'INITIAL TEXT');
    expect(state2.undoStack.isEmpty, true);
    expect(state2.redoStack.length, 1);
    expect(state2.redoStack.first.textLayers.first.text, 'UPDATED TEXT');
    
    // Redo
    notifier.redo();
    final state3 = container.read(editorProvider);
    expect(state3.project!.textLayers.first.text, 'UPDATED TEXT');
    expect(state3.undoStack.length, 1);
    expect(state3.undoStack.first.textLayers.first.text, 'INITIAL TEXT');
    expect(state3.redoStack.isEmpty, true);
  });
}
