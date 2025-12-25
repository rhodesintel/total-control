import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'theme/coldwar_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TotalControlApp());
}

class TotalControlApp extends StatelessWidget {
  const TotalControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Total Control',
      debugShowCheckedModeBanner: false,
      theme: ColdWarTheme.theme,
      home: const HomeScreen(),
    );
  }
}
