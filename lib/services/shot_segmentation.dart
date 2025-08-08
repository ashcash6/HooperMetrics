import 'dart:math';
import '../models/pose_data.dart';
import '../models/pose_keypoint.dart';

class ShotSegmentation {
  /// Returns absolute difference between two angles in degrees.
  static double angleDifference(double a, double b) => (a - b).abs();

  /// Checks if the arm is in 'loaded' position based on right elbow angle (~90°).
  static bool isArmLoaded(PoseData frame) {
    final elbowAngle = frame.rightElbowAngle;
    return elbowAngle >= 80 && elbowAngle <= 110;
  }

  /// Checks if the arm is extended (right elbow angle >= 150°).
  static bool isArmExtended(PoseData frame) {
    final elbowAngle = frame.rightElbowAngle;
    return elbowAngle >= 150;
  }

  /// Returns true if wrist is above shoulder (y smaller means higher in image coordinates).
  static bool isShoulderLifted(PoseData frame) {
    final shoulder = frame.joints[JointName.rightShoulder]!;
    final wrist = frame.joints[JointName.rightWrist]!;
    return wrist.y < shoulder.y;
  }

  /// Checks if the right elbow angle is stable within a threshold over a window of frames.
  static bool isArmStable(List<PoseData> frames, int start, int window, double angleThreshold) {
    final angles = frames
        .sublist(start, start + window)
        .map((f) => f.rightElbowAngle)
        .toList();
    final mean = angles.reduce((a, b) => a + b) / angles.length;
    return angles.every((a) => angleDifference(a, mean) < angleThreshold);
  }

  /// Validates shot start by checking elbow angle stability around ~90° over a window.
  static bool isValidShotStart(List<PoseData> frames, int start, int window) {
    if (start + window > frames.length) return false;
    final angles = frames.sublist(start, start + window).map((f) => f.rightElbowAngle).toList();
    final meanAngle = angles.reduce((a, b) => a + b) / angles.length;
    return meanAngle >= 80 && meanAngle <= 110;
  }

  /// Validates shot end: elbow angle ~150+, wrist above shoulder, angles stable.
  static bool isValidShotEnd(List<PoseData> frames, int start, int window) {
    if (start + window > frames.length) return false;
    final angles = frames.sublist(start, start + window).map((f) => f.rightElbowAngle).toList();
    final meanAngle = angles.reduce((a, b) => a + b) / angles.length;
    final wristAboveShoulder = frames.sublist(start, start + window).every(
        (f) => f.joints[JointName.rightWrist]!.y < f.joints[JointName.rightShoulder]!.y);
    final stable = angles.every((a) => angleDifference(a, meanAngle) < 5.0);
    return meanAngle >= 150 && wristAboveShoulder && stable;
  }

  /// Detects shots based on pose data frames using angle thresholds and timing.
  static List<List<PoseData>> detectShots(
    List<PoseData> frames, {
    int minShotDurationMs = 500,
    int cooldownDurationMs = 400,
    int holdFrames = 5,
    double angleStabilityThreshold = 5.0,
    int startEndValidationWindow = 5,
  }) {
    final List<List<PoseData>> shots = [];
    bool inShot = false;
    int? shotStartIndex;
    int cooldownEndTime = 0;

    int i = 0;
    while (i < frames.length) {
      final frame = frames[i];

      // Skip frames during cooldown period
      if (frame.timestampMs < cooldownEndTime) {
        i++;
        continue;
      }

      if (!inShot) {
        if (isArmLoaded(frame)) {
          if (isValidShotStart(frames, i, startEndValidationWindow)) {
            shotStartIndex = i;
            inShot = true;
          }
        }
      } else {
        if (i + holdFrames >= frames.length) break;

        if (isValidShotEnd(frames, i, holdFrames)) {
          final end = i + holdFrames - 1;
          final shotDuration = frames[end].timestampMs - frames[shotStartIndex!].timestampMs;

          if (shotDuration >= minShotDurationMs) {
            shots.add(frames.sublist(shotStartIndex, end + 1));
            cooldownEndTime = frames[end].timestampMs + cooldownDurationMs;
          }

          inShot = false;
          i = end + 1;
          continue;
        }
      }

      i++;
    }

    // Remove first shot if likely junk (initial false positive)
    if (shots.isNotEmpty) {
      shots.removeAt(0);
    }

    return shots;
  }
}
