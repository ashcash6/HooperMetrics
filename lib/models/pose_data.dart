import 'pose_keypoint.dart';

class PoseData {
  final Map<JointName, PoseKeyPoint> joints;  // Change key type to JointName
  final double leftElbowAngle;
  final double rightElbowAngle;
  final double leftKneeAngle;
  final double rightKneeAngle;
  final int timestampMs;  // Add timestamp in milliseconds since epoch

  PoseData({
    required this.joints,
    required this.leftElbowAngle,
    required this.rightElbowAngle,
    required this.leftKneeAngle,
    required this.rightKneeAngle,
    required this.timestampMs,
  });
}
