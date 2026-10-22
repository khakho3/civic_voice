import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
       !apiKey.isEmpty,
       apiKey != "$(GOOGLE_MAPS_API_KEY)" {
      GMSServices.provideAPIKey(apiKey)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "CivicVoiceMapsConfig") {
      let channel = FlutterMethodChannel(name: "civic_voice/config", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "googleMapsRequestConfig" else {
          result(FlutterMethodNotImplemented)
          return
        }
        var config: [String: String] = [:]
        if let bundle = Bundle.main.bundleIdentifier {
          config["iosBundleIdentifier"] = bundle
        }
        if let key = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String,
           !key.isEmpty, key != "$(GOOGLE_MAPS_API_KEY)" {
          config["apiKey"] = key
        }
        result(config)
      }
    }
  }
}
