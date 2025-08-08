import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';

import '../models/pose_data.dart';
import '../models/pose_keypoint.dart';

class VideoPoseProcessor {
  final String videoPath;
  final Interpreter interpreter;

  VideoPoseProcessor({
    required this.videoPath,
    required this.interpreter,
  });

  Future<List<PoseData>> extractPosesFromVideo() async {
    final poses = <PoseData>[];

    final file = File(videoPath);
    if (!file.existsSync() || await file.length() == 0) {
      debugPrint('[VideoPoseProcessor] ❌ Video file is missing or empty: $videoPath');
      return poses;
    }

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    final durationMs = controller.value.duration.inMilliseconds;
    await controller.dispose();

    debugPrint('[VideoPoseProcessor] ✅ Video loaded: $videoPath');
    debugPrint('[VideoPoseProcessor] 🎞 Duration: $durationMs ms');

    if (durationMs == 0) {
      debugPrint('[VideoPoseProcessor] ❌ Video has 0 duration, skipping pose extraction.');
      return poses;
    }

    const int skipMs = 50;
    final int frameCount = (durationMs / skipMs).floor();

    for (int i = 0; i < frameCount; i++) {
      final int timestamp = i * skipMs;

      if (timestamp >= durationMs - 100) break;

      final Uint8List? frameData = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: timestamp,
        quality: 75,
      );

      if (frameData == null) {
        debugPrint('[VideoPoseProcessor] ❌ Failed to get frame at $timestamp ms');
        continue;
      }

      final img.Image? frameImage = img.decodeImage(frameData);
      if (frameImage == null) {
        debugPrint('[VideoPoseProcessor] ❌ Failed to decode frame image at $timestamp ms');
        continue;
      }

      final pose = await _predictPose(frameImage, timestamp);
      if (pose != null) {
        poses.add(pose);
      }
    }

    debugPrint('[VideoPoseProcessor] ✅ Extracted ${poses.length} valid pose frames.');
    return poses;
  }

  Future<PoseData?> _predictPose(img.Image image, int timestampMs) async {
    try {
      final inputShape = interpreter.getInputTensor(0).shape;
      final inputHeight = inputShape[1];
      final inputWidth = inputShape[2];

      final resized = img.copyResize(image, width: inputWidth, height: inputHeight);

      final inputBytes = Uint8List(inputHeight * inputWidth * 3);
      int byteIndex = 0;

      for (int y = 0; y < inputHeight; y++) {
        for (int x = 0; x < inputWidth; x++) {
          final pixel = resized.getPixel(x, y);
          inputBytes[byteIndex++] = img.getRed(pixel);
          inputBytes[byteIndex++] = img.getGreen(pixel);
          inputBytes[byteIndex++] = img.getBlue(pixel);
        }
      }

      final outputShape = interpreter.getOutputTensor(0).shape;
      final output = List.generate(
        outputShape[0],
        (_) => List.generate(
          outputShape[1],
          (_) => List.generate(
            outputShape[2],
            (_) => List.filled(outputShape[3], 0.0),
          ),
        ),
      );

      interpreter.run(inputBytes.buffer.asUint8List(), output);

      final joints = <JointName, PoseKeyPoint>{
        for (int i = 0; i < 17; i++)
          JointName.values[i]: PoseKeyPoint(
            name: JointName.values[i],
            x: output[0][0][i][0],
            y: output[0][0][i][1],
            z: output[0][0][i][2],
          ),
      };

      return PoseData(
        joints: joints,
        leftElbowAngle: _calculateAngle(
          joints[JointName.leftShoulder]!,
          joints[JointName.leftElbow]!,
          joints[JointName.leftWrist]!,
        ),
        rightElbowAngle: _calculateAngle(
          joints[JointName.rightShoulder]!,
          joints[JointName.rightElbow]!,
          joints[JointName.rightWrist]!,
        ),
        leftKneeAngle: _calculateAngle(
          joints[JointName.leftHip]!,
          joints[JointName.leftKnee]!,
          joints[JointName.leftAnkle]!,
        ),
        rightKneeAngle: _calculateAngle(
          joints[JointName.rightHip]!,
          joints[JointName.rightKnee]!,
          joints[JointName.rightAnkle]!,
        ),
        timestampMs: timestampMs,
      );
    } catch (e) {
      debugPrint('[VideoPoseProcessor] ⚠️ Pose prediction error: $e');
      return null;
    }
  }

  double _calculateAngle(PoseKeyPoint a, PoseKeyPoint b, PoseKeyPoint c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final cross = ab.dx * cb.dy - ab.dy * cb.dx;
    return atan2(cross, dot).abs() * (180 / pi);
  }
}
