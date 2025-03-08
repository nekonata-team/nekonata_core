import Flutter
import UIKit

public class NekonataMapPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let factory = NekonataMapViewFactory(messenger: registrar.messenger())
    registrar.register(factory, withId: "nekonata_map")
  }
}
