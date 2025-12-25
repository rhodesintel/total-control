import 'package:flutter/material.dart';

/// Cold War Nuclear Control Aesthetic
class ColdWarTheme {
  // Backgrounds - bunker concrete/metal
  static const Color bg = Color(0xFF1A1914);
  static const Color bgPanel = Color(0xFF252420);
  static const Color bgInset = Color(0xFF0F0E0C);

  // Industrial metals
  static const Color metal = Color(0xFF3D3A32);
  static const Color metalLight = Color(0xFF4A463C);
  static const Color rivet = Color(0xFF2A2824);

  // Warning colors - authentic CRT phosphor
  static const Color amber = Color(0xFFFFB000);
  static const Color amberDim = Color(0xFF996600);
  static const Color danger = Color(0xFFFF2200);
  static const Color dangerDim = Color(0xFF881100);
  static const Color ok = Color(0xFF33FF33);
  static const Color okDim = Color(0xFF117711);

  // Text
  static const Color text = Color(0xFFCCBB99);
  static const Color textDim = Color(0xFF776655);
  static const Color textStencil = Color(0xFFDDCC88);

  // Hazard
  static const Color hazardYellow = Color(0xFFFFCC00);
  static const Color hazardBlack = Color(0xFF1A1A1A);

  static ThemeData get theme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        primaryColor: amber,
        colorScheme: const ColorScheme.dark(
          primary: amber,
          secondary: ok,
          surface: bgPanel,
          error: danger,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: metal,
          foregroundColor: amber,
          elevation: 4,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: amber,
            letterSpacing: 2,
          ),
        ),
        cardTheme: CardTheme(
          color: bgPanel,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: metal, width: 2),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: amber,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textStencil,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 14,
            color: text,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 12,
            color: textDim,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Courier New',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textStencil,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: metal,
            foregroundColor: amber,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return ok;
            return dangerDim;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return okDim;
            return metal;
          }),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: amber,
          linearTrackColor: metal,
        ),
      );
}
