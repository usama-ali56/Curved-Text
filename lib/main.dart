// CurveType: Premium Kinetic Typography Studio in Flutter.
// This line was added on the feature/git-lesson branch.
//asasassaasasas
//kpskxojcksjcjskcjskjckscsj
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data/database_seeder.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/state/theme_state.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized
  // This is my Change
  WidgetsFlutterBinding.ensureInitialized();
  
  // Seed default sample projects if first launch
  await DatabaseSeeder.seedIfNecessary();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'CurveType',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      
      // CurveType Custom Visual Accent Configuration
      // Light Mode Theme
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFDFCFB),
        primaryColor: const Color(0xFFE2D1C3),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFFE2D1C3),
          secondary: Color(0xFFFFEAD9),
          surface: Color(0xFFFFEAD9),
          background: Color(0xFFFDFCFB),
          outline: Color(0xFFE2D1C3),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: const Color(0xFF3A3530),
          displayColor: const Color(0xFF3A3530),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFDFCFB),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF3A3530)),
          titleTextStyle: GoogleFonts.outfit(
            color: const Color(0xFF3A3530),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        sliderTheme: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: const Color(0xFFE2D1C3),
          inactiveTrackColor: const Color(0xFFFFEAD9),
          thumbColor: const Color(0xFFE2D1C3),
          overlayColor: const Color(0xFFE2D1C3).withOpacity(0.15),
          valueIndicatorColor: const Color(0xFF3A3530),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, pressedElevation: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE2D1C3),
            foregroundColor: const Color(0xFF3A3530),
            elevation: 1,
            shadowColor: const Color(0xFFE2D1C3).withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3A3530),
            side: const BorderSide(color: Color(0xFF3A3530), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),

      // Dark Mode Theme (Premium Warm Cocoa Palette)
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1A1816),
        primaryColor: const Color(0xFFE2D1C3),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE2D1C3),
          secondary: Color(0xFF2C2621),
          surface: Color(0xFF2C2621),
          background: Color(0xFF1A1816),
          outline: Color(0xFFE2D1C3),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: const Color(0xFFF4EFEA),
          displayColor: const Color(0xFFF4EFEA),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF1A1816),
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFFF4EFEA)),
          titleTextStyle: GoogleFonts.outfit(
            color: const Color(0xFFF4EFEA),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        sliderTheme: SliderThemeData(
          trackHeight: 4,
          activeTrackColor: const Color(0xFFE2D1C3),
          inactiveTrackColor: const Color(0xFF2C2621),
          thumbColor: const Color(0xFFE2D1C3),
          overlayColor: const Color(0xFFE2D1C3).withOpacity(0.15),
          valueIndicatorColor: const Color(0xFF2C2621),
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, pressedElevation: 6),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE2D1C3),
            foregroundColor: const Color(0xFF3A3530),
            elevation: 1,
            shadowColor: const Color(0xFFE2D1C3).withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFF4EFEA),
            side: const BorderSide(color: Color(0xFFF4EFEA), width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textStyle: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      
      home: const SplashScreen(),
    );
  }
}
