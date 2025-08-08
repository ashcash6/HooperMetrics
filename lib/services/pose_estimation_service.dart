import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/pose_data.dart';
import '../models/pose_keypoint.dart';
import 'camera_service.dart';

class PoseEstimationService {
  final CameraService _cameraService;
  late Interpreter _interpreter;
  final StreamController<PoseData> _poseStreamController = StreamController<PoseData>.broadcast();

  Stream<PoseData> get poseStream => _poseStreamController.stream;

  PoseEstimationService(this._cameraService);

  Future<void> initialize() async {
    _interpreter = await Interpreter.fromAsset('assets/models/4.tflite');

    // Debug: check if asset is bundled correctly and loadable
    rootBundle.load('models/4.tflite').then((data) {
      debugPrint('[Debug] 4.tflite asset size: ${data.lengthInBytes}');
    }).catchError((e) {
      debugPrint('[Debug] Failed to load asset manually: $e');
    });
  }

  void start() {
    _cameraService.startStreaming(_processCameraImage);
  }

  void stop() {
    _cameraService.stopStreaming();
  }

  void dispose() {
    _poseStreamController.close();
    _interpreter.close();
  }

  void _processCameraImage(CameraImage image) async {
    // Convert CameraImage to input format expected by model
    final input = _preprocessImage(image);

    // Run model and get PoseData with timestamp
    final poseData = await _getPoseFromModel(input);

    _poseStreamController.add(poseData);
  }

  List<List<List<List<int>>>> _preprocessImage(CameraImage image) {
    // Your preprocessing logic here: resize, normalize, etc.
    // For example purposes, returning dummy data:
    return List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(257, (_) => List.filled(257, 0)),
      ),
    );
  }

  Future<PoseData> _getPoseFromModel(List<List<List<List<int>>>> input) async {
    final output = List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(17, (_) => List.filled(3, 0.0)),
      ),
    );

    _interpreter.run(input, output);

    final joints = <JointName, PoseKeyPoint>{
      JointName.leftShoulder: PoseKeyPoint(
        name: JointName.leftShoulder,
        x: output[0][0][5][0],
        y: output[0][0][5][1],
        z: output[0][0][5][2],
      ),
      JointName.rightShoulder: PoseKeyPoint(
        name: JointName.rightShoulder,
        x: output[0][0][6][0],
        y: output[0][0][6][1],
        z: output[0][0][6][2],
      ),
      JointName.leftElbow: PoseKeyPoint(
        name: JointName.leftElbow,
        x: output[0][0][7][0],
        y: output[0][0][7][1],
        z: output[0][0][7][2],
      ),
      JointName.rightElbow: PoseKeyPoint(
        name: JointName.rightElbow,
        x: output[0][0][8][0],
        y: output[0][0][8][1],
        z: output[0][0][8][2],
      ),
      JointName.leftWrist: PoseKeyPoint(
        name: JointName.leftWrist,
        x: output[0][0][9][0],
        y: output[0][0][9][1],
        z: output[0][0][9][2],
      ),
      JointName.rightWrist: PoseKeyPoint(
        name: JointName.rightWrist,
        x: output[0][0][10][0],
        y: output[0][0][10][1],
        z: output[0][0][10][2],
      ),
      JointName.leftHip: PoseKeyPoint(
        name: JointName.leftHip,
        x: output[0][0][11][0],
        y: output[0][0][11][1],
        z: output[0][0][11][2],
      ),
      JointName.rightHip: PoseKeyPoint(
        name: JointName.rightHip,
        x: output[0][0][12][0],
        y: output[0][0][12][1],
        z: output[0][0][12][2],
      ),
      JointName.leftKnee: PoseKeyPoint(
        name: JointName.leftKnee,
        x: output[0][0][13][0],
        y: output[0][0][13][1],
        z: output[0][0][13][2],
      ),
      JointName.rightKnee: PoseKeyPoint(
        name: JointName.rightKnee,
        x: output[0][0][14][0],
        y: output[0][0][14][1],
        z: output[0][0][14][2],
      ),
      JointName.leftAnkle: PoseKeyPoint(
        name: JointName.leftAnkle,
        x: output[0][0][15][0],
        y: output[0][0][15][1],
        z: output[0][0][15][2],
      ),
      JointName.rightAnkle: PoseKeyPoint(
        name: JointName.rightAnkle,
        x: output[0][0][16][0],
        y: output[0][0][16][1],
        z: output[0][0][16][2],
      ),
      JointName.nose: PoseKeyPoint(
        name: JointName.nose,
        x: output[0][0][0][0],
        y: output[0][0][0][1],
        z: output[0][0][0][2],
      ),
      JointName.leftEye: PoseKeyPoint(
        name: JointName.leftEye,
        x: output[0][0][1][0],
        y: output[0][0][1][1],
        z: output[0][0][1][2],
      ),
      JointName.rightEye: PoseKeyPoint(
        name: JointName.rightEye,
        x: output[0][0][2][0],
        y: output[0][0][2][1],
        z: output[0][0][2][2],
      ),
      JointName.leftEar: PoseKeyPoint(
        name: JointName.leftEar,
        x: output[0][0][3][0],
        y: output[0][0][3][1],
        z: output[0][0][3][2],
      ),
      JointName.rightEar: PoseKeyPoint(
        name: JointName.rightEar,
        x: output[0][0][4][0],
        y: output[0][0][4][1],
        z: output[0][0][4][2],
      ),
    };

    final timestampMs = DateTime.now().millisecondsSinceEpoch;

    return PoseData(
      joints: joints,
      leftElbowAngle: _calculateAngle(
        joints[JointName.leftShoulder]!,
        joints[JointName.leftElbow]!,
        joints[JointName.leftWrist]!,
      ),
      rightElbowAngle: _calculateAngle(
        joints[JointName.rightShoulder]!,
        joints[JointName.rightElbow]!,
        joints[JointName.rightWrist]!,
      ),
      leftKneeAngle: _calculateAngle(
        joints[JointName.leftHip]!,
        joints[JointName.leftKnee]!,
        joints[JointName.leftAnkle]!,
      ),
      rightKneeAngle: _calculateAngle(
        joints[JointName.rightHip]!,
        joints[JointName.rightKnee]!,
        joints[JointName.rightAnkle]!,
      ),
      timestampMs: timestampMs,
    );
  }

  double _calculateAngle(PoseKeyPoint a, PoseKeyPoint b, PoseKeyPoint c) {
    final ab = Offset(a.x - b.x, a.y - b.y);
    final cb = Offset(c.x - b.x, c.y - b.y);

    final dot = ab.dx * cb.dx + ab.dy * cb.dy;
    final cross = ab.dx * cb.dy - ab.dy * cb.dx;

    final angle = (atan2(cross, dot) * 180 / 3.141592653589793).abs();

    return angle;
  }

  /// Runs pose model on a raw image [Uint8List] (e.g. from video thumbnail).
  Future<PoseData> runModelOnImageBytes(Uint8List imageBytes) async {
    // TODO: Implement actual preprocessing of [imageBytes] to model input
    // For now, simulate dummy input and use existing pose logic

    final dummyInput = List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(257, (_) => List.filled(257, 0)),
      ),
    );

    return _getPoseFromModel(dummyInput);
  }
}
