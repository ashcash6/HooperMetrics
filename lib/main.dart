import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/setup_guide_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HooperMetricsApp());
}

class HooperMetricsApp extends StatelessWidget {
  const HooperMetricsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HooperMetrics',
      debugShowCheckedModeBanner: false,
      color: const Color(0xFF0F0F0F),
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF6B00),
          secondary: Color(0xFFFF6B00),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        SetupGuideScreen.routeName: (_) => const SetupGuideScreen(),
        CameraScreen.routeName: (_) => const CameraScreen(),
        HistoryScreen.routeName: (_) => const HistoryScreen(),
      },
      initialRoute: HomeScreen.routeName,
    );
  }
}
