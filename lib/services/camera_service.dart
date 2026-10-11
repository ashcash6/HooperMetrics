import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;
  CameraDescription? _camera;
  bool _isInitialized = false;
  String? recordedVideoPath;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({CameraLensDirection preferredDirection = CameraLensDirection.back}) async {
    // Dispose any existing controller first so we never have two live sessions.
    if (_controller != null) {
      final old = _controller!;
      _controller = null;
      _isInitialized = false;
      await old.dispose();
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _camera = cameras.firstWhere(
      (cam) => cam.lensDirection == preferredDirection,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      _camera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      _isInitialized = true;
    } catch (e) {
      debugPrint('[CameraService] init failed: $e');
      _isInitialized = false;
    }
  }

  Future<void> startRecording() async {
    if (!_isInitialized || _controller == null) return;
    try {
      await _controller!.startVideoRecording()
          .timeout(const Duration(seconds: 6));
    } on TimeoutException {
      debugPrint('[CameraService] startVideoRecording timed out — reinitializing');
      await _recoverAndStart();
    } catch (e) {
      debugPrint('[CameraService] startRecording failed: $e — reinitializing');
      await _recoverAndStart();
    }
  }

  // Dispose the session, rebuild it, and retry recording once.
  Future<void> _recoverAndStart() async {
    await initialize();
    if (!_isInitialized || _controller == null) {
      throw Exception('Camera session could not be recovered.');
    }
    await _controller!.startVideoRecording()
        .timeout(const Duration(seconds: 6));
  }

  Future<void> stopRecording() async {
    if (!_isInitialized || _controller == null) return;
    try {
      final file = await _controller!.stopVideoRecording();
      recordedVideoPath = file.path;
    } catch (e) {
      debugPrint('[CameraService] stopRecording failed: $e');
      rethrow;
    }
  }

  Widget buildPreview() {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text('Camera not available', style: TextStyle(color: Colors.white)),
      );
    }
    // Scale preview to cover the available space without distortion.
    // CameraPreview applies AspectRatio internally; with tight expand constraints
    // that overrides the ratio and stretches the image. Transform.scale corrects
    // for the mismatch between camera AR and screen AR (BoxFit.cover equivalent).
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        if (w == 0 || h == 0 || !constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
          return CameraPreview(_controller!);
        }
        final camAR = _controller!.value.aspectRatio;
        if (camAR == 0) return CameraPreview(_controller!);
        var scale = (w / h) * camAR;
        if (scale < 1.0) scale = 1.0 / scale;
        return ClipRect(
          child: Transform.scale(
            scale: scale,
            child: Center(child: CameraPreview(_controller!)),
          ),
        );
      },
    );
  }

  void dispose() {
    final c = _controller;
    _controller = null;
    _isInitialized = false;
    c?.dispose();
  }
}
