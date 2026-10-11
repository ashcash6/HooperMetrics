import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/pose_data.dart';
import 'package:easy_video_editor/easy_video_editor.dart';

class VideoTrimmer {
  /// Trims the video into separate shot clips based on pose timestamps.
  /// Returns a list of file paths to each trimmed clip.
  static Future<List<String>> trimShotsFromVideo(
    String inputVideoPath,
    List<List<PoseData>> shots,
  ) async {
    final List<String> shotPaths = [];
    final cacheDir = await getTemporaryDirectory();

    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];
      if (shot.isEmpty) continue;

      final int startTimeMs = shot.first.timestampMs;
      final int endTimeMs = shot.last.timestampMs;

      final outputPath = '${cacheDir.path}/shot_$i.mp4';

      try {
        final editor = VideoEditorBuilder(videoPath: inputVideoPath)
            .trim(startTimeMs: startTimeMs, endTimeMs: endTimeMs);

        final exportedPath = await editor.export(outputPath: outputPath);

        if (exportedPath != null && File(exportedPath).existsSync()) {
          shotPaths.add(exportedPath);
        }
      } catch (e) {
        debugPrint('[VideoTrimmer] Failed to trim shot $i: $e');
      }
    }

    return shotPaths;
  }
}
