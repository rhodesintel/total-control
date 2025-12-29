import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// Cold War theme colors
class AppColors {
  static const bg = Color(0xFF1a1a0f);
  static const panel = Color(0xFF2a2a1f);
  static const metal = Color(0xFF3d3d2d);
  static const amber = Color(0xFFffb000);
  static const amberDim = Color(0xFF8b6914);
  static const green = Color(0xFF00ff00);
  static const greenDim = Color(0xFF006600);
  static const red = Color(0xFFff3333);
  static const redDim = Color(0xFF661414);
  static const text = Color(0xFFd4c4a0);
  static const textDim = Color(0xFF6b6348);
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
