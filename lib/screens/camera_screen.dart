import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../models/pose_data.dart';
import '../services/video_trimmer.dart';
import '../services/ios_camera_permission.dart';
import '../services/camera_service.dart';
import '../services/shot_segmentation.dart';
import '../services/shot_analysis.dart';
import '../services/video_pose_processor.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  static const String routeName = '/camera';
  const CameraScreen({super.key});

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
  bool _isInitializing = false;
  bool _isStartingRecording = false;
  int _progressCurrent = 0;
  int _progressTotal = 0;

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
    // Only check permission status on resume — never re-init the camera here.
    // Re-initializing on resume triggers a race: the permission dialog closing
    // fires "resumed", which would dispose a controller that might be mid-init.
    // The camera plugin handles pause/resume internally.
    if (state == AppLifecycleState.resumed) {
      final granted = await IOSCameraPermission.isCameraPermissionGranted();
      if (!mounted) return;
      if (!granted) setState(() => _permissionDenied = true);
    }
  }

  Future<void> _initializeCamera() async {
    if (_isInitializing) return;
    _isInitializing = true;
    try {
      final granted = await IOSCameraPermission.isCameraPermissionGranted();
      if (!mounted) return;
      if (!granted) {
        final requested = await IOSCameraPermission.requestCameraPermission();
        if (!mounted) return;
        if (!requested) {
          setState(() => _permissionDenied = true);
          return;
        }
      }
      await _cameraService.initialize();
      if (!mounted) return;
      if (!_cameraService.isInitialized) {
        setState(() => _initError = 'Camera failed to initialize');
      }
    } catch (e) {
      if (mounted) setState(() => _initError = e.toString());
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _startRecording() async {
    if (_isStartingRecording) return;
    _isStartingRecording = true;
    setState(() => _canStop = false);

    bool started = false;
    try {
      await _cameraService.startRecording();
      started = true;
    } catch (e) {
      debugPrint('[CameraScreen] startRecording error: $e');
      if (mounted) {
        // CameraService already attempted recovery internally; if we're here
        // both attempts failed. Refresh the preview widget and tell the user.
        setState(() {});
        _showSnack('Camera not ready — please try again.');
      }
    } finally {
      _isStartingRecording = false;
    }

    if (!started || !mounted) return;
    setState(() => _isRecording = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _canStop = true);
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
      if (mounted) _showSnack('Failed to stop recording: $e');
      setState(() { _isProcessing = false; _canStop = false; });
      return;
    }

    final videoPath = _cameraService.recordedVideoPath;

    if (videoPath != null) {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (DateTime.now().isBefore(deadline)) {
        final f = File(videoPath);
        if (await f.exists() && await f.length() > 0) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    if (videoPath == null || !await File(videoPath).exists()) {
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final processor = VideoPoseProcessor(videoPath: videoPath);
      final poses = await processor.extractPosesFromVideo(
        onProgress: (current, total) {
          // Update UI every 5 frames — calling setState per-frame causes
          // hundreds of full widget-tree rebuilds during processing.
          if (mounted && (current == 1 || current % 5 == 0 || current == total)) {
            setState(() { _progressCurrent = current; _progressTotal = total; });
          }
        },
      );

      final allShots = ShotSegmentation.detectShots(poses);

      // The first detected shot is always treated as a calibration and dropped.
      // Users are told to take one warm-up shot before their real session.
      final shots = allShots.length > 1 ? allShots.sublist(1) : <List<PoseData>>[];

      if (shots.isEmpty) {
        setState(() => _isProcessing = false);
        _showNoShotsDialog(calibrationOnly: allShots.isNotEmpty);
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
      debugPrint('[CameraScreen] Error: $e\n$stack');
      if (mounted) {
        setState(() => _isProcessing = false);
        _showSnack('Analysis failed: $e');
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF1A1A1A)),
    );
  }

  void _showNoShotsDialog({bool calibrationOnly = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          calibrationOnly ? 'Only Calibration Shot Found' : 'No Shots Detected',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          calibrationOnly
              ? 'Only your calibration shot was detected. After the calibration, take at least one more shot — hold your follow-through until the ball is in the air.'
              : 'We could not detect any shots in your video.\n\n'
                'Make sure you are standing sideways with your full body in frame, and hold your follow-through after each shot.',
          style: const TextStyle(color: Color(0xFF888888), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Error / permission screens ───────────────────────────────────────────────

  Widget _buildPermissionDeniedScreen() {
    return _buildStatusScreen(
      icon: Icons.videocam_off_outlined,
      title: 'Camera Access Required',
      subtitle: 'Please grant camera permission to use HooperMetrics.',
      action: ElevatedButton(
        onPressed: IOSCameraPermission.openSettings,
        style: _orangeButtonStyle,
        child: const Text('Open Settings'),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return _buildStatusScreen(
      icon: Icons.error_outline_rounded,
      title: 'Something went wrong',
      subtitle: error,
      action: ElevatedButton(
        onPressed: () => setState(() {
          _initError = null;
          _initializationFuture = _initializeCamera();
        }),
        style: _orangeButtonStyle,
        child: const Text('Retry'),
      ),
    );
  }

  Widget _buildStatusScreen({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget action,
  }) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 36, color: const Color(0xFFFF6B00)),
              ),
              const SizedBox(height: 24),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 14, height: 1.5)),
              const SizedBox(height: 32),
              action,
            ],
          ),
        ),
      ),
    );
  }

  // ── Main build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) return _buildPermissionDeniedScreen();
    if (_initError != null) return _buildErrorScreen(_initError!);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Full-screen camera preview
          FutureBuilder<void>(
            future: _initializationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF6B00), strokeWidth: 2),
                );
              } else if (snapshot.hasError) {
                return _buildErrorScreen(snapshot.error.toString());
              }
              return SizedBox.expand(child: _cameraService.buildPreview());
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  if (_isRecording)
                    _RecBadge()
                  else
                    _CircleIconButton(
                      icon: Icons.help_outline_rounded,
                      onTap: _showInstructionsModal,
                    ),
                ],
              ),
            ),
          ),

          // Bottom gradient + record button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 48, 0, 56),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                ),
              ),
              child: Center(child: _buildRecordButton()),
            ),
          ),

          // Processing overlay
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    final isWaiting = _isRecording && !_canStop;

    return GestureDetector(
      onTap: isWaiting ? null : (_isRecording ? _stopRecording : _startRecording),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: _isRecording ? 68 : 78,
        height: _isRecording ? 68 : 78,
        decoration: BoxDecoration(
          color: isWaiting
              ? const Color(0xFF333333)
              : (_isRecording ? Colors.redAccent : const Color(0xFFFF6B00)),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
        ),
        child: Icon(
          _isRecording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
          color: Colors.white,
          size: _isRecording ? 30 : 34,
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFFFF6B00),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Analyzing your shots…',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (_progressTotal > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressCurrent / _progressTotal,
                        backgroundColor: const Color(0xFF2A2A2A),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Frame $_progressCurrent of $_progressTotal',
                      style: const TextStyle(color: Color(0xFF666666), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showInstructionsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Setup Reminders',
              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ...[
              'Phone on tripod or stable surface, ~10 ft away',
              'Stand sideways — shooting side facing camera',
              'Full body visible from head to toe',
              'First shot is a calibration — it won\'t be scored',
              'Hold your follow-through after each shot',
              'Stay in the same spot between shots',
            ].map(
              (t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Color(0xFFFF6B00), size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(t, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 14)),
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
}

// ── Shared small widgets ─────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

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

class _RecBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulseDot(),
          SizedBox(width: 6),
          Text('REC',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1)),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
        ..repeat(reverse: true);
  late final Animation<double> _anim = Tween(begin: 0.4, end: 1.0).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 7,
        height: 7,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }
}

final _orangeButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFFF6B00),
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 0,
);
