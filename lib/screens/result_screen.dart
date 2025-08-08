import 'package:flutter/material.dart';
import '../models/pose_data.dart';
import 'shot_review_screen.dart';

class ResultScreen extends StatelessWidget {
  final double overallScore;
  final Map<String, double> detailedScores;
  final List<String> tips;
  final List<List<PoseData>> shots;
  final List<String> shotVideoPaths; // NEW
  final String? videoPath;

  static const String routeName = '/result';

  const ResultScreen({
    Key? key,
    required this.overallScore,
    required this.detailedScores,
    required this.tips,
    required this.shots,
    required this.shotVideoPaths,
    this.videoPath,
  }) : super(key: key);

  Color _getColorForScore(double percent) {
    if (percent < 50) return Colors.red;
    if (percent < 76) return Colors.yellow.shade700;
    if (percent < 90) return Colors.orange;
    return Colors.green;
  }

  String _translateMetric(String key) {
    switch (key) {
      case 'left_elbow_angle':
        return 'Left Elbow Extension';
      case 'right_elbow_angle':
        return 'Right Elbow Extension';
      case 'left_knee_angle':
        return 'Left Knee Bending';
      case 'right_knee_angle':
        return 'Right Knee Bending';
      default:
        return key;
    }
  }

  String _translateTip(String rawTip) {
    final tip = rawTip.toLowerCase();
    if (tip.contains('left elbow')) {
      return 'Your left elbow extension is inconsistent. Focus on a full, repeatable follow-through.';
    } else if (tip.contains('right elbow')) {
      return 'Your right elbow needs a smoother extension. Snap straight on every shot.';
    } else if (tip.contains('left knee')) {
      return 'Your left leg’s bend varies. Try to load and extend with the same motion each time.';
    } else if (tip.contains('right knee')) {
      return 'You’re bending your right knee inconsistently. Focus on keeping your base consistent.';
    } else if (tip.contains('good') || tip.contains('great')) {
      return 'Strong fundamentals here. Stay locked in and keep that consistency.';
    } else {
      return 'Your mechanics look steady overall. Keep refining for even more consistency.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowedMetrics = {
      'left_elbow_angle',
      'right_elbow_angle',
      'left_knee_angle',
      'right_knee_angle',
    };

    final filteredScores = detailedScores.entries
        .where((entry) => allowedMetrics.contains(entry.key))
        .toList();

    final overallPercent = (overallScore * 100).clamp(0, 100).toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Shot Breakdown'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Shot Consistency Score',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${overallPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: _getColorForScore(overallPercent),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Measures the repeatability of your shooting form.',
                style: TextStyle(fontSize: 14, color: Colors.white60),
              ),
              const Divider(height: 32, thickness: 1, color: Colors.white24),

              const Text(
                'Consistency by Shooting Mechanics',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...filteredScores.map((entry) {
                final percent = (entry.value * 100).clamp(0, 100).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '${_translateMetric(entry.key)}: ${percent.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 16, color: _getColorForScore(percent)),
                  ),
                );
              }),
              const Divider(height: 32, thickness: 1, color: Colors.white24),

              const Text(
                'Coach’s Feedback',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              ...tips.map(
                (tip) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ",
                          style: TextStyle(fontSize: 18, color: Colors.orangeAccent)),
                      Expanded(
                        child: Text(
                          _translateTip(tip),
                          style:
                              const TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShotReviewScreen(
                          shots: shots,
                          shotVideoPaths: shotVideoPaths, // PASS HERE
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor: Colors.orange.shade700,
                  ),
                  child: const Text(
                    'Watch Your Shots',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
