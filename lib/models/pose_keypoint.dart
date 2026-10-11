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
  final double confidence;

  const PoseKeyPoint({
    required this.name,
    required this.x,
    required this.y,
    required this.confidence,
  });

  PoseKeyPoint operator -(PoseKeyPoint other) {
    return PoseKeyPoint(
      name: name,
      x: x - other.x,
      y: y - other.y,
      confidence: (confidence + other.confidence) / 2,
    );
  }
}
