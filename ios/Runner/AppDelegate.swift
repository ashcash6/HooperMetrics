import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var iosCameraPermission: IOSCameraPermission?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "ios_camera_permission",
                                       binaryMessenger: controller.binaryMessenger)

    iosCameraPermission = IOSCameraPermission()

    channel.setMethodCallHandler { [weak self] (call, result) in
      self?.iosCameraPermission?.handle(call, result: result)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
