import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/project.dart';
import '../../domain/models/text_layer.dart';
import '../../data/database_helper.dart';
import '../state/editor_state.dart';
import '../widgets/canvas_gesture_detector.dart';
import '../widgets/crop_overlay.dart';
import '../../data/utils/color_filter_helper.dart';

class CanvasEditorScreen extends ConsumerStatefulWidget {
  const CanvasEditorScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CanvasEditorScreen> createState() => _CanvasEditorScreenState();
}

class _CanvasEditorScreenState extends ConsumerState<CanvasEditorScreen> with SingleTickerProviderStateMixin {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _primaryTextColor => _isDark ? const Color(0xFFF4EFEA) : const Color(0xFF3A3530); // Soft Cream / Deep Charcoal-Taupe
  Color get _secondaryTextColor => _isDark ? const Color(0xFFA89E95) : const Color(0xFF3A3530).withOpacity(0.6); // Muted Taupe-Grey
  Color get _cardBgColor => _isDark ? const Color(0xFF2C2621) : const Color(0xFFFFEAD9); // Warm Dark Espresso / Soft Peach
  Color get _scaffoldBgColor => _isDark ? const Color(0xFF1A1816) : const Color(0xFFFDFCFB); // Rich Dark Cocoa / Clean Cream
  Color get _borderColor => _isDark ? const Color(0xFF2C2621) : const Color(0xFFE2D1C3); // Espresso / Beige
  
  // Tab controller for bottom properties: 0 = Text layers properties, 1 = Image adjustment filters, 2 = Crop/Rotate image
  late TabController _tabController;
  
  // Image path aspect ratio cache to fit vertical and horizontal images correctly
  final Map<String, double> _aspectRatioCache = {};
  
  // Text input controller for the bottom sheet editing text
  final TextEditingController _textEditingController = TextEditingController();

  // Curated font families list based on the design specifications
  final List<String> _fontFamilies = [
    'Outfit',
    'Inter',
    'Montserrat',
    'Space Mono',
    'Oswald',
    'Caveat',
    'Playfair Display',
    'Lora',
  ];

  // Curated color palette (Soft Neutrals & functional accents)
  final List<Color> _colors = [
    const Color(0xFFFDFCFB), // Clean Cream
    const Color(0xFFFFEAD9), // Soft Peach
    const Color(0xFFE2D1C3), // Warm Taupe
    const Color(0xFF3A3530), // Deep Charcoal-Taupe
    const Color(0xFF10B981), // Emerald
    Colors.redAccent,
    Colors.amber,
    Colors.blueAccent,
    Colors.purpleAccent,
  ];

  // Custom typography gradient presets
  final Map<String, List<int>> _gradientPresets = {
    'Sunset': [0xFFFF512F, 0xFFDD2476],
    'Ocean': [0xFF00c6ff, 0xFF0072ff],
    'Retro Gold': [0xFFF3A152, 0xFFE5A64E, 0xFFD2AD4B, 0xFFBBB54A],
    'Cotton Candy': [0xFFFF007F, 0xFF7F00FF],
    'Neon Mint': [0xFF00FF87, 0xFF60EFFF],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 2) {
        // Clear text layer selection when moving to Crop tab to prevent overlay conflict
        ref.read(editorProvider.notifier).clearSelection();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _showTextEditBottomSheet(TextLayer layer) {
    _textEditingController.text = layer.text;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Text content',
                style: GoogleFonts.outfit(
                  color: _primaryTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textEditingController,
                autofocus: true,
                style: GoogleFonts.outfit(color: _primaryTextColor),
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _scaffoldBgColor,
                  hintText: 'Type something...',
                  hintStyle: GoogleFonts.outfit(color: _secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2D1C3)),
                  ),
                ),
                onChanged: (val) {
                  // Update text in real time on canvas
                  ref.read(editorProvider.notifier).updateTextLayer(
                        layer.copyWith(text: val.toUpperCase()),
                      );
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE2D1C3),
                    foregroundColor: const Color(0xFF3A3530),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'DONE',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportComposition() async {
    // Show quality picker
    final double? ratio = await _showQualityPickerDialog();
    if (ratio == null) return;

    // Show loading
    _showExportingLoader();

    try {
      // De-select any layers first to hide dashed borders/handles on final print!
      ref.read(editorProvider.notifier).clearSelection();
      
      // Allow screen to redraw without dashed border before rendering
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw 'RepaintBoundary not found';

      final ui.Image image = await boundary.toImage(pixelRatio: ratio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw 'Failed to get image bytes';
      
      final bytes = byteData.buffer.asUint8List();

      // Write to external directory (e.g. downloads) on Android, or documents on iOS
      String finalPath;
      if (Platform.isAndroid) {
        final dir = Directory('/storage/emulated/0/Download');
        if (await dir.exists()) {
          finalPath = p.join(dir.path, 'CurveType_${DateTime.now().millisecondsSinceEpoch}.png');
        } else {
          final appDocDir = await getApplicationDocumentsDirectory();
          finalPath = p.join(appDocDir.path, 'CurveType_${DateTime.now().millisecondsSinceEpoch}.png');
        }
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        finalPath = p.join(appDocDir.path, 'CurveType_${DateTime.now().millisecondsSinceEpoch}.png');
      }

      final file = File(finalPath);
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loader

      _showSuccessDialog(finalPath);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<double?> _showQualityPickerDialog() async {
    return showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _borderColor),
          ),
          title: Text(
            'Export Resolution',
            style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildQualityOption(context, 'Low Quality (720p preview)', 1.0),
              Divider(color: _borderColor),
              _buildQualityOption(context, 'Medium Quality (1080p Web)', 2.0),
              Divider(color: _borderColor),
              _buildQualityOption(context, 'High / Original Resolution (4K print)', 3.5),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQualityOption(BuildContext context, String title, double ratio) {
    return ListTile(
      title: Text(
        title,
        style: GoogleFonts.outfit(color: _primaryTextColor, fontSize: 14),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF3D30EC)),
      onTap: () => Navigator.pop(context, ratio),
    );
  }

  void _showExportingLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBgColor,
          content: Row(
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3D30EC)),
              ),
              const SizedBox(width: 24),
              Text(
                'Rasterizing canvas...',
                style: GoogleFonts.outfit(color: _primaryTextColor),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String path) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _borderColor),
          ),
          title: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Text(
                'Export Successful!',
                style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'Your masterpiece has been saved to:\n\n$path',
            style: GoogleFonts.outfit(color: _secondaryTextColor),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Pop the success dialog
                Navigator.pop(context); // Pop the editor screen to return to dashboard
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2D1C3),
                foregroundColor: const Color(0xFF3A3530),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'AWESOME',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showExitConfirmationDialog(Project project) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _borderColor),
          ),
          title: Text(
            'Exit Canvas',
            style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Do you want to save your current changes, or discard them and revert the design to the last saved version?',
            style: GoogleFonts.outfit(color: _secondaryTextColor),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: Text(
                'CANCEL',
                style: GoogleFonts.outfit(color: _secondaryTextColor),
              ),
            ),
            // Discard Changes Button
            TextButton(
              onPressed: () => Navigator.pop(context, 'discard'),
              child: Text(
                'DISCARD CHANGES',
                style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
            // Save Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'save'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2D1C3),
                foregroundColor: const Color(0xFF3A3530),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'SAVE',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (result == 'save') {
      _showExportingLoader();
      try {
        await ref.read(editorProvider.notifier).saveCurrentProject();
      } catch (_) {}
      if (mounted) {
        Navigator.pop(context); // pop loader
        Navigator.pop(context); // pop editor screen
      }
    } else if (result == 'discard') {
      ref.read(editorProvider.notifier).closeProject();
      if (mounted) {
        Navigator.pop(context); // pop editor screen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorProvider);
    final project = editorState.project;

    if (project == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDFCFB),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE2D1C3)),
          ),
        ),
      );
    }

    final TextLayer? activeLayer = editorState.selectedLayerId != null
        ? project.textLayers.firstWhere((l) => l.id == editorState.selectedLayerId)
        : null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _showExitConfirmationDialog(project);
      },
      child: Scaffold(
        backgroundColor: _scaffoldBgColor,
        appBar: AppBar(
          backgroundColor: _scaffoldBgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close_rounded, color: _primaryTextColor),
            onPressed: () => _showExitConfirmationDialog(project),
          ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEAD9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2D1C3), width: 1.0),
              ),
              child: Text(
                '${project.textLayers.length} LAYERS',
                style: GoogleFonts.outfit(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3A3530),
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        actions: [
          // Undo
          IconButton(
            icon: Icon(
              Icons.undo_rounded,
              color: editorState.undoStack.isNotEmpty ? _primaryTextColor : _primaryTextColor.withOpacity(0.3),
            ),
            onPressed: editorState.undoStack.isNotEmpty
                ? () => ref.read(editorProvider.notifier).undo()
                : null,
          ),
          // Redo
          IconButton(
            icon: Icon(
              Icons.redo_rounded,
              color: editorState.redoStack.isNotEmpty ? _primaryTextColor : _primaryTextColor.withOpacity(0.3),
            ),
            onPressed: editorState.redoStack.isNotEmpty
                ? () => ref.read(editorProvider.notifier).redo()
                : null,
          ),
          // Project Options Menu (Rename/Delete)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: _primaryTextColor),
            onSelected: (value) async {
              if (value == 'rename') {
                final String? newName = await _showRenameDialog(project.name);
                if (newName != null && newName.trim().isNotEmpty) {
                  final updated = project.copyWith(
                    name: newName.trim(),
                    updatedAt: DateTime.now(),
                  );
                  ref.read(editorProvider.notifier).loadProject(updated);
                  await ref.read(editorProvider.notifier).saveCurrentProject();
                }
              } else if (value == 'delete') {
                final confirm = await _showDeleteConfirmDialog(project.name);
                if (confirm == true) {
                  // Pop back to dashboard
                  if (mounted) Navigator.pop(context);
                  // Delete local image file
                  try {
                     final file = File(project.imagePath);
                     if (await file.exists()) {
                       await file.delete();
                     }
                  } catch (e) {
                    // Ignore or handle delete file failure
                  }
                  // Delete from DB
                  await DatabaseHelper.instance.deleteProject(project.id);
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: Color(0xFF3D30EC), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Rename Project',
                      style: GoogleFonts.outfit(color: _primaryTextColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    const Icon(Icons.delete_rounded, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Delete Project',
                      style: GoogleFonts.outfit(color: _primaryTextColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
            color: _cardBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _borderColor),
            ),
          ),
          const SizedBox(width: 4),
          // Save
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: OutlinedButton(
              onPressed: () async {
                await ref.read(editorProvider.notifier).saveCurrentProject();
                if (mounted) Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3A3530), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                'SAVE',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF3A3530),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Export
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3A3530).withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _exportComposition,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE2D1C3),
                  foregroundColor: const Color(0xFF3A3530),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(
                  'EXPORT',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Main Work Canvas
          Expanded(
            child: GestureDetector(
              onTap: () => ref.read(editorProvider.notifier).clearSelection(),
              child: Container(
                color: const Color(0xFFFDFCFB),
                width: double.infinity,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildCanvasContent(project, editorState, activeLayer, constraints);
                  },
                ),
              ),
            ),
          ),

          // Quick action layer controls (only when layer is selected)
          if (activeLayer != null) _buildLayerQuickActions(activeLayer),

          // Bottom properties panel sheets
          _buildPropertiesPanel(activeLayer, project),
        ],
      ),
    ),
    );
  }

  Widget _buildCanvasContent(
    Project project,
    EditorState state,
    TextLayer? activeLayer,
    BoxConstraints constraints,
  ) {
    // 1. Calculate image dimensions inside available canvas area
    // For preview, we assume a default landscape size or check background file dimensions
    // We'll read the image file coordinates safely
    final File imageFile = File(project.imagePath);
    if (!imageFile.existsSync()) {
      return Center(
        child: Text(
          'Background image file missing.',
          style: GoogleFonts.outfit(color: Colors.redAccent),
        ),
      );
    }

    // Load and resolve image aspect ratio asynchronously, with a cache to prevent layout jank
    if (!_aspectRatioCache.containsKey(project.imagePath)) {
      // Set initial fallback aspect ratio
      _aspectRatioCache[project.imagePath] = 16.0 / 9.0;
      
      // Resolve size asynchronously
      imageFile.readAsBytes().then((bytes) {
        decodeImageFromList(bytes).then((image) {
          if (mounted) {
            setState(() {
              _aspectRatioCache[project.imagePath] = image.width / image.height;
            });
          }
        }).catchError((_) {});
      }).catchError((_) {});
    }

    final double imageAspectRatio = _aspectRatioCache[project.imagePath] ?? (16.0 / 9.0);
    
    // Fit canvas aspect ratio to image
    double canvasW;
    double canvasH;
    final double availW = constraints.maxWidth - 32;
    final double availH = constraints.maxHeight - 32;
    final double availRatio = availW / availH;

    if (imageAspectRatio > availRatio) {
      canvasW = availW;
      canvasH = availW / imageAspectRatio;
    } else {
      canvasH = availH;
      canvasW = availH * imageAspectRatio;
    }

    final Size canvasSize = Size(canvasW, canvasH);

    // Apply color filters matrix
    final ColorFilter compositeFilter = ColorFilterHelper.getAdjustmentFilter(
      brightness: project.imageSettings.brightness,
      contrast: project.imageSettings.contrast,
      saturation: project.imageSettings.saturation,
    );

    return Center(
      child: RepaintBoundary(
        key: _repaintBoundaryKey,
        child: Container(
          width: canvasSize.width,
          height: canvasSize.height,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: const Color(0xFFE2D1C3), width: 1.5),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Background Image with adjustment filters applied
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..rotateZ(project.imageSettings.rotation * math.pi / 180)
                  ..scale(
                    project.imageSettings.isFlippedHorizontal ? -1.0 : 1.0,
                    project.imageSettings.isFlippedVertical ? -1.0 : 1.0,
                  ),
                child: ColorFiltered(
                  colorFilter: compositeFilter,
                  child: ClipRect(
                    clipper: _CropClipper(
                      left: project.imageSettings.cropLeft,
                      top: project.imageSettings.cropTop,
                      right: project.imageSettings.cropRight,
                      bottom: project.imageSettings.cropBottom,
                    ),
                    child: Image.file(
                      imageFile,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              // 2. Interactive text layers list
              // We draw layers sequentially. The last layer in the list is drawn on top.
              ...project.textLayers.map((layer) {
                final bool isSelected = state.selectedLayerId == layer.id;
                return CanvasGestureDetector(
                  layer: layer,
                  isSelected: isSelected,
                  canvasSize: canvasSize,
                  onTap: () => ref.read(editorProvider.notifier).selectLayer(layer.id),
                  onGestureStart: () => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
                  onPositionChanged: (x, y) {
                    ref.read(editorProvider.notifier).updateTextLayer(
                          layer.copyWith(x: x, y: y),
                          pushToHistory: false,
                        );
                  },
                  onTransformChanged: (scale, rotation, curvature) {
                    ref.read(editorProvider.notifier).updateTextLayer(
                          layer.copyWith(scale: scale, rotation: rotation, curvature: curvature),
                          pushToHistory: false,
                        );
                  },
                );
              }).toList(),
              
              // 3. Crop Overlay (active only in Crop mode)
              if (_tabController.index == 2)
                CropOverlay(
                  canvasSize: canvasSize,
                  imageSettings: project.imageSettings,
                  onGestureStart: () => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
                  onChanged: (newSettings) {
                    ref.read(editorProvider.notifier).updateImageSettings(newSettings, pushToHistory: false);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLayerQuickActions(TextLayer layer) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2D1C3), // Muted Warm Beige / Taupe
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: const Color(0xFF3A3530).withOpacity(0.12),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle at the very top of the sheet
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3A3530).withOpacity(0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionBtn(
                Icons.edit_note_rounded,
                'Edit Text',
                () => _showTextEditBottomSheet(layer),
              ),
              _buildQuickActionBtn(
                Icons.flip_to_front_rounded,
                'To Front',
                () => ref.read(editorProvider.notifier).changeLayerOrder(layer.id, true),
              ),
              _buildQuickActionBtn(
                Icons.flip_to_back_rounded,
                'To Back',
                () => ref.read(editorProvider.notifier).changeLayerOrder(layer.id, false),
              ),
              _buildQuickActionBtn(
                Icons.copy_all_rounded,
                'Duplicate',
                () => ref.read(editorProvider.notifier).duplicateTextLayer(layer.id),
              ),
              _buildQuickActionBtn(
                Icons.delete_forever_rounded,
                'Delete',
                () => ref.read(editorProvider.notifier).deleteTextLayer(layer.id),
                color: const Color(0xFFD32F2F), // Refined high-contrast red
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionBtn(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final activeColor = color ?? _primaryTextColor;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: activeColor, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.outfit(color: activeColor.withOpacity(0.7), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertiesPanel(TextLayer? activeLayer, Project project) {
    final bool hasQuickActions = activeLayer != null;

    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: hasQuickActions
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(32)),
        border: hasQuickActions
            ? null
            : Border(
                top: BorderSide(
                  color: _borderColor,
                  width: 1.5,
                ),
              ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle indicator for premium feel (only when quick actions are not shown at the top)
            if (!hasQuickActions)
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3530).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Tabs headers
            TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF3A3530),
              labelColor: const Color(0xFF3A3530),
              unselectedLabelColor: const Color(0xFF3A3530).withOpacity(0.5),
              indicatorSize: TabBarIndicatorSize.label,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.8),
              tabs: const [
                Tab(text: 'TEXT PROPERTIES'),
                Tab(text: 'FILTERS'),
                Tab(text: 'CROP & ROTATE'),
              ],
            ),

            // Tab View contents
            SizedBox(
              height: 250,
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Prevent swipe conflict with canvas gesture
                children: [
                  // Tab 0: Text Properties
                  activeLayer != null
                      ? _buildTextPropertiesTab(activeLayer)
                      : Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (project.textLayers.isNotEmpty) ...[
                                _buildLayerSelector(project.textLayers, null),
                                const SizedBox(height: 20),
                              ],
                              Text(
                                'Select a text layer to edit, or add one:',
                                style: GoogleFonts.outfit(color: _secondaryTextColor.withOpacity(0.7)),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  ref.read(editorProvider.notifier).addTextLayer();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE2D1C3),
                                  foregroundColor: const Color(0xFF3A3530),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                icon: const Icon(Icons.add_rounded, color: Color(0xFF3A3530)),
                                label: Text('ADD TEXT LAYER', style: GoogleFonts.outfit(color: Color(0xFF3A3530), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                      // Tab 1: Image adjustment filters
                      _buildFiltersTab(project),

                      // Tab 2: Crop & rotate controls
                      _buildCropRotateTab(project),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }

  Widget _buildLayerSelector(List<TextLayer> layers, String? selectedLayerId) {
    if (layers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'LAYERS IN USE (${layers.length})',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3530).withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: layers.length,
            itemBuilder: (context, index) {
              final layer = layers[index];
              final isSelected = layer.id == selectedLayerId;
              final String layerTextPreview = layer.text.trim().isEmpty 
                  ? 'Empty Layer' 
                  : (layer.text.length > 15 ? '${layer.text.substring(0, 12)}...' : layer.text);

              return GestureDetector(
                onTap: () {
                  ref.read(editorProvider.notifier).selectLayer(layer.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF3A3530) : const Color(0xFFFDFCFB),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF3A3530) : const Color(0xFFE2D1C3),
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFF3A3530).withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected 
                              ? const Color(0xFFFDFCFB).withOpacity(0.2) 
                              : const Color(0xFF3A3530).withOpacity(0.08),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: GoogleFonts.outfit(
                            color: isSelected ? const Color(0xFFFDFCFB) : const Color(0xFF3A3530),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        layerTextPreview,
                        style: GoogleFonts.outfit(
                          color: isSelected ? const Color(0xFFFDFCFB) : const Color(0xFF3A3530),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTextPropertiesTab(TextLayer layer) {
    final project = ref.read(editorProvider).project;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (project != null && project.textLayers.isNotEmpty) ...[
            _buildLayerSelector(project.textLayers, layer.id),
            const SizedBox(height: 20),
          ],
          // Font Family scrolling selector
          Text(
            'FONT FAMILY',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3A3530), letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _fontFamilies.length,
              itemBuilder: (context, index) {
                final font = _fontFamilies[index];
                final isSelected = layer.fontFamily == font;
                return GestureDetector(
                  onTap: () {
                    ref.read(editorProvider.notifier).updateTextLayer(layer.copyWith(fontFamily: font));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE2D1C3) : const Color(0xFFFDFCFB),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3A3530) : _borderColor,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      font,
                      style: GoogleFonts.getFont(font, textStyle: GoogleFonts.outfit(
                        color: const Color(0xFF3A3530),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      )),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Curvature slider
          _buildPropertySlider(
            label: 'CURVETURE',
            value: layer.curvature,
            min: -100.0,
            max: 100.0,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateTextLayer(layer.copyWith(curvature: val), pushToHistory: false);
            },
            displayValue: '${layer.curvature.toInt()}%',
          ),
          const SizedBox(height: 12),

          // Size slider
          _buildPropertySlider(
            label: 'FONT SIZE',
            value: layer.fontSize,
            min: 12.0,
            max: 80.0,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateTextLayer(layer.copyWith(fontSize: val), pushToHistory: false);
            },
            displayValue: '${layer.fontSize.toInt()}px',
          ),
          const SizedBox(height: 12),

          // Letter Spacing slider
          _buildPropertySlider(
            label: 'LETTER SPACING',
            value: layer.letterSpacing,
            min: -5.0,
            max: 30.0,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateTextLayer(layer.copyWith(letterSpacing: val), pushToHistory: false);
            },
            displayValue: '${layer.letterSpacing.toStringAsFixed(1)}',
          ),
          const SizedBox(height: 12),

          // Opacity slider
          _buildPropertySlider(
            label: 'OPACITY',
            value: layer.opacity,
            min: 0.1,
            max: 1.0,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateTextLayer(layer.copyWith(opacity: val), pushToHistory: false);
            },
            displayValue: '${(layer.opacity * 100).toInt()}%',
          ),
          const SizedBox(height: 16),

          // Color circles row
          Text(
            'TEXT COLOR',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3A3530), letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colors.length,
              itemBuilder: (context, index) {
                final col = _colors[index];
                final isSelected = layer.colorValue == col.value;
                return GestureDetector(
                  onTap: () {
                    ref.read(editorProvider.notifier).updateTextLayer(layer.copyWith(colorValue: col.value));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: col,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3A3530) : const Color(0xFFE2D1C3),
                        width: isSelected ? 3 : 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: col.withOpacity(0.3),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Stroke borders properties
          Text(
            'TEXT OUTLINE / STROKE',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3A3530), letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          _buildPropertySlider(
            label: 'OUTLINE WIDTH',
            value: layer.strokeWidth,
            min: 0.0,
            max: 10.0,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateTextLayer(
                    layer.copyWith(
                      strokeWidth: val,
                      strokeColorValue: layer.strokeColorValue ?? const Color(0xFF3A3530).value,
                    ),
                    pushToHistory: false,
                  );
            },
            displayValue: '${layer.strokeWidth.toStringAsFixed(1)}px',
          ),
          const SizedBox(height: 8),
          // Outline Color Selector
          Row(
            children: [
              Text(
                'OUTLINE COLOR:  ',
                style: GoogleFonts.outfit(fontSize: 11, color: _secondaryTextColor),
              ),
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _colors.length,
                    itemBuilder: (context, index) {
                      final col = _colors[index];
                      final isSelected = layer.strokeColorValue == col.value;
                      return GestureDetector(
                        onTap: () {
                          ref.read(editorProvider.notifier).updateTextLayer(
                                layer.copyWith(strokeColorValue: col.value),
                              );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3A3530) : const Color(0xFFE2D1C3),
                              width: isSelected ? 2.5 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Clear Outline button
              TextButton(
                onPressed: () {
                  ref.read(editorProvider.notifier).updateTextLayer(
                        layer.copyWith(strokeColorValue: null, strokeWidth: 0),
                      );
                },
                child: Text(
                  'CLEAR',
                  style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2D1C3)),
          const SizedBox(height: 16),

          // GRADIENT PRESETS
          Text(
            'GRADIENT TEXT FILL',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3A3530), letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // Solid Reset Button
                GestureDetector(
                  onTap: () {
                    ref.read(editorProvider.notifier).updateTextLayer(
                          layer.copyWith(clearGradient: true),
                        );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: layer.gradientColors == null ? const Color(0xFFE2D1C3) : const Color(0xFFFDFCFB),
                      border: Border.all(
                        color: layer.gradientColors == null ? const Color(0xFF3A3530) : _borderColor,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'SOLID COLOR',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF3A3530),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                // Gradient Presets list
                ..._gradientPresets.entries.map((entry) {
                  final presetColors = entry.value;
                  final isSelected = layer.gradientColors != null &&
                      layer.gradientColors!.length == presetColors.length &&
                      layer.gradientColors!.first == presetColors.first;
                  return GestureDetector(
                    onTap: () {
                      ref.read(editorProvider.notifier).updateTextLayer(
                            layer.copyWith(gradientColors: presetColors, clearGradient: false),
                          );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: presetColors.map((c) => Color(c)).toList(),
                        ),
                        border: Border.all(
                          color: isSelected ? Colors.white : _borderColor,
                          width: isSelected ? 2.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          entry.key.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              const Shadow(
                                color: Colors.black,
                                blurRadius: 4,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2D1C3)),
          const SizedBox(height: 16),

          // DROP SHADOW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DROP SHADOW',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3A3530), letterSpacing: 1.0),
              ),
              Switch(
                value: layer.shadowColorValue != null,
                activeColor: const Color(0xFFE2D1C3),
                activeTrackColor: const Color(0xFF3A3530),
                onChanged: (val) {
                  ref.read(editorProvider.notifier).updateTextLayer(
                        layer.copyWith(
                          shadowColorValue: val ? 0xFF3A3530 : null,
                          clearShadow: !val,
                        ),
                      );
                },
              ),
            ],
          ),
          if (layer.shadowColorValue != null) ...[
            const SizedBox(height: 8),
            // Shadow Blur Slider
            _buildPropertySlider(
              label: 'SHADOW BLUR',
              value: layer.shadowBlur,
              min: 0.0,
              max: 20.0,
              onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
              onChanged: (val) {
                ref.read(editorProvider.notifier).updateTextLayer(
                      layer.copyWith(shadowBlur: val),
                      pushToHistory: false,
                    );
              },
              displayValue: '${layer.shadowBlur.toInt()}px',
            ),
            const SizedBox(height: 8),
            // Shadow Offset X Slider
            _buildPropertySlider(
              label: 'SHADOW OFFSET X',
              value: layer.shadowOffsetX,
              min: -15.0,
              max: 15.0,
              onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
              onChanged: (val) {
                ref.read(editorProvider.notifier).updateTextLayer(
                      layer.copyWith(shadowOffsetX: val),
                      pushToHistory: false,
                    );
              },
              displayValue: '${layer.shadowOffsetX.toInt()}px',
            ),
            const SizedBox(height: 8),
            // Shadow Offset Y Slider
            _buildPropertySlider(
              label: 'SHADOW OFFSET Y',
              value: layer.shadowOffsetY,
              min: -15.0,
              max: 15.0,
              onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
              onChanged: (val) {
                ref.read(editorProvider.notifier).updateTextLayer(
                      layer.copyWith(shadowOffsetY: val),
                      pushToHistory: false,
                    );
              },
              displayValue: '${layer.shadowOffsetY.toInt()}px',
            ),
            const SizedBox(height: 8),
            // Shadow Colors list
            Row(
              children: [
                Text(
                  'SHADOW COLOR:  ',
                  style: GoogleFonts.outfit(fontSize: 11, color: _secondaryTextColor),
                ),
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      itemBuilder: (context, index) {
                        final col = _colors[index];
                        final isSelected = layer.shadowColorValue == col.value;
                        return GestureDetector(
                          onTap: () {
                            ref.read(editorProvider.notifier).updateTextLayer(
                                  layer.copyWith(shadowColorValue: col.value),
                                );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF3A3530) : const Color(0xFFE2D1C3),
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE2D1C3)),
          const SizedBox(height: 16),

          // NEON GLOW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEON GLOW EFFECT',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3A3530), letterSpacing: 1.0),
              ),
              Switch(
                value: layer.glowColorValue != null,
                activeColor: const Color(0xFFE2D1C3),
                activeTrackColor: const Color(0xFF3A3530),
                onChanged: (val) {
                  ref.read(editorProvider.notifier).updateTextLayer(
                        layer.copyWith(
                          glowColorValue: val ? const Color(0xFF3A3530).value : null,
                          clearGlow: !val,
                        ),
                      );
                },
              ),
            ],
          ),
          if (layer.glowColorValue != null) ...[
            const SizedBox(height: 8),
            // Glow Radius Slider
            _buildPropertySlider(
              label: 'GLOW RADIUS',
              value: layer.glowRadius,
              min: 0.0,
              max: 30.0,
              onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
              onChanged: (val) {
                ref.read(editorProvider.notifier).updateTextLayer(
                      layer.copyWith(glowRadius: val),
                      pushToHistory: false,
                    );
              },
              displayValue: '${layer.glowRadius.toInt()}px',
            ),
            const SizedBox(height: 8),
            // Glow Colors list
            Row(
              children: [
                Text(
                  'GLOW COLOR:  ',
                  style: GoogleFonts.outfit(fontSize: 11, color: _secondaryTextColor),
                ),
                Expanded(
                  child: SizedBox(
                    height: 28,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      itemBuilder: (context, index) {
                        final col = _colors[index];
                        final isSelected = layer.glowColorValue == col.value;
                        return GestureDetector(
                          onTap: () {
                            ref.read(editorProvider.notifier).updateTextLayer(
                                  layer.copyWith(glowColorValue: col.value),
                                );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: col,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? const Color(0xFF3A3530) : const Color(0xFFE2D1C3),
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltersTab(Project project) {
    final settings = project.imageSettings;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brightness slider
          _buildPropertySlider(
            label: 'BRIGHTNESS',
            value: settings.brightness,
            min: -0.8,
            max: 0.8,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateImageSettings(
                    settings.copyWith(brightness: val),
                    pushToHistory: false,
                  );
            },
            displayValue: '${(settings.brightness * 100).toInt()}%',
          ),
          const SizedBox(height: 16),

          // Contrast slider
          _buildPropertySlider(
            label: 'CONTRAST',
            value: settings.contrast,
            min: 0.3,
            max: 1.8,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateImageSettings(
                    settings.copyWith(contrast: val),
                    pushToHistory: false,
                  );
            },
            displayValue: '${(settings.contrast * 100).toInt()}%',
          ),
          const SizedBox(height: 16),

          // Saturation slider
          _buildPropertySlider(
            label: 'SATURATION',
            value: settings.saturation,
            min: 0.0,
            max: 2.0,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateImageSettings(
                    settings.copyWith(saturation: val),
                    pushToHistory: false,
                  );
            },
            displayValue: '${(settings.saturation * 100).toInt()}%',
          ),
          const SizedBox(height: 16),
          // Reset Filters button
          Center(
            child: TextButton(
              onPressed: () {
                ref.read(editorProvider.notifier).updateImageSettings(
                      settings.copyWith(brightness: 0.0, contrast: 1.0, saturation: 1.0),
                    );
              },
              child: Text(
                'RESET IMAGE ADJUSTMENTS',
                style: GoogleFonts.outfit(color: const Color(0xFF3A3530), fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropRotateTab(Project project) {
    final settings = project.imageSettings;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rotate & Flip buttons row
          Text(
            'TRANSFORMATIONS',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3A3530), letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTransformBtn(
                Icons.rotate_90_degrees_ccw_rounded,
                'Rotate 90°',
                () {
                  final newRotation = (settings.rotation + 90) % 360;
                  ref.read(editorProvider.notifier).updateImageSettings(
                        settings.copyWith(rotation: newRotation),
                      );
                },
              ),
              _buildTransformBtn(
                Icons.flip_rounded,
                'Flip Horiz',
                () {
                  ref.read(editorProvider.notifier).updateImageSettings(
                        settings.copyWith(isFlippedHorizontal: !settings.isFlippedHorizontal),
                      );
                },
              ),
              _buildTransformBtn(
                Icons.flip_rounded,
                'Flip Vert',
                () {
                  ref.read(editorProvider.notifier).updateImageSettings(
                        settings.copyWith(isFlippedVertical: !settings.isFlippedVertical),
                      );
                },
                rotateAngle: math.pi / 2, // Rotate flip icon to signify vertical
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Crop sliders
          Text(
            'CROP CANVAS EDGES',
            style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF3A3530), letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          _buildPropertySlider(
            label: 'CROP LEFT',
            value: settings.cropLeft,
            min: 0.0,
            max: 0.45,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateImageSettings(
                    settings.copyWith(cropLeft: val),
                    pushToHistory: false,
                  );
            },
            displayValue: '${(settings.cropLeft * 100).toInt()}%',
          ),
          const SizedBox(height: 8),
          _buildPropertySlider(
            label: 'CROP RIGHT',
            value: settings.cropRight,
            min: 0.55,
            max: 1.0,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateImageSettings(
                    settings.copyWith(cropRight: val),
                    pushToHistory: false,
                  );
            },
            displayValue: '${((1.0 - settings.cropRight) * 100).toInt()}%',
          ),
          const SizedBox(height: 8),
          _buildPropertySlider(
            label: 'CROP TOP',
            value: settings.cropTop,
            min: 0.0,
            max: 0.45,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateImageSettings(
                    settings.copyWith(cropTop: val),
                    pushToHistory: false,
                  );
            },
            displayValue: '${(settings.cropTop * 100).toInt()}%',
          ),
          const SizedBox(height: 8),
          _buildPropertySlider(
            label: 'CROP BOTTOM',
            value: settings.cropBottom,
            min: 0.55,
            max: 1.0,
            onChangeStart: (val) => ref.read(editorProvider.notifier).pushCurrentStateToHistory(),
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateImageSettings(
                    settings.copyWith(cropBottom: val),
                    pushToHistory: false,
                  );
            },
            displayValue: '${((1.0 - settings.cropBottom) * 100).toInt()}%',
          ),
        ],
      ),
    );
  }

  Widget _buildTransformBtn(IconData icon, String label, VoidCallback onTap, {double rotateAngle = 0}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _isDark ? const Color(0xFF262626) : const Color(0xFFF3F4F6),
        foregroundColor: _primaryTextColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _borderColor),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: rotateAngle,
            child: Icon(icon, color: const Color(0xFF3A3530), size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.outfit(fontSize: 12, color: _primaryTextColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertySlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required String displayValue,
    ValueChanged<double>? onChangeStart,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                color: _secondaryTextColor,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              displayValue,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3A3530),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4, // 4px thick tactile track
            activeTrackColor: const Color(0xFFE2D1C3),
            inactiveTrackColor: const Color(0xFFFDFCFB),
            thumbColor: const Color(0xFFE2D1C3),
            overlayColor: const Color(0xFFE2D1C3).withOpacity(0.15),
            valueIndicatorColor: const Color(0xFF3A3530),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, pressedElevation: 6), // 10px tactile thumb with glowing hover/press
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeStart: onChangeStart,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  Future<String?> _showRenameDialog(String currentName) async {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _borderColor),
          ),
          title: Text(
            'Rename Project',
            style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            style: GoogleFonts.outfit(color: _primaryTextColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: _scaffoldBgColor,
              hintText: 'Enter name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF3D30EC)),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: GoogleFonts.outfit(color: _secondaryTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D30EC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'RENAME',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmDialog(String projectName) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _borderColor),
          ),
          title: Text(
            'Delete Project?',
            style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to permanently delete "$projectName"? This will remove all layers and cached image storage.',
            style: GoogleFonts.outfit(color: _secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'CANCEL',
                style: GoogleFonts.outfit(color: _secondaryTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'DELETE',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CropClipper extends CustomClipper<Rect> {
  final double left;
  final double top;
  final double right;
  final double bottom;

  _CropClipper({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      left * size.width,
      top * size.height,
      right * size.width,
      bottom * size.height,
    );
  }

  @override
  bool shouldReclip(covariant _CropClipper oldClipper) {
    return oldClipper.left != left ||
        oldClipper.top != top ||
        oldClipper.right != right ||
        oldClipper.bottom != bottom;
  }
}
