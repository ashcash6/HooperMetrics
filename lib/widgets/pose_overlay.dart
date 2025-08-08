import 'package:flutter/material.dart';
import '../models/pose_keypoint.dart';
import '../models/pose_data.dart';

class PoseOverlay extends StatelessWidget {
   final PoseData? poseData;
   final double width;
   final double height;

   const PoseOverlay({
     Key? key,
     required this.poseData,
     required this.width,
     required this.height,
   }) : super(key: key);

   @override
   Widget build(BuildContext context) {
     if (poseData == null) return const SizedBox.shrink();

     return Transform(
       alignment: Alignment.center,
       transform: Matrix4.identity()
         ..rotateZ(-pi / 2)      // Rotate 90° CCW to match portrait
         ..scale(-1.0, 1.0),     // Flip horizontally
       child: CustomPaint(
         size: Size(height, width), // Swap width/height because of rotation
         painter: _PosePainter(poseData!, height, width),
       ),
     );
   }
 }


class _PosePainter extends CustomPainter {
  final PoseData poseData;
  final double width;
  final double height;

  _PosePainter(this.poseData, this.width, this.height);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 3;

    final joints = poseData.joints;

    Offset? joint(JointName name) {
      if (!joints.containsKey(name)) return null;
      final kp = joints[name]!;
      return Offset(kp.x * width, kp.y * height);
    }

    void drawLine(JointName a, JointName b) {
      final p1 = joint(a);
      final p2 = joint(b);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }

    final connections = [
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

    for (final pair in connections) {
      drawLine(pair[0], pair[1]);
    }

    for (final kp in joints.values) {
      canvas.drawCircle(Offset(kp.x * width, kp.y * height), 4, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
