import 'pose_keypoint.dart';

class PoseData {
  final Map<JointName, PoseKeyPoint> joints;
  final double leftElbowAngle;
  final double rightElbowAngle;
  final double leftKneeAngle;
  final double rightKneeAngle;
  final double leftShoulderAngle;
  final double rightShoulderAngle;
  final int timestampMs;

  PoseData({
    required this.joints,
    required this.leftElbowAngle,
    required this.rightElbowAngle,
    required this.leftKneeAngle,
    required this.rightKneeAngle,
    required this.leftShoulderAngle,
    required this.rightShoulderAngle,
    required this.timestampMs,
  });

  static const double _minConfidence = 0.25;

  /// True when at least one arm's core joints are sufficiently visible.
  /// Checked before handedness is known, so either arm qualifies — shoulder and
  /// elbow at full confidence, wrist at a lower threshold (ball often occludes it).
  bool get isShootingArmVisible {
    bool armVisible(JointName s, JointName e, JointName w) {
      final shoulder = joints[s];
      final elbow = joints[e];
      final wrist = joints[w];
      if (shoulder == null || shoulder.confidence < _minConfidence) return false;
      if (elbow == null || elbow.confidence < _minConfidence) return false;
      return wrist != null && wrist.confidence >= 0.15;
    }

    return armVisible(
          JointName.rightShoulder, JointName.rightElbow, JointName.rightWrist) ||
        armVisible(
          JointName.leftShoulder, JointName.leftElbow, JointName.leftWrist);
  }

  /// True when the left (guide) arm keypoints are sufficiently visible.
  bool get isGuideArmVisible {
    for (final name in [
      JointName.leftShoulder,
      JointName.leftElbow,
      JointName.leftWrist,
    ]) {
      final kp = joints[name];
      if (kp == null || kp.confidence < _minConfidence) return false;
    }
    return true;
  }

  /// Average confidence of the three shooting-arm joints.
  double get shootingArmConfidence {
    final confs = [
      joints[JointName.rightShoulder]?.confidence ?? 0.0,
      joints[JointName.rightElbow]?.confidence ?? 0.0,
      joints[JointName.rightWrist]?.confidence ?? 0.0,
    ];
    return confs.reduce((a, b) => a + b) / confs.length;
  }
}
