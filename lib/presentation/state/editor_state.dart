import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/project.dart';
import '../../domain/models/text_layer.dart';
import '../../domain/models/image_settings.dart';
import '../../data/database_helper.dart';

class EditorState {
  final Project? project;
  final String? selectedLayerId;
  final List<Project> undoStack;
  final List<Project> redoStack;
  final bool isSaving;

  EditorState({
    this.project,
    this.selectedLayerId,
    this.undoStack = const [],
    this.redoStack = const [],
    this.isSaving = false,
  });

  EditorState copyWith({
    Project? project,
    String? selectedLayerId,
    List<Project>? undoStack,
    List<Project>? redoStack,
    bool? isSaving,
    bool clearSelection = false,
  }) {
    return EditorState(
      project: project ?? this.project,
      selectedLayerId: clearSelection ? null : (selectedLayerId ?? this.selectedLayerId),
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class EditorStateNotifier extends Notifier<EditorState> {
  final _uuid = const Uuid();

  @override
  EditorState build() {
    return EditorState();
  }

  void loadProject(Project project) {
    state = EditorState(
      project: project,
      selectedLayerId: project.textLayers.isNotEmpty ? project.textLayers.first.id : null,
      undoStack: [],
      redoStack: [],
    );
  }

  void selectLayer(String? layerId) {
    state = state.copyWith(selectedLayerId: layerId);
  }

  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  void closeProject() {
    state = EditorState();
  }

  // Push current project state to the undo stack and clear redo stack
  void _pushToHistory() {
    final currentProject = state.project;
    if (currentProject == null) return;

    final updatedUndo = List<Project>.from(state.undoStack)..add(currentProject);
    state = state.copyWith(
      undoStack: updatedUndo,
      redoStack: [], // Clear redo stack on any new edit
    );
  }

  void pushCurrentStateToHistory() {
    _pushToHistory();
  }

  void updateTextLayer(TextLayer updatedLayer, {bool pushToHistory = true}) {
    final project = state.project;
    if (project == null) return;

    if (pushToHistory) {
      _pushToHistory();
    }

    final updatedLayers = project.textLayers.map((layer) {
      return layer.id == updatedLayer.id ? updatedLayer : layer;
    }).toList();

    final updatedProject = project.copyWith(
      textLayers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(project: updatedProject);
  }

  void addTextLayer({String text = 'DOUBLE TAP TO EDIT'}) {
    final project = state.project;
    if (project == null) return;

    _pushToHistory();

    final newLayer = TextLayer(
      id: _uuid.v4(),
      text: text,
      x: 0.5,
      y: 0.5,
      scale: 1.0,
      rotation: 0.0,
      curvature: 0.0,
      fontFamily: 'Outfit',
      fontSize: 32.0,
      colorValue: 0xFFFFFFFF,
      opacity: 1.0,
    );

    final updatedLayers = List<TextLayer>.from(project.textLayers)..add(newLayer);
    final updatedProject = project.copyWith(
      textLayers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      project: updatedProject,
      selectedLayerId: newLayer.id,
    );
  }

  void deleteTextLayer(String id) {
    final project = state.project;
    if (project == null) return;

    _pushToHistory();

    final updatedLayers = project.textLayers.where((layer) => layer.id != id).toList();
    final updatedProject = project.copyWith(
      textLayers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    // If deleted layer was selected, select another one or clear selection
    String? newSelectedId;
    if (state.selectedLayerId == id) {
      newSelectedId = updatedLayers.isNotEmpty ? updatedLayers.first.id : null;
    } else {
      newSelectedId = state.selectedLayerId;
    }

    state = state.copyWith(
      project: updatedProject,
      selectedLayerId: newSelectedId,
      clearSelection: newSelectedId == null,
    );
  }

  void duplicateTextLayer(String id) {
    final project = state.project;
    if (project == null) return;

    final originalLayer = project.textLayers.firstWhere((layer) => layer.id == id);
    _pushToHistory();

    final duplicated = originalLayer.copyWith(
      id: _uuid.v4(),
      x: (originalLayer.x + 0.05).clamp(0.0, 1.0),
      y: (originalLayer.y + 0.05).clamp(0.0, 1.0),
    );

    final updatedLayers = List<TextLayer>.from(project.textLayers)..add(duplicated);
    final updatedProject = project.copyWith(
      textLayers: updatedLayers,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(
      project: updatedProject,
      selectedLayerId: duplicated.id,
    );
  }

  void changeLayerOrder(String id, bool bringToFront) {
    final project = state.project;
    if (project == null) return;

    _pushToHistory();

    final layers = List<TextLayer>.from(project.textLayers);
    final index = layers.indexWhere((layer) => layer.id == id);
    if (index == -1) return;

    final layer = layers.removeAt(index);
    if (bringToFront) {
      layers.add(layer); // Add to end of list (draws on top)
    } else {
      layers.insert(0, layer); // Add to start of list (draws behind)
    }

    final updatedProject = project.copyWith(
      textLayers: layers,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(project: updatedProject);
  }

  void updateImageSettings(ImageSettings settings, {bool pushToHistory = true}) {
    final project = state.project;
    if (project == null) return;

    if (pushToHistory) {
      _pushToHistory();
    }

    final updatedProject = project.copyWith(
      imageSettings: settings,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(project: updatedProject);
  }

  void undo() {
    if (state.undoStack.isEmpty) return;

    final currentProject = state.project;
    if (currentProject == null) return;

    final previousProject = state.undoStack.last;
    final updatedUndo = List<Project>.from(state.undoStack)..removeLast();
    final updatedRedo = List<Project>.from(state.redoStack)..add(currentProject);

    // Ensure selected layer still exists, otherwise select first available or clear
    String? newSelectedId = state.selectedLayerId;
    if (newSelectedId != null &&
        !previousProject.textLayers.any((l) => l.id == newSelectedId)) {
      newSelectedId = previousProject.textLayers.isNotEmpty
          ? previousProject.textLayers.first.id
          : null;
    }

    state = state.copyWith(
      project: previousProject,
      selectedLayerId: newSelectedId,
      undoStack: updatedUndo,
      redoStack: updatedRedo,
      clearSelection: newSelectedId == null,
    );
  }

  void redo() {
    if (state.redoStack.isEmpty) return;

    final currentProject = state.project;
    if (currentProject == null) return;

    final nextProject = state.redoStack.last;
    final updatedRedo = List<Project>.from(state.redoStack)..removeLast();
    final updatedUndo = List<Project>.from(state.undoStack)..add(currentProject);

    String? newSelectedId = state.selectedLayerId;
    if (newSelectedId != null &&
        !nextProject.textLayers.any((l) => l.id == newSelectedId)) {
      newSelectedId = nextProject.textLayers.isNotEmpty
          ? nextProject.textLayers.first.id
          : null;
    }

    state = state.copyWith(
      project: nextProject,
      selectedLayerId: newSelectedId,
      undoStack: updatedUndo,
      redoStack: updatedRedo,
      clearSelection: newSelectedId == null,
    );
  }

  Future<void> saveCurrentProject() async {
    final project = state.project;
    if (project == null) return;

    state = state.copyWith(isSaving: true);
    try {
      await DatabaseHelper.instance.saveProject(project);
    } catch (e) {
      // Handle or log error
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }
}

// Global provider for the editor state
final editorProvider = NotifierProvider<EditorStateNotifier, EditorState>(() {
  return EditorStateNotifier();
});
