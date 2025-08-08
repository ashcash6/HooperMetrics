import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
// import 'screens/result_screen.dart';  // You can still import it for type safety, no problem

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test loading the TFLite model asset
  try {
    final interpreter = await Interpreter.fromAsset('assets/models/4.tflite');
    print('TFLite model loaded successfully.');
    interpreter.close();
  } catch (e) {
    print('Failed to load TFLite model: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Basketball Shot Analyzer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        CameraScreen.routeName: (context) => const CameraScreen(),
        // Removed ResultScreen route here because it requires parameters
      },
    );
  }
}
