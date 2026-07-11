import Flutter
import UIKit
import GoogleMaps // 1. Add this import

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Provide your Google Maps API Key here. Replace the placeholder string.
    // Ensure Maps SDK for iOS is enabled in Google Cloud Console and billing is set up.
    GMSServices.provideAPIKey("AIzaSyDNIpkBoIRUzAua4--Wi49E2WIyoTEtHxk")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}