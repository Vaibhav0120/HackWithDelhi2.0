import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ToolFinderApp());
}

class ToolFinderApp extends StatelessWidget {
  const ToolFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToolFinder AI',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF4A9EFF),
          secondary: Color(0xFF64FFDA),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
