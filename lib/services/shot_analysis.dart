// lib/shot_analysis.dart
import 'dart:math';
import 'package:basketball_app/models/pose_data.dart';

class ShotAnalysisResult {
  final double overallScore;
  final Map<String, double> detailedScores;
  final List<String> tips;

  ShotAnalysisResult({
    required this.overallScore,
    required this.detailedScores,
    required this.tips,
  });
}

class ShotAnalyzer {
  // Compute DTW distance between two sequences
  double dtwDistance(List<double> a, List<double> b) {
    int n = a.length;
    int m = b.length;
    List<List<double>> dtw = List.generate(
      n + 1,
      (_) => List.filled(m + 1, double.infinity),
    );
    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        double cost = (a[i - 1] - b[j - 1]).abs();
        dtw[i][j] = cost +
            min(dtw[i - 1][j], min(dtw[i][j - 1], dtw[i - 1][j - 1]));
      }
    }
    return dtw[n][m];
  }

  // Calculate consistency score from multiple sequences of one feature
  Map<String, double> featureConsistency(List<List<double>> arrays, double maxDist) {
    int n = arrays.length;
    if (n < 2) return {'score': 1.0, 'avgDist': 0.0};

    double totalScore = 0;
    double totalDist = 0;
    int totalPairs = 0;

    for (int i = 0; i < n; i++) {
      for (int j = i + 1; j < n; j++) {
        double dist = dtwDistance(arrays[i], arrays[j]);
        double score = max(0, 1 - dist / maxDist);
        totalScore += score;
        totalDist += dist;
        totalPairs++;
      }
    }

    double avgScore = totalPairs > 0 ? totalScore / totalPairs : 0;
    double avgDist = totalPairs > 0 ? totalDist / totalPairs : 0;
    return {'score': avgScore, 'avgDist': avgDist};
  }

  // Prepare angle arrays per shot
  List<Map<String, List<double>>> preprocessShots(List<List<PoseData>> rawShots) {
    List<Map<String, List<double>>> processed = [];

    for (var shot in rawShots) {
      List<double> leftElbowAngle = [];
      List<double> rightElbowAngle = [];
      List<double> leftKneeAngle = [];
      List<double> rightKneeAngle = [];

      for (var frame in shot) {
        leftElbowAngle.add(frame.leftElbowAngle);
        rightElbowAngle.add(frame.rightElbowAngle);
        leftKneeAngle.add(frame.leftKneeAngle);
        rightKneeAngle.add(frame.rightKneeAngle);
      }

      // Remove NaNs or invalid values
      List<double> clean(List<double> arr) => arr.where((x) => x.isFinite).toList();

      processed.add({
        'left_elbow_angle': clean(leftElbowAngle),
        'right_elbow_angle': clean(rightElbowAngle),
        'left_knee_angle': clean(leftKneeAngle),
        'right_knee_angle': clean(rightKneeAngle),
      });
    }

    return processed;
  }

  ShotAnalysisResult analyzeShots(List<List<PoseData>> rawShots) {
    final shots = preprocessShots(rawShots);

    final featureNames = [
      'left_elbow_angle',
      'right_elbow_angle',
      'left_knee_angle',
      'right_knee_angle',
    ];

    final maxDistances = {
      'left_elbow_angle': 600.0,
      'right_elbow_angle': 600.0,
      'left_knee_angle': 600.0,
      'right_knee_angle': 600.0,
    };

    Map<String, double> detailedScores = {};
    double overallSum = 0;

    for (var fname in featureNames) {
      List<List<double>> arrays = [];
      for (var shot in shots) {
        if (shot.containsKey(fname) && shot[fname]!.isNotEmpty) {
          arrays.add(shot[fname]!);
        }
      }

      if (arrays.length > 1) {
        final result = featureConsistency(arrays, maxDistances[fname]!);
        detailedScores[fname] = result['score']!;
      } else {
        detailedScores[fname] = 1.0; // If only one shot, score is perfect by default
      }

      overallSum += detailedScores[fname]!;
    }

    double overallScore = overallSum / featureNames.length;

    List<String> tips = [];

    if (detailedScores['left_elbow_angle']! < 0.7) {
      tips.add("Try keeping your left elbow angle steadier during your shot.");
    }
    if (detailedScores['right_elbow_angle']! < 0.7) {
      tips.add("Try keeping your right elbow angle steadier during your shot.");
    }
    if (detailedScores['left_knee_angle']! < 0.7) {
      tips.add("Try to keep your left knee angle consistent during shots.");
    }
    if (detailedScores['right_knee_angle']! < 0.7) {
      tips.add("Try to keep your right knee angle consistent during shots.");
    }

    if (tips.isEmpty) {
      tips.add("Great consistency! Keep up the good work!");
    }

    return ShotAnalysisResult(
      overallScore: overallScore,
      detailedScores: detailedScores,
      tips: tips,
    );
  }
}
