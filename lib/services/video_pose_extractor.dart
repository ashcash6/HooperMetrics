import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../models/pose_data.dart';
import '../services/pose_estimation_service.dart';

class VideoPoseExtractor {
  final PoseEstimationService poseService;

  VideoPoseExtractor(this.poseService);

  /// Extracts pose data from a video at [videoPath].
  /// Returns a list of [PoseData] objects representing each frame.
  Future<List<PoseData>> extractPoseDataFromVideo(String videoPath) async {
    debugPrint('[VideoPoseExtractor] Starting pose extraction from video: $videoPath');

    final List<PoseData> poseFrames = [];

    // Simulate frame-by-frame processing using thumbnails (every 100ms)
    for (int i = 0; i < 9999; i++) {
      final thumbnail = await VideoThumbnail.thumbnailData(
        video: videoPath,
        timeMs: i * 100, // 100 ms per frame (10 fps)
        imageFormat: ImageFormat.JPEG,
        quality: 75,
      );

      if (thumbnail == null) break;

      try {
        final pose = await poseService.runModelOnImageBytes(thumbnail);
        poseFrames.add(pose);
      } catch (e) {
        debugPrint('[VideoPoseExtractor] Failed to extract pose from frame $i: $e');
      }
    }

    debugPrint('[VideoPoseExtractor] Pose extraction complete: ${poseFrames.length} frames.');
    return poseFrames;
  }
}
