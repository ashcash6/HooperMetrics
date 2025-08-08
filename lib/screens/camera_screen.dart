import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../services/video_trimmer.dart';
import '../services/ios_camera_permission.dart';
import '../services/camera_service.dart';
import '../services/pose_estimation_service.dart';
import '../services/shot_segmentation.dart';
import '../services/shot_analysis.dart';
import '../services/video_pose_processor.dart';
import '../models/pose_data.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  static const String routeName = '/camera';

  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  late final CameraService _cameraService = CameraService();
  bool _isRecording = false;
  bool _permissionDenied = false;
  String? _initError;
  bool _isProcessing = false;
  bool _canStop = false;

  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializationFuture = _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final granted = await IOSCameraPermission.isCameraPermissionGranted();
      if (!mounted) return;
      if (granted) {
        setState(() {
          _permissionDenied = false;
          _initError = null;
          _initializationFuture = _initializeCamera();
        });
      } else {
        setState(() => _permissionDenied = true);
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final granted = await IOSCameraPermission.isCameraPermissionGranted();
      if (!granted) {
        final requested = await IOSCameraPermission.requestCameraPermission();
        if (!requested) {
          setState(() => _permissionDenied = true);
          throw Exception('Camera permission denied');
        }
      }

      await _cameraService.initialize();
      if (!_cameraService.isInitialized) {
        throw Exception('Camera failed to initialize');
      }
    } catch (e) {
      setState(() => _initError = e.toString());
      rethrow;
    }
  }

  Future<void> _startRecording() async {
    setState(() => _canStop = false);

    try {
      await _cameraService.startRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isRecording = true;
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _canStop = true);
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_canStop) return;

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });

    try {
      await _cameraService.stopRecording();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
      setState(() {
        _isProcessing = false;
        _canStop = false;
      });
      return;
    }

    await Future.delayed(const Duration(seconds: 3));

    final videoPath = _cameraService.recordedVideoPath;
    print('[CameraScreen] Video path: $videoPath');

    if (videoPath == null || !await File(videoPath).exists()) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final interpreter = await Interpreter.fromAsset('assets/models/4.tflite');
      final processor = VideoPoseProcessor(videoPath: videoPath, interpreter: interpreter);
      final poses = await processor.extractPosesFromVideo();

      final shots = ShotSegmentation.detectShots(poses);

      if (shots.isEmpty) {
        setState(() => _isProcessing = false);
        _showNoShotsDetectedDialog();
        return;
      }

      final trimmedPaths = await VideoTrimmer.trimShotsFromVideo(videoPath, shots);
      final analysis = ShotAnalyzer().analyzeShots(shots);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            overallScore: analysis.overallScore,
            detailedScores: analysis.detailedScores,
            tips: analysis.tips,
            shots: shots,
            shotVideoPaths: trimmedPaths,
            videoPath: videoPath,
          ),
        ),
      );
    } catch (e, stack) {
      print('[CameraScreen] ❌ Error during video processing: $e');
      print(stack);
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video analysis failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showNoShotsDetectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'No Shots Detected',
          style: TextStyle(color: Colors.orangeAccent),
        ),
        content: const Text(
          'We could not detect any shots in your video.\n\n'
          'Please review the shooting instructions and try again.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.orangeAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off, size: 64, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              const Text(
                'Camera permission is required to use this feature.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: IOSCameraPermission.openSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Open Settings', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 24),
              Text(
                'Error: $error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _initError = null;
                    _initializationFuture = _initializeCamera();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) return _buildPermissionDeniedScreen();
    if (_initError != null) return _buildErrorScreen(_initError!);

    return Stack(
      children: [
        FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return _buildErrorScreen(snapshot.error.toString());
            } else {
              return Scaffold(
                backgroundColor: Colors.black,
                body: SizedBox.expand(
                  child: Column(
                    children: [
                      Expanded(
                        flex: 7,
                        child: SizedBox.expand(
                          child: _cameraService.buildPreview(),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _isRecording
                                    ? (_canStop ? _stopRecording : null)
                                    : _startRecording,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isRecording ? Colors.redAccent : Colors.orange,
                                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: Text(
                                  _isRecording ? 'Stop Recording' : 'Start Recording',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                              OutlinedButton(
                                onPressed: _showInstructionsModal,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.orangeAccent, width: 2),
                                  padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                child: const Text(
                                  'View Shooting Instructions',
                                  style: TextStyle(fontSize: 16, color: Colors.orangeAccent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.85),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 20),
                  Text(
                    'Processing video...',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showInstructionsModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
              child: ListView(
                children: [
                  const Text(
                    'Shooting Setup Guide',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...[
                    'The first shot is used for calibration',
                    'Always try to shoot from the same spot each time',
                    'Stand sideways to the camera when shooting',
                    'Stand around 10 feet from the camera',
                    'Keep the phone vertical',
                    'Use a tripod or keep the phone still',
                    'Make sure your whole body is visible and close to the camera',
                    'Hold your follow-through',
                    'Avoid walking or celebrating between shots',
                  ].map(_buildTip),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Colors.orangeAccent, fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
