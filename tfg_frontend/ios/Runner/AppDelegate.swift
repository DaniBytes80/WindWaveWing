import Flutter
import UIKit
import GoolgeMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // TODO: Add your Google Maps API key
    GMSServices.provideAPIKey(Configuration.googleAPI)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
