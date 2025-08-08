// pose_processor.dart

import 'dart:math';
import 'models/pose_keypoints.dart';

/// Calculates the velocity (Euclidean distance per frame) between two keypoints
double calculateVelocity(Keypoint a, Keypoint b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  return sqrt(dx * dx + dy * dy);
}

/// Calculates angle at joint `mid` between `start` and `end`
/// Returns angle in degrees
double calculateAngle(Keypoint start, Keypoint mid, Keypoint end) {
  final a = atan2(start.y - mid.y, start.x - mid.x);
  final b = atan2(end.y - mid.y, end.x - mid.x);
  double angle = (b - a).abs() * (180 / pi);

  if (angle > 180) {
    angle = 360 - angle;
  }

  return angle;
}

/// Calculates key joint angles from pose keypoints
/// Returns a map of joint name -> angle
Map<String, double> extractAngles(PoseKeypoints pose) {
  return {
    'rightElbow': calculateAngle(
        pose.rightShoulder, pose.rightElbow, pose.rightWrist),
    'leftElbow': calculateAngle(
        pose.leftShoulder, pose.leftElbow, pose.leftWrist),
    'rightKnee': calculateAngle(
        pose.rightHip, pose.rightKnee, pose.rightAnkle),
    'leftKnee': calculateAngle(
        pose.leftHip, pose.leftKnee, pose.leftAnkle),
    'rightShoulder': calculateAngle(
        pose.rightElbow, pose.rightShoulder, pose.rightHip),
    'leftShoulder': calculateAngle(
        pose.leftElbow, pose.leftShoulder, pose.leftHip),
  };
}

/// Smooths a list of angles using a simple moving average
List<double> smoothAngles(List<double> input, {int windowSize = 3}) {
  final smoothed = <double>[];

  for (int i = 0; i < input.length; i++) {
    int start = max(0, i - windowSize + 1);
    int end = i + 1;
    final window = input.sublist(start, end);
    smoothed.add(window.reduce((a, b) => a + b) / window.length);
  }

  return smoothed;
}

/// Filters out pose frames where confidence of key joints is too low
bool isPoseFrameValid(PoseKeypoints pose, {double threshold = 0.3}) {
  final joints = [
    pose.leftWrist,
    pose.rightWrist,
    pose.leftElbow,
    pose.rightElbow,
    pose.leftShoulder,
    pose.rightShoulder
  ];

  return joints.every((kp) => kp.confidence >= threshold);
}
