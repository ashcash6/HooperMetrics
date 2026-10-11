import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/pose_data.dart';

class ShotReviewScreen extends StatefulWidget {
  final List<List<PoseData>> shots;
  final List<String> shotVideoPaths;

  const ShotReviewScreen({
    super.key,
    required this.shots,
    required this.shotVideoPaths,
  });

  @override
  State<ShotReviewScreen> createState() => _ShotReviewScreenState();
}

class _ShotReviewScreenState extends State<ShotReviewScreen> {
  VideoPlayerController? _controller;
  int _index = 0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.shotVideoPaths.isNotEmpty) _loadVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _loadVideo() async {
    setState(() => _isInitialized = false);
    await _controller?.dispose();
    _controller = VideoPlayerController.file(File(widget.shotVideoPaths[_index]));
    await _controller!.initialize();
    await _controller!.setLooping(true);
    _controller!.play();
    if (mounted) setState(() => _isInitialized = true);
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.shots.length) return;
    _controller?.pause();
    setState(() => _index = next);
    _loadVideo();
  }

  void _togglePlay() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.shots.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video + pose overlay
          if (_isInitialized && _controller != null)
            Center(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: VideoPlayer(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                  color: Color(0xFFFF6B00), strokeWidth: 2),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      'Shot ${_index + 1} of $total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 52),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.transparent
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NavButton(
                    icon: Icons.skip_previous_rounded,
                    enabled: _index > 0,
                    onTap: () => _go(-1),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: _togglePlay,
                    child: Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B00),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2),
                      ),
                      child: Icon(
                        _controller?.value.isPlaying == true
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _NavButton(
                    icon: Icons.skip_next_rounded,
                    enabled: _index < total - 1,
                    onTap: () => _go(1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _NavButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.25)
                  : Colors.white.withValues(alpha: 0.06)),
        ),
        child: Icon(icon,
            color: enabled
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            size: 26),
      ),
    );
  }
}
