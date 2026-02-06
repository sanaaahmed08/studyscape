import 'package:flutter/material.dart';
import 'screens/welcome_screen.dart';

void main() {
  runApp(const StudyScapeApp());
}

class StudyScapeApp extends StatelessWidget {
  const StudyScapeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StudyScape',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF212B58)),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}
