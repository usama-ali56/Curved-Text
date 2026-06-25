import 'dart:io';
import 'database_helper.dart';

class DatabaseSeeder {
  static Future<void> seedIfNecessary() async {
    final dbHelper = DatabaseHelper.instance;

    // One-time cleanup of existing seed projects from database
    final cleanedUp = await dbHelper.getSetting('cleaned_up_seeds_v1');
    if (cleanedUp != 'true') {
      try {
        final projects = await dbHelper.getAllProjects();
        final seedNames = {'Neo-Flow Brand', 'Arc Vector Set', 'Social Pack V2', 'Curve Thesis'};
        for (final project in projects) {
          if (seedNames.contains(project.name)) {
            // Delete project records
            await dbHelper.deleteProject(project.id);
            // Delete associated image file
            final file = File(project.imagePath);
            if (await file.exists()) {
              await file.delete();
            }
          }
        }
        await dbHelper.setSetting('cleaned_up_seeds_v1', 'true');
      } catch (e) {
        // ignore
      }
    }

    // Set seeded_samples to true to prevent future seeding on fresh installs
    await dbHelper.setSetting('seeded_samples', 'true');
  }
}
