import 'package:flutter/material.dart';

import '../models/pose_keypoint.dart';
import '../models/pose_data.dart';

class PoseOverlay extends StatelessWidget {
  final PoseData? poseData;
  final double width;
  final double height;

  const PoseOverlay({
    super.key,
    required this.poseData,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (poseData == null) return const SizedBox.shrink();

    return CustomPaint(
      size: Size(width, height),
      painter: _PosePainter(poseData!, width, height),
    );
  }
}

class _PosePainter extends CustomPainter {
  final PoseData poseData;
  final double width;
  final double height;

  _PosePainter(this.poseData, this.width, this.height);

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.65) return Colors.greenAccent;
    if (confidence >= 0.35) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final joints = poseData.joints;

    Offset? jointOffset(JointName name) {
      final kp = joints[name];
      if (kp == null) return null;
      // Coordinates are [0,1] normalized; scale to canvas dimensions.
      return Offset(kp.x * size.width, kp.y * size.height);
    }

    void drawBone(JointName a, JointName b) {
      final p1 = jointOffset(a);
      final p2 = jointOffset(b);
      if (p1 == null || p2 == null) return;

      final confA = joints[a]!.confidence;
      final confB = joints[b]!.confidence;
      final minConf = confA < confB ? confA : confB;

      final paint = Paint()
        ..color = _confidenceColor(minConf).withValues(alpha: 0.75)
        ..strokeWidth = 2.5;
      canvas.drawLine(p1, p2, paint);
    }

    const bones = [
      [JointName.leftShoulder, JointName.rightShoulder],
      [JointName.leftShoulder, JointName.leftElbow],
      [JointName.leftElbow, JointName.leftWrist],
      [JointName.rightShoulder, JointName.rightElbow],
      [JointName.rightElbow, JointName.rightWrist],
      [JointName.leftShoulder, JointName.leftHip],
      [JointName.rightShoulder, JointName.rightHip],
      [JointName.leftHip, JointName.rightHip],
      [JointName.leftHip, JointName.leftKnee],
      [JointName.leftKnee, JointName.leftAnkle],
      [JointName.rightHip, JointName.rightKnee],
      [JointName.rightKnee, JointName.rightAnkle],
    ];

    for (final bone in bones) {
      drawBone(bone[0], bone[1]);
    }

    for (final entry in joints.entries) {
      final kp = entry.value;
      if (kp.confidence < 0.15) continue;
      final pos = Offset(kp.x * size.width, kp.y * size.height);
      final paint = Paint()..color = _confidenceColor(kp.confidence);
      canvas.drawCircle(pos, kp.confidence >= 0.5 ? 5.0 : 3.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PosePainter old) =>
      old.poseData != poseData;
}
