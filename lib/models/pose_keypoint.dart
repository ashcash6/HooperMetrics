// lib/models/pose_keypoint.dart

enum JointName {
  nose,
  leftEye,
  rightEye,
  leftEar,
  rightEar,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

class PoseKeyPoint {
  final JointName name;
  final double x;
  final double y;
  final double z;

  PoseKeyPoint({
    required this.name,
    required this.x,
    required this.y,
    required this.z,
  });

  PoseKeyPoint operator -(PoseKeyPoint other) {
    return PoseKeyPoint(
      name: name,
      x: x - other.x,
      y: y - other.y,
      z: z - other.z,
    );
  }
}
