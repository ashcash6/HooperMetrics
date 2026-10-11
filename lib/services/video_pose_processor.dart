import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/pose_data.dart';
import '../models/pose_keypoint.dart';

class VideoPoseProcessor {
  final String videoPath;

  // Match PoseData's own threshold so frames that pass isShootingArmVisible
  // also produce non-zero angles (was 0.4, causing all angles → 0 → 0% scores).
  static const double _minConfidence = 0.25;
  static const double _smoothingAlpha = 0.4;
  // 100ms = ~10fps, sufficient for shot form analysis and 2× faster than 50ms.
  static const int _sampleIntervalMs = 100;

  VideoPoseProcessor({required this.videoPath});

  Future<List<PoseData>> extractPosesFromVideo({
    void Function(int current, int total)? onProgress,
  }) async {
    final poses = <PoseData>[];

    final file = File(videoPath);
    if (!file.existsSync() || await file.length() == 0) {
      debugPrint('[VideoPoseProcessor] Video file missing or empty.');
      return poses;
    }

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    final durationMs = controller.value.duration.inMilliseconds;
    // Capture video dimensions to normalize ML Kit pixel coords → [0, 1].
    final videoSize = controller.value.size;
    await controller.dispose();

    if (durationMs == 0 || videoSize.isEmpty) {
      debugPrint('[VideoPoseProcessor] Video has 0 duration or unknown size.');
      return poses;
    }

    // Use base model — it's 3–4× faster than accurate with acceptable accuracy
    // for joint angle extraction.
    final poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.single,
        model: PoseDetectionModel.base,
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final frameCount = (durationMs / _sampleIntervalMs).floor();
    Map<JointName, PoseKeyPoint>? prevJoints;

    debugPrint('[VideoPoseProcessor] ${durationMs}ms → $frameCount frames @ ${_sampleIntervalMs}ms');

    for (int i = 0; i < frameCount; i++) {
      onProgress?.call(i + 1, frameCount);

      final timestamp = i * _sampleIntervalMs;
      if (timestamp >= durationMs - 100) break;

      final framePath = '${tempDir.path}/hm_frame_$i.jpg';
      String? savedPath;
      try {
        savedPath = await VideoThumbnail.thumbnailFile(
          video: videoPath,
          thumbnailPath: framePath,
          imageFormat: ImageFormat.JPEG,
          timeMs: timestamp,
          quality: 80,
        );
      } catch (e) {
        debugPrint('[VideoPoseProcessor] Thumbnail error at ${timestamp}ms: $e');
        continue;
      }

      if (savedPath == null) continue;

      try {
        final inputImage = InputImage.fromFilePath(savedPath);
        final mlPoses = await poseDetector.processImage(inputImage);

        if (mlPoses.isNotEmpty) {
          // Normalize pixel coords → [0, 1] so the PoseOverlay widget works
          // directly and so coords are scale-independent across devices.
          final rawJoints = _convertMLKitPose(mlPoses.first, videoSize);
          final smoothed = _smoothJoints(rawJoints, prevJoints);
          prevJoints = smoothed;

          final pose = _buildPoseData(smoothed, timestamp);
          if (pose.isShootingArmVisible) {
            poses.add(pose);
          }
        }
      } catch (e) {
        debugPrint('[VideoPoseProcessor] ML Kit error at frame $i: $e');
      } finally {
        try { File(savedPath).deleteSync(); } catch (_) {}
      }
    }

    await poseDetector.close();
    debugPrint('[VideoPoseProcessor] Extracted ${poses.length} valid frames.');
    return poses;
  }

  Map<JointName, PoseKeyPoint> _convertMLKitPose(Pose pose, Size videoSize) {
    const mapping = <PoseLandmarkType, JointName>{
      PoseLandmarkType.nose: JointName.nose,
      PoseLandmarkType.leftShoulder: JointName.leftShoulder,
      PoseLandmarkType.rightShoulder: JointName.rightShoulder,
      PoseLandmarkType.leftElbow: JointName.leftElbow,
      PoseLandmarkType.rightElbow: JointName.rightElbow,
      PoseLandmarkType.leftWrist: JointName.leftWrist,
      PoseLandmarkType.rightWrist: JointName.rightWrist,
      PoseLandmarkType.leftHip: JointName.leftHip,
      PoseLandmarkType.rightHip: JointName.rightHip,
      PoseLandmarkType.leftKnee: JointName.leftKnee,
      PoseLandmarkType.rightKnee: JointName.rightKnee,
      PoseLandmarkType.leftAnkle: JointName.leftAnkle,
      PoseLandmarkType.rightAnkle: JointName.rightAnkle,
    };

    final joints = <JointName, PoseKeyPoint>{};
    for (final entry in mapping.entries) {
      final lm = pose.landmarks[entry.key];
      if (lm == null) continue;
      joints[entry.value] = PoseKeyPoint(
        name: entry.value,
        // Normalize to [0, 1] — required by PoseOverlay painter.
        x: (lm.x / videoSize.width).clamp(0.0, 1.0),
        y: (lm.y / videoSize.height).clamp(0.0, 1.0),
        confidence: lm.likelihood,
      );
    }
    return joints;
  }

  Map<JointName, PoseKeyPoint> _smoothJoints(
    Map<JointName, PoseKeyPoint> current,
    Map<JointName, PoseKeyPoint>? previous,
  ) {
    if (previous == null) return current;

    final result = <JointName, PoseKeyPoint>{};
    for (final entry in current.entries) {
      final cur = entry.value;
      final prev = previous[entry.key];
      if (prev == null) {
        result[entry.key] = cur;
        continue;
      }
      // Carry forward when confidence is low (e.g. ball occlusion).
      final alpha = cur.confidence > _minConfidence ? _smoothingAlpha : 0.1;
      result[entry.key] = PoseKeyPoint(
        name: cur.name,
        x: alpha * cur.x + (1 - alpha) * prev.x,
        y: alpha * cur.y + (1 - alpha) * prev.y,
        confidence: alpha * cur.confidence + (1 - alpha) * prev.confidence,
      );
    }
    return result;
  }

  PoseData _buildPoseData(Map<JointName, PoseKeyPoint> joints, int timestampMs) {
    return PoseData(
      joints: joints,
      leftElbowAngle: _angle(
        joints[JointName.leftShoulder],
        joints[JointName.leftElbow],
        joints[JointName.leftWrist],
      ),
      rightElbowAngle: _angle(
        joints[JointName.rightShoulder],
        joints[JointName.rightElbow],
        joints[JointName.rightWrist],
      ),
      leftKneeAngle: _angle(
        joints[JointName.leftHip],
        joints[JointName.leftKnee],
        joints[JointName.leftAnkle],
      ),
      rightKneeAngle: _angle(
        joints[JointName.rightHip],
        joints[JointName.rightKnee],
        joints[JointName.rightAnkle],
      ),
      leftShoulderAngle: _angle(
        joints[JointName.leftElbow],
        joints[JointName.leftShoulder],
        joints[JointName.leftHip],
      ),
      rightShoulderAngle: _angle(
        joints[JointName.rightElbow],
        joints[JointName.rightShoulder],
        joints[JointName.rightHip],
      ),
      timestampMs: timestampMs,
    );
  }

  double _angle(PoseKeyPoint? a, PoseKeyPoint? b, PoseKeyPoint? c) {
    if (a == null || b == null || c == null) return 0.0;
    if (a.confidence < _minConfidence ||
        b.confidence < _minConfidence ||
        c.confidence < _minConfidence) {
      return 0.0;
    }
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);
    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final cross = ab.dx * cb.dy - ab.dy * cb.dx;
    return atan2(cross, dot).abs() * (180 / pi);
  }
}
