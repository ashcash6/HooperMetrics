import 'package:flutter/services.dart';

class IOSCameraPermission {
  static const MethodChannel _channel = MethodChannel('ios_camera_permission');

  static Future<bool> isCameraPermissionGranted() async {
    try {
      final granted = await _channel.invokeMethod<bool>('isCameraPermissionGranted') ?? false;
      print('[Dart] isCameraPermissionGranted: $granted');
      return granted;
    } catch (e) {
      print('[Dart] isCameraPermissionGranted error: $e');
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestCameraPermission') ?? false;
      print('[Dart] requestCameraPermission: $granted');
      return granted;
    } catch (e) {
      print('[Dart] requestCameraPermission error: $e');
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      print('[Dart] openSettings called');
      await _channel.invokeMethod('openSettings');
    } catch (e) {
      print('[Dart] openSettings error: $e');
    }
  }
}
