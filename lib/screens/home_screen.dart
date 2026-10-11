import 'package:flutter/material.dart';

import 'setup_guide_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  static const String routeName = '/';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Logo
              Center(
                child: Image.asset('assets/logo.png', height: 130, fit: BoxFit.contain),
              ),

              const SizedBox(height: 22),

              // Wordmark + tagline
              const Column(
                children: [
                  Text(
                    'HooperMetrics',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Track. Analyze. Improve.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 15,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // Primary CTA
              SizedBox(
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, SetupGuideScreen.routeName),
                  icon: const Icon(Icons.fiber_manual_record_rounded, size: 16),
                  label: const Text(
                    'New Session',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary CTA
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, HistoryScreen.routeName),
                  icon: const Icon(Icons.history_rounded, size: 20),
                  label: const Text(
                    'My Sessions',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF333333), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 44),
            ],
          ),
        ),
      ),
    );
  }
}
