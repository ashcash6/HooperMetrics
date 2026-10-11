// lib/models/shot.dart

import 'pose_data.dart';
class Shot {
  final int startFrame;
  final int endFrame;
  final List<PoseData> frames;

  Shot({
    required this.startFrame,
    required this.endFrame,
    required this.frames,
  });

  PoseData get start => frames.first;
  PoseData get end => frames.last;
}
