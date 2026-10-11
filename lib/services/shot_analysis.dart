import 'dart:math';
import '../models/pose_data.dart';

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
  /// Dynamic Time Warping distance between two angle sequences.
  double _dtw(List<double> a, List<double> b) {
    final n = a.length;
    final m = b.length;
    final dtw = List.generate(n + 1, (_) => List.filled(m + 1, double.infinity));
    dtw[0][0] = 0;

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = (a[i - 1] - b[j - 1]).abs();
        dtw[i][j] = cost + min(dtw[i - 1][j], min(dtw[i][j - 1], dtw[i - 1][j - 1]));
      }
    }
    return dtw[n][m];
  }

  /// Average pairwise DTW consistency score for a set of angle sequences.
  /// Returns a value in [0, 1] where 1 is perfectly consistent.
  double _consistencyScore(List<List<double>> sequences, double maxDist) {
    if (sequences.length < 2) return 1.0;
    double total = 0;
    int pairs = 0;
    for (int i = 0; i < sequences.length; i++) {
      for (int j = i + 1; j < sequences.length; j++) {
        final dist = _dtw(sequences[i], sequences[j]);
        total += max(0.0, 1.0 - dist / maxDist);
        pairs++;
      }
    }
    return pairs > 0 ? total / pairs : 0;
  }

  /// Extracts per-shot angle arrays for each feature, discarding zero/invalid values.
  List<Map<String, List<double>>> _preprocessShots(List<List<PoseData>> rawShots) {
    return rawShots.map((shot) {
      clean(List<double> arr) => arr.where((x) => x.isFinite && x > 1.0).toList();
      return {
        'right_elbow_angle': clean(shot.map((f) => f.rightElbowAngle).toList()),
        'left_elbow_angle': clean(shot.map((f) => f.leftElbowAngle).toList()),
        'right_knee_angle': clean(shot.map((f) => f.rightKneeAngle).toList()),
        'left_knee_angle': clean(shot.map((f) => f.leftKneeAngle).toList()),
        'right_shoulder_angle': clean(shot.map((f) => f.rightShoulderAngle).toList()),
        'left_shoulder_angle': clean(shot.map((f) => f.leftShoulderAngle).toList()),
      };
    }).toList();
  }

  ShotAnalysisResult analyzeShots(List<List<PoseData>> rawShots) {
    if (rawShots.length < 2) {
      return ShotAnalysisResult(
        overallScore: -1.0,
        detailedScores: {},
        tips: [
          'Only 1 scored shot was detected. Record at least 3 shots total (1 calibration + 2 scored) to get your consistency score and mechanics breakdown.',
        ],
      );
    }

    final shots = _preprocessShots(rawShots);

    // Max DTW distances calibrated per feature range.
    const features = <String, double>{
      'right_elbow_angle': 600.0,
      'left_elbow_angle': 600.0,
      'right_knee_angle': 600.0,
      'left_knee_angle': 600.0,
      'right_shoulder_angle': 500.0,
      'left_shoulder_angle': 500.0,
    };

    final scores = <String, double>{};
    double scoreSum = 0;
    int scoredFeatures = 0;

    for (final entry in features.entries) {
      final key = entry.key;
      final maxDist = entry.value;

      final sequences = shots
          .map((s) => s[key] ?? <double>[])
          .where((arr) => arr.length >= 3)
          .toList();

      if (sequences.length >= 2) {
        scores[key] = _consistencyScore(sequences, maxDist);
        scoreSum += scores[key]!;
        scoredFeatures++;
      } else {
        // Not enough data to compare — mark as unavailable, not perfect.
        scores[key] = -1.0;
      }
    }

    final overallScore = scoredFeatures > 0 ? scoreSum / scoredFeatures : 0.0;

    final tips = <String>[];

    void check(String key, String tip) {
      final s = scores[key];
      if (s != null && s >= 0 && s < 0.70) tips.add(tip);
    }

    check(
      'right_elbow_angle',
      'right_elbow: Your shooting elbow extension is inconsistent — focus on a full, repeatable snap on every shot.',
    );
    check(
      'left_elbow_angle',
      'left_elbow: Your guide arm position varies. Lock your off-arm in place as a consistent directional guide.',
    );
    check(
      'right_knee_angle',
      'right_knee: Your shooting-side knee bend varies between shots. Load your legs to the same depth each time for consistent power transfer.',
    );
    check(
      'left_knee_angle',
      'left_knee: Your non-dominant leg is inconsistent. Keep your base symmetric and balanced on every rep.',
    );
    check(
      'right_shoulder_angle',
      'right_shoulder: Your shooting shoulder angle is inconsistent. Keep your elbow directly in front of your shoulder — not flared out.',
    );
    check(
      'left_shoulder_angle',
      'left_shoulder: Your off-arm shoulder position varies. Maintain a steady guide arm that doesn\'t drift between shots.',
    );

    if (tips.isEmpty) {
      tips.add('great: Strong fundamentals. Stay locked in and keep that consistency.');
    }

    return ShotAnalysisResult(
      overallScore: overallScore,
      detailedScores: Map.fromEntries(
        scores.entries.where((e) => e.value >= 0),
      ),
      tips: tips,
    );
  }
}
