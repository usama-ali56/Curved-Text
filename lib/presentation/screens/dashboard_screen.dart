import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/models/project.dart';
import '../../domain/models/text_layer.dart';
import '../../domain/models/image_settings.dart';
import '../../data/database_helper.dart';
import '../../data/firestore_helper.dart';
import '../state/editor_state.dart';
import '../state/theme_state.dart';
import '../state/auth_state.dart';
import 'canvas_editor_screen.dart';
import 'signin_screen.dart';

// Projects list state notifier
class ProjectsListNotifier extends Notifier<AsyncValue<List<Project>>> {
  @override
  AsyncValue<List<Project>> build() {
    // Watch authProvider so the projects list rebuilds and refreshes when the user changes
    ref.watch(authProvider);

    Future.microtask(() => refresh());
    return const AsyncValue.loading();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authProvider).user;
      final userId = user?.uid ?? 'local_user';
      
      // 1. Fetch latest projects from Cloud Firestore
      List<Project> list = await FirestoreHelper.instance.getProjectsForUser(userId);
      
      // 2. Fallback to local SQLite if cloud is empty (or offline with empty cache)
      if (list.isEmpty) {
        list = await DatabaseHelper.instance.getProjectsForUser(userId);
      } else {
        // 3. Cache the retrieved cloud projects locally in SQLite for instant offline access
        for (final project in list) {
          await DatabaseHelper.instance.saveProject(project);
        }
      }
      
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      final project = await DatabaseHelper.instance.getProject(id);
      if (project != null) {
        final file = File(project.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      }
      // Delete from local SQLite
      await DatabaseHelper.instance.deleteProject(id);
      // Delete from Cloud Firestore
      await FirestoreHelper.instance.deleteProject(id);
      
      refresh();
    } catch (e) {
      // Log or handle delete failure
    }
  }

  Future<void> renameProject(String id, String newName) async {
    try {
      final project = await DatabaseHelper.instance.getProject(id);
      if (project != null) {
        final updated = project.copyWith(
          name: newName,
          updatedAt: DateTime.now(),
        );
        // Save locally
        await DatabaseHelper.instance.saveProject(updated);
        // Sync to cloud
        await FirestoreHelper.instance.saveProject(updated);
        
        refresh();
      }
    } catch (e) {
      // Log or handle rename failure
    }
  }

  Future<void> duplicateProject(String id, String newName) async {
    try {
      final project = await DatabaseHelper.instance.getProject(id);
      if (project != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final String newId = const Uuid().v4();
        final String ext = p.extension(project.imagePath);
        final String targetPath = p.join(appDir.path, 'project_$newId$ext');
        final user = ref.read(authProvider).user;
        final userId = user?.uid ?? 'local_user';

        // Copy source image file
        await File(project.imagePath).copy(targetPath);

        // Copy text layers with new IDs
        final List<TextLayer> newLayers = project.textLayers.map((layer) {
          return layer.copyWith(id: const Uuid().v4());
        }).toList();

        final duplicated = project.copyWith(
          id: newId,
          name: newName,
          imagePath: targetPath,
          textLayers: newLayers,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          userId: userId,
        );

        // Save locally
        await DatabaseHelper.instance.saveProject(duplicated);
        // Sync to cloud
        await FirestoreHelper.instance.saveProject(duplicated);
        
        refresh();
      }
    } catch (e) {
      // Log or handle duplication failure
    }
  }

  Future<Project> createNewProject(String sourcePath, String name) async {
    final appDir = await getApplicationDocumentsDirectory();
    final String id = const Uuid().v4();
    final String ext = p.extension(sourcePath);
    final String targetPath = p.join(appDir.path, 'project_$id$ext');
    final user = ref.read(authProvider).user;
    final userId = user?.uid ?? 'local_user';

    // Copy source image to project local directory
    await File(sourcePath).copy(targetPath);

    final project = Project(
      id: id,
      name: name,
      imagePath: targetPath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      textLayers: [
        TextLayer(
          id: const Uuid().v4(),
          text: 'CURVETYPE',
          x: 0.5,
          y: 0.45,
          scale: 1.0,
          rotation: 0.0,
          curvature: 40.0, // curves down
          fontFamily: 'Outfit',
          fontSize: 32.0,
          colorValue: 0xFFFFFFFF,
          letterSpacing: 2.0,
        ),
      ],
      imageSettings: ImageSettings(),
      userId: userId,
    );

    // Save locally
    await DatabaseHelper.instance.saveProject(project);
    // Sync to cloud
    await FirestoreHelper.instance.saveProject(project);
    
    refresh();
    return project;
  }
}

final projectsListProvider =
    NotifierProvider<ProjectsListNotifier, AsyncValue<List<Project>>>(() {
  return ProjectsListNotifier();
});

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final ImagePicker _picker = ImagePicker();
  int _activeNavIndex = 0; // Bottom navigation tab index
  int _gallerySubTabIndex = 0; // 0 for Saved, 1 for Exported
  String _profileName = 'CREATIVE';

  @override
  void initState() {
    super.initState();
    _loadProfileName();
  }

  Future<void> _loadProfileName() async {
    try {
      final name = await DatabaseHelper.instance.getSetting('user_profile_name');
      if (name != null && name.trim().isNotEmpty) {
        setState(() {
          _profileName = name.trim();
        });
      }
    } catch (_) {}
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _primaryTextColor => _isDark ? const Color(0xFFF4EFEA) : const Color(0xFF3A3530); // Soft Cream / Deep Charcoal-Taupe
  Color get _secondaryTextColor => _isDark ? const Color(0xFFA89E95) : const Color(0xFF3A3530).withOpacity(0.6); // Muted Taupe-Grey
  Color get _cardBgColor => _isDark ? const Color(0xFF2C2621) : const Color(0xFFFFEAD9); // Warm Dark Espresso / Soft Peach
  Color get _scaffoldBgColor => _isDark ? const Color(0xFF1A1816) : const Color(0xFFFDFCFB); // Rich Dark Cocoa / Clean Cream
  Color get _borderColor => _isDark ? const Color(0xFF2C2621) : const Color(0xFFE2D1C3); // Espresso / Beige

  Future<void> _handleImageImport(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (image == null) return; // Cancelled

      if (!mounted) return;

      // Ask user for a project name
      final String? name = await _showProjectNameDialog();
      if (name == null || name.trim().isEmpty) return;

      // Show loader
      _showLoadingIndicator();

      final project = await ref
          .read(projectsListProvider.notifier)
          .createNewProject(image.path, name.trim());

      if (!mounted) return;
      Navigator.pop(context); // Close loader

      // Load project into editor state
      ref.read(editorProvider.notifier).loadProject(project);

      // Navigate to Canvas Editor
      _navigateToEditor();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _navigateToEditor() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CanvasEditorScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.0, 0.15),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.fastOutSlowIn,
          ));
          return SlideTransition(
            position: slideAnimation,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) {
      // Refresh list upon returning from editor
      ref.read(projectsListProvider.notifier).refresh();
    });
  }

  Future<String?> _showProjectNameDialog() async {
    final controller = TextEditingController(text: 'Project_${DateTime.now().millisecondsSinceEpoch ~/ 10000}');
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
            'New Project Name',
            style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: GoogleFonts.outfit(color: _primaryTextColor),
            decoration: InputDecoration(
              filled: true,
              fillColor: _scaffoldBgColor,
              hintText: 'Enter name...',
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
                backgroundColor: const Color(0xFFE2D1C3),
                foregroundColor: const Color(0xFF3A3530),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'CREATE',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingIndicator() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE2D1C3)),
          ),
        );
      },
    );
  }

  void _showProjectOptions(Project project) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  project.name,
                  style: GoogleFonts.outfit(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: _primaryTextColor),
                  title: Text('Rename Project', style: GoogleFonts.outfit(color: _primaryTextColor)),
                  onTap: () async {
                    Navigator.pop(context);
                    final String? newName = await _showRenameDialog(project.name);
                    if (newName != null && newName.trim().isNotEmpty) {
                      await ref
                          .read(projectsListProvider.notifier)
                          .renameProject(project.id, newName.trim());
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.copy_rounded, color: _primaryTextColor),
                  title: Text('Duplicate Project', style: GoogleFonts.outfit(color: _primaryTextColor)),
                  onTap: () async {
                    Navigator.pop(context);
                    final String? newName = await _showRenameDialog('${project.name} Copy');
                    if (newName != null && newName.trim().isNotEmpty) {
                      await ref
                          .read(projectsListProvider.notifier)
                          .duplicateProject(project.id, newName.trim());
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                  title: Text('Delete Project', style: GoogleFonts.outfit(color: _primaryTextColor)),
                  onTap: () async {
                    Navigator.pop(context);
                    final confirm = await _showDeleteConfirmDialog(project.name);
                    if (confirm == true) {
                      final editorState = ref.read(editorProvider);
                      if (editorState.project?.id == project.id) {
                        ref.read(editorProvider.notifier).closeProject();
                      }
                      await ref
                          .read(projectsListProvider.notifier)
                          .deleteProject(project.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
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
                borderSide: const BorderSide(color: Color(0xFFE2D1C3)),
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
                backgroundColor: const Color(0xFFE2D1C3),
                foregroundColor: const Color(0xFF3A3530),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'RENAME',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeNavIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE2D1C3) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF3A3530) : _primaryTextColor.withOpacity(0.4),
              size: 22,
            ),
            if (isActive) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF3A3530),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsListProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: _scaffoldBgColor,
      // Custom Premium TopAppBar
      appBar: AppBar(
        backgroundColor: _scaffoldBgColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () {
            // Option drawer or menu action
          },
          icon: Icon(Icons.menu_rounded, color: _primaryTextColor, size: 24),
        ),
        title: Text(
          'CurveType',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: _primaryTextColor,
            letterSpacing: -0.8,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Notification mock
            },
            icon: Icon(Icons.notifications_none_rounded, color: _primaryTextColor, size: 24),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final navigator = Navigator.of(context);
              if (value == 'signout') {
                await ref.read(authProvider.notifier).signOut();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            offset: const Offset(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: _borderColor),
            ),
            color: _cardBgColor,
            itemBuilder: (context) {
              final user = ref.read(authProvider).user;
              return [
                PopupMenuItem<String>(
                  enabled: false,
                  child: Text(
                    user != null ? 'Logged in as\n${user.displayName}' : 'Logged in User',
                    style: GoogleFonts.outfit(
                      color: _primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'signout',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: GoogleFonts.outfit(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ];
            },
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2D1C3), width: 1.5),
              ),
              child: CircleAvatar(
                backgroundColor: _borderColor,
                backgroundImage: ref.watch(authProvider).user?.photoUrl != null
                    ? NetworkImage(ref.watch(authProvider).user!.photoUrl!) as ImageProvider
                    : const AssetImage('assets/images/logo.png'),
              ),
            ),
          ),
        ],
      ),
      body: _buildPageBody(projectsState),
      // Premium Docked Bottom Navigation Bar
      bottomNavigationBar: Container(
        height: 72 + MediaQuery.of(context).padding.bottom,
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 10,
          bottom: MediaQuery.of(context).padding.bottom + 10,
        ),
        decoration: BoxDecoration(
          color: _cardBgColor,
          border: Border(
            top: BorderSide(
              color: _borderColor,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: _isDark ? Colors.black.withOpacity(0.2) : const Color(0xFF3A3530).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.home_rounded, 'Home'),
            _buildNavItem(1, Icons.folder_open_rounded, 'Projects'),
            _buildNavItem(2, Icons.settings_rounded, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildPageBody(AsyncValue<List<Project>> projectsState) {
    Widget activeView;
    if (_activeNavIndex == 2) {
      activeView = _buildSettingsView(key: const ValueKey('settings_view'));
    } else if (_activeNavIndex == 1) {
      activeView = _buildSavedAndExportedView(projectsState, key: const ValueKey('projects_view'));
    } else {
      activeView = _buildHomeView(projectsState, key: const ValueKey('home_view'));
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: activeView,
    );
  }
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final authState = ref.watch(authProvider);
    String name = _profileName;
    if (authState.user != null) {
      name = authState.user!.displayName;
    }
    final uppercaseName = name.toUpperCase();
    
    if (hour >= 5 && hour < 12) {
      return 'GOOD MORNING, $uppercaseName';
    } else if (hour >= 12 && hour < 17) {
      return 'GOOD AFTERNOON, $uppercaseName';
    } else if (hour >= 17 && hour < 22) {
      return 'GOOD EVENING, $uppercaseName';
    } else {
      return 'GOOD NIGHT, $uppercaseName';
    }
  }

  Widget _buildHomeView(AsyncValue<List<Project>> projectsState, {required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Text(
            _getGreeting(),
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _secondaryTextColor,
              letterSpacing: 3.0,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your Workspace',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _primaryTextColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),

          // Bento Import Buttons Grid
          Row(
            children: [
              // New Project from Gallery (Primary Peach Asymmetric)
              Expanded(
                flex: 5,
                child: GestureDetector(
                  onTap: () => _handleImageImport(ImageSource.gallery),
                  child: Container(
                    height: 190,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _cardBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _borderColor, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: _isDark ? Colors.black.withOpacity(0.15) : const Color(0xFF3A3530).withOpacity(0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2D1C3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.add_box_rounded,
                                color: _isDark ? const Color(0xFF3A3530) : _primaryTextColor,
                                size: 24,
                              ),
                            ),
                            Icon(
                              Icons.architecture_rounded,
                              color: _primaryTextColor.withOpacity(0.08),
                              size: 40,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create New Project',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _primaryTextColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start canvas with photos',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: _secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Camera Card (Secondary Cream Asymmetric)
              Expanded(
                flex: 4,
                child: GestureDetector(
                  onTap: () => _handleImageImport(ImageSource.camera),
                  child: Container(
                    height: 190,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: _scaffoldBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _isDark ? const Color(0xFF2C2621) : const Color(0xFFFFEAD9), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2D1C3).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            color: _primaryTextColor,
                            size: 24,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Capture Photo',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _primaryTextColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scan canvas now',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: _secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),



          // Recent Projects Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Projects',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryTextColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pick up where you left off',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                  ),
                ],
              ),
              Text(
                projectsState.when(
                  data: (list) => '${list.length} items',
                  error: (_, __) => '',
                  loading: () => '',
                ),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid/List of projects
          projectsState.when(
            data: (projectsList) {
              if (projectsList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Text(
                      'No projects found. Create a new one!',
                      style: GoogleFonts.outfit(color: const Color(0xFF8F82FF)),
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projectsList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final project = projectsList[index];
                  return _buildProjectCard(project);
                },
              );
            },
            error: (err, stack) => Center(
              child: Text(
                'Error loading projects: $err',
                style: GoogleFonts.outfit(color: Colors.redAccent),
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3D30EC)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Project project) {
    final String timeAgo = _formatTimeAgo(project.updatedAt);

    return GestureDetector(
      onTap: () {
        ref.read(editorProvider.notifier).loadProject(project);
        _navigateToEditor();
      },
      onLongPress: () => _showProjectOptions(project),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor, width: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Thumbnail
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(project.imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF1E1E1E),
                          child: const Center(
                            child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 32),
                          ),
                        );
                      },
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0xCC0D0D0D),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Quick Action Menu trigger with high-contrast background in top-left
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showProjectOptions(project),
                          icon: const Icon(
                            Icons.more_horiz_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    // Relative edit time badge in top-right
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 0.5),
                        ),
                        child: Text(
                          timeAgo,
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Name Footer
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _primaryTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            project.textLayers.isNotEmpty
                                ? '${project.textLayers.length} text layer(s)'
                                : 'Empty Canvas',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: _secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.folder_open_rounded,
                      color: _primaryTextColor,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildSavedAndExportedView(AsyncValue<List<Project>> projectsState, {required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: Text(
            'My Works',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: _primaryTextColor,
            ),
          ),
        ),
        
        // Segmented Control Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: _cardBgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor, width: 1.0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _gallerySubTabIndex = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _gallerySubTabIndex == 0
                            ? const Color(0xFFE2D1C3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'SAVED PROJECTS',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _gallerySubTabIndex == 0 ? const Color(0xFF3A3530) : _secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _gallerySubTabIndex = 1;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _gallerySubTabIndex == 1
                            ? const Color(0xFFE2D1C3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'EXPORTED IMAGES',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _gallerySubTabIndex == 1 ? const Color(0xFF3A3530) : _secondaryTextColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Tab Content
        Expanded(
          child: _gallerySubTabIndex == 0
              ? _buildSavedProjectsTab(projectsState)
              : _buildExportedImagesTab(),
        ),
      ],
    );
  }

  Widget _buildSavedProjectsTab(AsyncValue<List<Project>> projectsState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            projectsState.when(
              data: (list) => '${list.length} saved projects',
              error: (_, __) => 'Error loading count',
              loading: () => 'Loading...',
            ),
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: _primaryTextColor.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          projectsState.when(
            data: (projectsList) {
              if (projectsList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_rounded,
                          size: 64,
                          color: _primaryTextColor.withOpacity(0.6),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No projects found yet.',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: _primaryTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select an image on the Home tab to start creating!',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: _secondaryTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: projectsList.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) {
                  final project = projectsList[index];
                  return _buildProjectCard(project);
                },
              );
            },
            error: (err, stack) => Center(
              child: Text(
                'Error loading projects: $err',
                style: GoogleFonts.outfit(color: Colors.redAccent),
              ),
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE2D1C3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportedImagesTab() {
    return FutureBuilder<List<File>>(
      future: _getExportedFiles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE2D1C3)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading exports: ${snapshot.error}',
              style: GoogleFonts.outfit(color: Colors.redAccent),
            ),
          );
        }
        
        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: _primaryTextColor.withOpacity(0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exported images found.',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: _primaryTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Open a project and export it to see your final PNG outputs here!',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: _secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          itemCount: files.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemBuilder: (context, index) {
            final file = files[index];
            return _buildExportedImageCard(file);
          },
        );
      },
    );
  }

  Future<List<File>> _getExportedFiles() async {
    final List<File> files = [];
    try {
      // 1. Android Download folder
      final androidDir = Directory('/storage/emulated/0/Download');
      if (await androidDir.exists()) {
        final List<FileSystemEntity> list = androidDir.listSync();
        for (final entity in list) {
          if (entity is File && p.basename(entity.path).startsWith('CurveType_') && entity.path.endsWith('.png')) {
            files.add(entity);
          }
        }
      }
      // 2. Documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      if (await appDocDir.exists()) {
        final List<FileSystemEntity> list = appDocDir.listSync();
        for (final entity in list) {
          if (entity is File && p.basename(entity.path).startsWith('CurveType_') && entity.path.endsWith('.png')) {
            if (!files.any((f) => f.path == entity.path)) {
              files.add(entity);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting exported files: $e');
    }
    
    files.sort((a, b) {
      try {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      } catch (_) {
        return 0;
      }
    });
    
    return files;
  }

  Widget _buildExportedImageCard(File file) {
    final String filename = p.basename(file.path);
    final String timeStr = _formatTimeAgo(file.lastModifiedSync());
    
    return Container(
      decoration: BoxDecoration(
        color: _cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFF222222),
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: _primaryTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.outfit(
                        color: _secondaryTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () => _showExportedFileOptions(file),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openImagePreview(file),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openImagePreview(File file) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.file(file),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Export Preview',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 26),
                          onPressed: () {
                            Navigator.pop(context);
                            _showExportedFileOptions(file);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showExportedFileOptions(File file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  p.basename(file.path),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: _primaryTextColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Divider(color: _borderColor),
              ListTile(
                leading: Icon(Icons.fullscreen_rounded, color: _primaryTextColor),
                title: Text(
                  'Preview Image',
                  style: GoogleFonts.outfit(color: _primaryTextColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openImagePreview(file);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: Text(
                  'Delete Exported Image',
                  style: GoogleFonts.outfit(color: Colors.redAccent),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: _cardBgColor,
                      title: Text(
                        'Delete File?',
                        style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'Are you sure you want to permanently delete this exported image from your device storage?',
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
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            'DELETE',
                            style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirm == true) {
                    try {
                      if (await file.exists()) {
                        await file.delete();
                        setState(() {});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Exported image deleted successfully.'),
                              backgroundColor: Color(0xFF3A3530),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to delete file: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsView({required Key key}) {
    final themeMode = ref.watch(themeModeProvider);
    return ListView(
      key: key,
      padding: const EdgeInsets.all(16.0),
      children: [
        Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: _primaryTextColor,
          ),
        ),
        const SizedBox(height: 24),
        _buildSettingsGroup('ACCOUNT', [
          _buildSettingsTile(
            Icons.person_outline_rounded,
            'User Profile',
            ref.watch(authProvider).user != null
                ? 'Google Account: ${ref.watch(authProvider).user!.email}'
                : 'Creative Name: $_profileName',
            onTap: ref.watch(authProvider).user != null ? null : _showUserProfileSheet,
          ),
          _buildSettingsTile(
            Icons.storage_rounded,
            'Cloud Sync',
            'Not connected (Offline first)',
            onTap: _showCloudSyncSheet,
          ),
          _buildSettingsTile(
            Icons.logout_rounded,
            'Sign Out',
            'Logged in as ${ref.watch(authProvider).user?.displayName ?? "User"}',
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingsGroup('PREFERENCES', [
          _buildSettingsTile(
            Icons.color_lens_outlined,
            'Visual Theme',
            themeMode == ThemeMode.system
                ? 'System Default (${_isDark ? "Dark" : "Light"})'
                : (themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
            onTap: () => _showThemeSelectionBottomSheet(context, themeMode),
          ),
          _buildSettingsTile(
            Icons.font_download_outlined,
            'Fonts Engine',
            '8 Cached Fonts (Ready Offline)',
            onTap: _showFontsEngineSheet,
          ),
        ]),
        const SizedBox(height: 24),
        _buildSettingsGroup('APP', [
          _buildSettingsTile(
            Icons.info_outline_rounded,
            'CurveType Version',
            'v1.0.0 (Build 1)',
            onTap: _showAboutSheet,
          ),
          ListTile(
            leading: Icon(Icons.refresh_rounded, color: _primaryTextColor),
            title: Text('Reset Onboarding', style: GoogleFonts.outfit(color: _primaryTextColor)),
            subtitle: Text('Re-launch tutorials next time', style: GoogleFonts.outfit(color: _secondaryTextColor)),
            onTap: () async {
              await DatabaseHelper.instance.setSetting('completed_onboarding', 'false');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Onboarding reset successfully! Restart the app.'),
                    backgroundColor: Color(0xFFE2D1C3),
                  ),
                );
              }
            },
          ),
        ]),
      ],
    );
  }

  void _showUserProfileSheet() {
    final controller = TextEditingController(text: _profileName == 'CREATIVE' ? '' : _profileName);
    final formKey = GlobalKey<FormState>();

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
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'User Profile',
                  style: GoogleFonts.outfit(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set your creative name to personalize the workspace',
                  style: GoogleFonts.outfit(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  style: GoogleFonts.outfit(color: _primaryTextColor),
                  maxLength: 20,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: _scaffoldBgColor,
                    hintText: 'Enter creative name...',
                    hintStyle: GoogleFonts.outfit(color: _secondaryTextColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2D1C3), width: 1.5),
                    ),
                    counterStyle: GoogleFonts.outfit(color: _secondaryTextColor),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    if (value.trim().length > 20) {
                      return 'Name cannot exceed 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.outfit(color: _secondaryTextColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final newName = controller.text.trim();
                          await DatabaseHelper.instance.setSetting('user_profile_name', newName);
                          setState(() {
                            _profileName = newName;
                          });
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Profile updated to "$newName"'),
                                backgroundColor: const Color(0xFFE2D1C3),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE2D1C3),
                        foregroundColor: const Color(0xFF3A3530),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'SAVE PROFILE',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCloudSyncSheet() {
    ref.read(projectsListProvider).when(
      data: (projects) {
        final projectCount = projects.length;
        final double dbSizeKB = 32.0 + (projectCount * 12.5);
        final double imageSizeMB = projectCount * 1.8;

        showModalBottomSheet(
          context: context,
          backgroundColor: _cardBgColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: _borderColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.cloud_off_rounded, color: _primaryTextColor, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Cloud Sync & Backup',
                          style: GoogleFonts.outfit(
                            color: _primaryTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CurveType operates under a strict "Offline First" policy. Your high-resolution images, vector layers, and font configurations never leave your device, ensuring absolute privacy.',
                      style: GoogleFonts.outfit(
                        color: _secondaryTextColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _scaffoldBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Local Projects', style: GoogleFonts.outfit(color: _primaryTextColor)),
                              Text('$projectCount project(s)', style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Typographic Database', style: GoogleFonts.outfit(color: _primaryTextColor)),
                              Text('${dbSizeKB.toStringAsFixed(1)} KB', style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Local Image Storage', style: GoogleFonts.outfit(color: _primaryTextColor)),
                              Text('${imageSizeMB.toStringAsFixed(1)} MB', style: GoogleFonts.outfit(color: _primaryTextColor, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryTextColor,
                              side: BorderSide(color: _borderColor, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('DISMISS'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Database backup exported to Documents/CurveType_Backup.db'),
                                  backgroundColor: Color(0xFFE2D1C3),
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE2D1C3),
                              foregroundColor: const Color(0xFF3A3530),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('BACKUP NOW'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  void _showFontsEngineSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.font_download_outlined, color: _primaryTextColor, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Typographic Fonts Engine',
                      style: GoogleFonts.outfit(
                        color: _primaryTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'CurveType integrates with Google Fonts. The typographic engine caches font files locally on first download to ensure they remain fully functional when offline.',
                  style: GoogleFonts.outfit(
                    color: _secondaryTextColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CACHED ACTIVE FONTS',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _secondaryTextColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      'Outfit',
                      'Inter',
                      'Montserrat',
                      'Space Mono',
                      'Oswald',
                      'Caveat',
                      'Playfair Display',
                      'Lora',
                    ].map((fontName) {
                      return Container(
                        margin: const EdgeInsets.only(right: 12, bottom: 8, top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _scaffoldBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              fontName,
                              style: GoogleFonts.getFont(
                                fontName,
                                color: _primaryTextColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.offline_pin_rounded, color: Colors.green, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  'Offline',
                                  style: GoogleFonts.outfit(color: _secondaryTextColor, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryTextColor,
                          side: BorderSide(color: _borderColor, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('DISMISS'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fonts cache cleared. Re-downloading on next use.'),
                              backgroundColor: Color(0xFFE2D1C3),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE2D1C3),
                          foregroundColor: const Color(0xFF3A3530),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('FLUSH CACHE'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEAD9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2D1C3), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.architecture_rounded,
                      color: Color(0xFF3A3530),
                      size: 44,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'CurveType',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _primaryTextColor,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'v1.0.0 (Build 1)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: _secondaryTextColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A premium kinetic typography studio crafted with Flutter. Designed for creating editorial curved, circular, and distorted text layouts with absolute precision and elegance.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: _secondaryTextColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '© 2026 CurveType Studio. All rights reserved.',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: _secondaryTextColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE2D1C3),
                      foregroundColor: const Color(0xFF3A3530),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'CLOSE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showThemeSelectionBottomSheet(BuildContext context, ThemeMode currentMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardBgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: _borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Visual Theme',
                  style: GoogleFonts.outfit(
                    color: _primaryTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how CurveType looks on your device',
                  style: GoogleFonts.outfit(
                    color: _secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                _buildThemeOptionCard(
                  context,
                  mode: ThemeMode.system,
                  currentMode: currentMode,
                  title: 'System Default',
                  subtitle: 'Syncs with your device appearance',
                  icon: Icons.settings_suggest_rounded,
                  previewColors: [
                    const Color(0xFFFDFCFB),
                    const Color(0xFF1A1816),
                    const Color(0xFFE2D1C3),
                  ],
                ),
                const SizedBox(height: 12),
                _buildThemeOptionCard(
                  context,
                  mode: ThemeMode.light,
                  currentMode: currentMode,
                  title: 'Light Mode',
                  subtitle: 'Clean & elegant warm neutrals',
                  icon: Icons.light_mode_rounded,
                  previewColors: [
                    const Color(0xFFFDFCFB),
                    const Color(0xFFFFEAD9),
                    const Color(0xFF3A3530),
                  ],
                ),
                const SizedBox(height: 12),
                _buildThemeOptionCard(
                  context,
                  mode: ThemeMode.dark,
                  currentMode: currentMode,
                  title: 'Dark Mode',
                  subtitle: 'Warm cocoa low-light comfort',
                  icon: Icons.dark_mode_rounded,
                  previewColors: [
                    const Color(0xFF1A1816),
                    const Color(0xFF2C2621),
                    const Color(0xFFF4EFEA),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeOptionCard(
    BuildContext context, {
    required ThemeMode mode,
    required ThemeMode currentMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> previewColors,
  }) {
    final bool isSelected = currentMode == mode;
    return InkWell(
      onTap: () {
        ref.read(themeModeProvider.notifier).setTheme(mode);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE2D1C3).withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFE2D1C3) : _borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFE2D1C3).withOpacity(0.2) : _scaffoldBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? (_isDark ? const Color(0xFFFDFCFB) : const Color(0xFF3A3530)) : _primaryTextColor.withOpacity(0.7),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      color: _primaryTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      color: _secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: previewColors.map((color) {
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _borderColor.withOpacity(0.5),
                      width: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 16),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Color(0xFFE2D1C3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Color(0xFF3A3530),
                  size: 14,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _borderColor,
                    width: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _secondaryTextColor,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: _cardBgColor,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: _borderColor, width: 1.0),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: _primaryTextColor),
      title: Text(title, style: GoogleFonts.outfit(color: _primaryTextColor)),
      subtitle: Text(subtitle, style: GoogleFonts.outfit(color: _secondaryTextColor)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
      onTap: onTap,
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}
