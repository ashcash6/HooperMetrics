import 'package:flutter/foundation.dart';
import '../models/pose_data.dart';
import '../models/pose_keypoint.dart';

class ShotSegmentation {
  static double _angleDiff(double a, double b) => (a - b).abs();

  /// Scans all frames to determine the dominant shooting hand.
  static bool detectShootingHand(List<PoseData> frames) {
    double bestRightClearance = 0;
    double bestLeftClearance = 0;
    const double minConf = 0.35;

    for (final frame in frames) {
      final rw = frame.joints[JointName.rightWrist];
      final rs = frame.joints[JointName.rightShoulder];
      final lw = frame.joints[JointName.leftWrist];
      final ls = frame.joints[JointName.leftShoulder];

      if (rw != null && rs != null &&
          rw.confidence > minConf && rs.confidence > minConf) {
        final clearance = rs.y - rw.y;
        if (clearance > bestRightClearance) bestRightClearance = clearance;
      }
      if (lw != null && ls != null &&
          lw.confidence > minConf && ls.confidence > minConf) {
        final clearance = ls.y - lw.y;
        if (clearance > bestLeftClearance) bestLeftClearance = clearance;
      }
    }

    return bestRightClearance >= bestLeftClearance;
  }

  static bool _isArmLoaded(PoseData frame, bool rightHanded) {
    final angle = rightHanded ? frame.rightElbowAngle : frame.leftElbowAngle;
    return angle > 0 && angle >= 70 && angle <= 125;
  }

  static bool _isWristAboveShoulder(PoseData frame, bool rightHanded) {
    final shoulderName =
        rightHanded ? JointName.rightShoulder : JointName.leftShoulder;
    final wristName =
        rightHanded ? JointName.rightWrist : JointName.leftWrist;
    final shoulder = frame.joints[shoulderName];
    final wrist = frame.joints[wristName];
    if (shoulder == null || wrist == null) return false;
    return wrist.y < shoulder.y;
  }

  static bool _isValidShotStart(
    List<PoseData> frames, int start, int window, bool rightHanded,
  ) {
    if (start + window > frames.length) return false;
    final angles = frames
        .sublist(start, start + window)
        .map((f) => rightHanded ? f.rightElbowAngle : f.leftElbowAngle)
        .where((a) => a > 0)
        .toList();
    if (angles.length < (window / 2).ceil()) return false;
    final mean = angles.reduce((a, b) => a + b) / angles.length;
    return mean >= 70 && mean <= 125;
  }

  static bool _isValidShotEnd(
    List<PoseData> frames, int start, int window, bool rightHanded,
  ) {
    if (start + window > frames.length) return false;
    final slice = frames.sublist(start, start + window);
    final angles = slice
        .map((f) => rightHanded ? f.rightElbowAngle : f.leftElbowAngle)
        .where((a) => a > 0)
        .toList();
    if (angles.length < (window / 2).ceil()) return false;
    final mean = angles.reduce((a, b) => a + b) / angles.length;
    final wristAbove = slice.any((f) => _isWristAboveShoulder(f, rightHanded));
    final stableCount = angles.where((a) => _angleDiff(a, mean) < 15.0).length;
    final stable = stableCount >= (angles.length * 0.75).ceil();
    return mean >= 130 && wristAbove && stable;
  }

  /// Returns true if the person was not moving significantly in the frames
  /// leading up to [start]. Walking causes large hip x-displacement in
  /// normalized [0,1] coordinates; standing planted to shoot stays still.
  static bool _isBodyPlanted(List<PoseData> frames, int start, int window) {
    if (start < 2) return true;
    final lookback = (start - window).clamp(0, frames.length - 1);
    final xs = <double>[];
    for (int i = lookback; i < start; i++) {
      final lh = frames[i].joints[JointName.leftHip];
      final rh = frames[i].joints[JointName.rightHip];
      if (lh != null && rh != null &&
          lh.confidence > 0.3 && rh.confidence > 0.3) {
        xs.add((lh.x + rh.x) / 2.0);
      }
    }
    if (xs.length < 2) return true; // not enough data, allow it
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final minX = xs.reduce((a, b) => a < b ? a : b);
    // 5% of normalized frame width comfortably separates walking from standing.
    return (maxX - minX) < 0.05;
  }

  static List<List<PoseData>> detectShots(
    List<PoseData> frames, {
    int minShotDurationMs = 400,
    int cooldownDurationMs = 500,
    int holdFrames = 4,
    int validationWindow = 4,
  }) {
    final validFrames = frames.where((f) => f.isShootingArmVisible).toList();
    if (validFrames.length < holdFrames * 3) return [];

    final rightHanded = detectShootingHand(validFrames);
    debugPrint('[ShotSegmentation] ${rightHanded ? "right" : "left"}-handed shooter.');

    final shots = <List<PoseData>>[];
    bool inShot = false;
    int? shotStartIndex;
    int cooldownEndMs = 0;

    int i = 0;
    while (i < validFrames.length) {
      final frame = validFrames[i];

      if (frame.timestampMs < cooldownEndMs) {
        i++;
        continue;
      }

      if (!inShot) {
        if (_isArmLoaded(frame, rightHanded) &&
            _isValidShotStart(validFrames, i, validationWindow, rightHanded) &&
            _isBodyPlanted(validFrames, i, validationWindow)) {
          shotStartIndex = i;
          inShot = true;
        }
      } else {
        if (i + holdFrames >= validFrames.length) break;

        if (_isValidShotEnd(validFrames, i, holdFrames, rightHanded)) {
          final end = i + holdFrames - 1;
          final duration = validFrames[end].timestampMs -
              validFrames[shotStartIndex!].timestampMs;

          if (duration >= minShotDurationMs) {
            shots.add(validFrames.sublist(shotStartIndex, end + 1));
            cooldownEndMs = validFrames[end].timestampMs + cooldownDurationMs;
          }

          inShot = false;
          i = end + 1;
          continue;
        }

        final angle = rightHanded ? frame.rightElbowAngle : frame.leftElbowAngle;
        if (angle > 0 && angle < 50) inShot = false;
      }

      i++;
    }

    debugPrint('[ShotSegmentation] Detected ${shots.length} shot(s).');
    return shots;
  }
}
