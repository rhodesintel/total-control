import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// High contrast light theme
class AppColors {
  static const bg = Color(0xFF0d0d08);
  static const panel = Color(0xFF1a1a12);
  static const metal = Color(0xFF2a2a1c);
  static const amber = Color(0xFFffcc00);       // Brighter amber
  static const amberDim = Color(0xFFcc9900);    // Still visible
  static const green = Color(0xFF44ff44);       // Brighter green
  static const greenDim = Color(0xFF22aa22);    // Still visible
  static const red = Color(0xFFff5555);         // Brighter red
  static const redDim = Color(0xFFcc3333);      // Still visible
  static const text = Color(0xFFf0e8d0);        // Much brighter text
  static const textDim = Color(0xFFb0a080);     // Brighter dim text
}

void main() {
  runApp(const TotalControlApp());
}

class TotalControlApp extends StatelessWidget {
  const TotalControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Total Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bg,
        fontFamily: 'Courier',
        colorScheme: ColorScheme.dark(
          primary: AppColors.amber,
          secondary: AppColors.green,
          surface: AppColors.panel,
          error: AppColors.red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.metal,
          foregroundColor: AppColors.amber,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amber,
            foregroundColor: AppColors.bg,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
