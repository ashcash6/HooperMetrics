// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/';

  const HomeScreen({Key? key}) : super(key: key);

  void _startCamera(BuildContext context) {
    Navigator.pushNamed(context, CameraScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double screenHeight = size.height;

    // Make logo height ~38% of screen height
    final double logoHeight = screenHeight * 0.38;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo takes roughly the upper third + some padding
              Image.asset(
                'assets/logo.png',
                height: logoHeight,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 24),

              Text(
                'Analyze your shots\nlike a pro.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 48),

              ElevatedButton(
                onPressed: () => _startCamera(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Start Shooting',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
