import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../domain/models/project.dart';
import '../domain/models/text_layer.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('curvetype.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE text_layers ADD COLUMN styleMetadata TEXT');
      } catch (e) {
        // Ignore if column already exists
        print('Database upgrade warning: $e');
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute("ALTER TABLE projects ADD COLUMN userId TEXT NOT NULL DEFAULT 'local_user'");
      } catch (e) {
        print('Database upgrade warning (projects userId): $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          CREATE TABLE users (
            email TEXT PRIMARY KEY,
            password TEXT NOT NULL,
            name TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        print('Database upgraded to version 4: users table created.');
      } catch (e) {
        print('Database upgrade warning (users table): $e');
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // Create settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create Projects table
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        imagePath TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        imageSettings TEXT NOT NULL,
        userId TEXT NOT NULL DEFAULT 'local_user'
      )
    ''');

    // Create Text Layers table
    await db.execute('''
      CREATE TABLE text_layers (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        text TEXT NOT NULL,
        x REAL NOT NULL,
        y REAL NOT NULL,
        scale REAL NOT NULL,
        rotation REAL NOT NULL,
        curvature REAL NOT NULL,
        fontFamily TEXT NOT NULL,
        fontSize REAL NOT NULL,
        colorValue INTEGER NOT NULL,
        strokeColorValue INTEGER,
        strokeWidth REAL NOT NULL,
        letterSpacing REAL NOT NULL,
        opacity REAL NOT NULL,
        styleMetadata TEXT,
        FOREIGN KEY (projectId) REFERENCES projects (id) ON DELETE CASCADE
      )
    ''');

    // Create Users table
    await db.execute('''
      CREATE TABLE users (
        email TEXT PRIMARY KEY,
        password TEXT NOT NULL,
        name TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getSetting(String key) async {
    final db = await database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  Future<void> registerUser(String email, String password, String name) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();

    // Check if user already exists
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
    );

    if (existing.isNotEmpty) {
      throw Exception('An account with this email already exists.');
    }

    await db.insert('users', {
      'email': normalizedEmail,
      'password': password,
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>?> authenticateUser(String email, String password) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();

    final results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
    );

    if (results.isEmpty) {
      throw Exception('No account found with this email. Please sign up first.');
    }

    final userMap = results.first;
    if (userMap['password'] != password) {
      throw Exception('Incorrect password. Please try again.');
    }

    return userMap;
  }

  Future<void> saveProject(Project project) async {
    final db = await database;

    await db.transaction((txn) async {
      // 1. Insert or replace project record
      final projectMap = project.toMap();
      // Convert imageSettings map to JSON string for storage
      projectMap['imageSettings'] = jsonEncode(projectMap['imageSettings']);
      
      await txn.insert(
        'projects',
        projectMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Clear old text layers for this project
      await txn.delete(
        'text_layers',
        where: 'projectId = ?',
        whereArgs: [project.id],
      );

      // 3. Insert new text layers
      for (final layer in project.textLayers) {
        final layerMap = layer.toMap();
        layerMap['projectId'] = project.id;
        await txn.insert(
          'text_layers',
          layerMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<Project?> getProject(String id) async {
    final db = await database;

    final projectMaps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (projectMaps.isEmpty) return null;

    final projectMap = Map<String, dynamic>.from(projectMaps.first);
    // Parse imageSettings from JSON string back to Map
    projectMap['imageSettings'] = jsonDecode(projectMap['imageSettings'] as String);

    final layerMaps = await db.query(
      'text_layers',
      where: 'projectId = ?',
      whereArgs: [id],
    );

    final textLayers = layerMaps.map((m) => TextLayer.fromMap(m)).toList();

    return Project.fromMap(projectMap, textLayers);
  }

  Future<List<Project>> getAllProjects() async {
    final db = await database;

    final projectMaps = await db.query('projects', orderBy: 'updatedAt DESC');
    final List<Project> projects = [];

    for (final map in projectMaps) {
      final projectMap = Map<String, dynamic>.from(map);
      projectMap['imageSettings'] = jsonDecode(projectMap['imageSettings'] as String);

      final projectId = projectMap['id'] as String;
      final layerMaps = await db.query(
        'text_layers',
        where: 'projectId = ?',
        whereArgs: [projectId],
      );

      final textLayers = layerMaps.map((m) => TextLayer.fromMap(m)).toList();
      projects.add(Project.fromMap(projectMap, textLayers));
    }

    return projects;
  }

  Future<List<Project>> getProjectsForUser(String userId) async {
    final db = await database;

    final projectMaps = await db.query(
      'projects',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'updatedAt DESC',
    );
    final List<Project> projects = [];

    for (final map in projectMaps) {
      final projectMap = Map<String, dynamic>.from(map);
      projectMap['imageSettings'] = jsonDecode(projectMap['imageSettings'] as String);

      final projectId = projectMap['id'] as String;
      final layerMaps = await db.query(
        'text_layers',
        where: 'projectId = ?',
        whereArgs: [projectId],
      );

      final textLayers = layerMaps.map((m) => TextLayer.fromMap(m)).toList();
      projects.add(Project.fromMap(projectMap, textLayers));
    }

    return projects;
  }

  Future<void> deleteProject(String id) async {
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete(
        'text_layers',
        where: 'projectId = ?',
        whereArgs: [id],
      );
      await txn.delete(
        'projects',
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
