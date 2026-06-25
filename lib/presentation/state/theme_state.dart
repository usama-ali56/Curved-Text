import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database_helper.dart';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system; // Default to system
  }

  Future<void> _loadTheme() async {
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    try {
      final themeStr = await DatabaseHelper.instance.getSetting('theme_mode');
      if (themeStr == 'light') {
        state = ThemeMode.light;
      } else if (themeStr == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } catch (e) {
      // Ignore or log load failure
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    String val = 'system';
    if (mode == ThemeMode.light) {
      val = 'light';
    } else if (mode == ThemeMode.dark) {
      val = 'dark';
    }
    await DatabaseHelper.instance.setSetting('theme_mode', val);
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.system) {
      await setTheme(ThemeMode.light);
    } else if (state == ThemeMode.light) {
      await setTheme(ThemeMode.dark);
    } else {
      await setTheme(ThemeMode.system);
    }
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});
