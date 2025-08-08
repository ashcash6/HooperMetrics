import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  CameraController? _controller;
  CameraDescription? _camera;
  bool _isInitialized = false;
  String? recordedVideoPath;

  bool get isInitialized => _isInitialized;

  Future<void> initialize({CameraLensDirection preferredDirection = CameraLensDirection.back}) async {
    debugPrint('[CameraService] Initializing camera...');
    // Removed permission check here — handle permission externally

    final cameras = await availableCameras();
    debugPrint('[CameraService] Available cameras count: ${cameras.length}');
    if (cameras.isEmpty) {
      debugPrint('[CameraService] No cameras found.');
      _isInitialized = false;
      return;
    }

    _camera = cameras.firstWhere(
      (cam) => cam.lensDirection == preferredDirection,
      orElse: () => cameras.first,
    );
    debugPrint('[CameraService] Selected camera: ${_camera!.name}');

    _controller = CameraController(
      _camera!,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      _isInitialized = true;
      debugPrint('[CameraService] Camera initialized successfully.');
    } catch (e) {
      debugPrint('[CameraService] Camera initialization failed: $e');
      _isInitialized = false;
    }
  }

  Future<void> startRecording() async {
    if (!_isInitialized || _controller == null) {
      debugPrint('[CameraService] Cannot start recording: Camera not initialized');
      return;
    }

    try {
      await _controller!.startVideoRecording();
      debugPrint('[CameraService] Started video recording');
    } catch (e) {
      debugPrint('[CameraService] Failed to start video recording: $e');
    }
  }

  Future<void> stopRecording() async {
    if (!_isInitialized || _controller == null) {
      debugPrint('[CameraService] Cannot stop recording: Camera not initialized');
      return;
    }

    try {
      final file = await _controller!.stopVideoRecording();
      recordedVideoPath = file.path;
      debugPrint('[CameraService] Stopped video recording, saved to $recordedVideoPath');
    } catch (e) {
      debugPrint('[CameraService] Failed to stop video recording: $e');
    }
  }

  Future<void> startStreaming(Function(CameraImage) onImageAvailable) async {
    if (!_isInitialized || _controller == null) {
      debugPrint('[CameraService] Cannot start streaming: Camera not initialized');
      return;
    }

    try {
      await _controller!.startImageStream((CameraImage image) {
        onImageAvailable(image);
      });
      debugPrint('[CameraService] Started image streaming');
    } catch (e) {
      debugPrint('[CameraService] Failed to start image streaming: $e');
    }
  }

  Future<void> stopStreaming() async {
    if (!_isInitialized || _controller == null) {
      debugPrint('[CameraService] Cannot stop streaming: Camera not initialized');
      return;
    }

    try {
      await _controller!.stopImageStream();
      debugPrint('[CameraService] Stopped image streaming');
    } catch (e) {
      debugPrint('[CameraService] Failed to stop image streaming: $e');
    }
  }

  Widget buildPreview() {
    if (!_isInitialized || _controller == null || !_controller!.value.isInitialized) {
      return const Center(child: Text('Camera not available', style: TextStyle(color: Colors.white)));
    }
    return CameraPreview(_controller!);
  }

  void dispose() {
    _controller?.dispose();
  }
}
