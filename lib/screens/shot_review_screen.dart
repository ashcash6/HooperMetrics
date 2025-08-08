import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/pose_data.dart';

class ShotReviewScreen extends StatefulWidget {
  final List<List<PoseData>> shots;
  final List<String> shotVideoPaths;

  const ShotReviewScreen({
    Key? key,
    required this.shots,
    required this.shotVideoPaths,
  }) : super(key: key);

  @override
  State<ShotReviewScreen> createState() => _ShotReviewScreenState();
}

class _ShotReviewScreenState extends State<ShotReviewScreen> {
  VideoPlayerController? _videoController;
  Timer? _poseUpdateTimer;
  int _currentShotIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.shots.isNotEmpty) {
      _initializeVideo();
    }
  }

  @override
  void didUpdateWidget(covariant ShotReviewScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shots.isNotEmpty &&
        oldWidget.shotVideoPaths[_currentShotIndex] !=
            widget.shotVideoPaths[_currentShotIndex]) {
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    _poseUpdateTimer?.cancel();
    await _videoController?.dispose();

    final path = widget.shotVideoPaths[_currentShotIndex];
    _videoController = VideoPlayerController.file(File(path));

    await _videoController!.initialize();
    setState(() {});
    _videoController!.play();

    _poseUpdateTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (_videoController == null ||
          !_videoController!.value.isInitialized ||
          !_videoController!.value.isPlaying) return;
      // Could add pose sync here if needed later
    });
  }

  @override
  void dispose() {
    _poseUpdateTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  void _nextShot() {
    if (_currentShotIndex < widget.shots.length - 1) {
      _poseUpdateTimer?.cancel();
      _videoController?.pause();
      setState(() {
        _currentShotIndex++;
      });
      _initializeVideo();
    }
  }

  void _previousShot() {
    if (_currentShotIndex > 0) {
      _poseUpdateTimer?.cancel();
      _videoController?.pause();
      setState(() {
        _currentShotIndex--;
      });
      _initializeVideo();
    }
  }

  void _replayShot() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      _videoController!.seekTo(Duration.zero);
      _videoController!.play();
    }
  }

  void _goBackToCamera() {
    Navigator.of(context).pushReplacementNamed('/camera');
  }


  @override
  Widget build(BuildContext context) {
    if (widget.shots.isEmpty) {
      // No shots detected error screen
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('No Shots Detected'),
          backgroundColor: Colors.orange.shade800,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 72, color: Colors.redAccent),
                const SizedBox(height: 20),
                const Text(
                  'No shots were detected in the video.\nPlease try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _goBackToCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text(
                    'Go back to Camera',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Please review the shooting instructions on the camera screen for better results.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Normal shot review UI
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Shot ${_currentShotIndex + 1} of ${widget.shots.length}'),
        backgroundColor: Colors.orange.shade800,
      ),
      body: _videoController != null && _videoController!.value.isInitialized
          ? Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_currentShotIndex > 0)
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 32),
                          color: Colors.orange,
                          onPressed: _previousShot,
                        ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.replay, size: 32),
                        color: Colors.orange,
                        onPressed: _replayShot,
                      ),
                      const SizedBox(width: 20),
                      if (_currentShotIndex < widget.shots.length - 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_forward, size: 32),
                          color: Colors.orange,
                          onPressed: _nextShot,
                        ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );
  }
}
