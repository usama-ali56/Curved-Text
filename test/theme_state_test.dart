import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:curvetype/presentation/state/theme_state.dart';

void main() {
  test('themeModeProvider default value and toggle', () {
    final container = ProviderContainer();
    final notifier = container.read(themeModeProvider.notifier);

    // Default theme mode
    expect(container.read(themeModeProvider), ThemeMode.system);

    // Toggle theme to light
    notifier.toggleTheme();
    expect(container.read(themeModeProvider), ThemeMode.light);

    // Toggle theme to dark
    notifier.toggleTheme();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    // Toggle theme back to system
    notifier.toggleTheme();
    expect(container.read(themeModeProvider), ThemeMode.system);
  });
}
