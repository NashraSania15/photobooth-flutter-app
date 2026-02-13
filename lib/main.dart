import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const PhotoBoothApp());
}

class PhotoBoothApp extends StatelessWidget {
  const PhotoBoothApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PhotoBooth',

      themeMode: ThemeMode.system,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.deepPurple,
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
      ),

      home: const WelcomeScreen(),
    );
  }
}
