import AVFoundation
import UIKit
import Flutter

@objc class IOSCameraPermission: NSObject {

  @objc func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    print("[Swift] handle() called with method: \(call.method)")

    switch call.method {
    case "isCameraPermissionGranted":
      let granted = isCameraPermissionGranted()
      print("[Swift] isCameraPermissionGranted = \(granted)")
      result(granted)
    case "requestCameraPermission":
      print("[Swift] requestCameraPermission called")
      requestCameraPermission(result: result)
    case "openSettings":
      print("[Swift] openSettings called")
      openSettings()
      result(nil)
    default:
      print("[Swift] Method not implemented: \(call.method)")
      result(FlutterMethodNotImplemented)
    }
  }

  private func isCameraPermissionGranted() -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    print("[Swift] authorizationStatus = \(status.rawValue)")

    return status == .authorized
  }

  private func requestCameraPermission(result: @escaping FlutterResult) {
    AVCaptureDevice.requestAccess(for: .video) { granted in
      DispatchQueue.main.async {
        print("[Swift] requestAccess granted = \(granted)")
        result(granted)
      }
    }
  }

  private func openSettings() {
    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
      print("[Swift] Invalid settings URL")
      return
    }
    if UIApplication.shared.canOpenURL(settingsUrl) {
      print("[Swift] Opening app settings")
      UIApplication.shared.open(settingsUrl)
    } else {
      print("[Swift] Cannot open app settings")
    }
  }
}
