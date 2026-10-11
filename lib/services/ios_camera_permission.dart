import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class IOSCameraPermission {
  static const MethodChannel _channel = MethodChannel('ios_camera_permission');

  static Future<bool> isCameraPermissionGranted() async {
    try {
      final granted = await _channel.invokeMethod<bool>('isCameraPermissionGranted') ?? false;
      debugPrint('[Dart] isCameraPermissionGranted: $granted');
      return granted;
    } catch (e) {
      debugPrint('[Dart] isCameraPermissionGranted error: $e');
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    try {
      final granted = await _channel.invokeMethod<bool>('requestCameraPermission') ?? false;
      debugPrint('[Dart] requestCameraPermission: $granted');
      return granted;
    } catch (e) {
      debugPrint('[Dart] requestCameraPermission error: $e');
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      debugPrint('[Dart] openSettings called');
      await _channel.invokeMethod('openSettings');
    } catch (e) {
      debugPrint('[Dart] openSettings error: $e');
    }
  }
}
