import Flutter
import MapKit
import UIKit

class NekonataMapViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return NekonataMapView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger)
    }

    /// Implementing this method is only necessary when the `arguments` in `createWithFrame` is not `nil`.
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class NekonataMapView: NSObject, FlutterPlatformView {
    private var map: MKMapView
    private var channel: FlutterMethodChannel

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        channel = FlutterMethodChannel(name: "nekonata_map_\(viewId)", binaryMessenger: messenger!)
        map = MKMapView(frame: frame)

        super.init()

        channel.setMethodCallHandler(handle)

        map.delegate = self
        if let dict = args as? [String: Any],
            let latitude = dict["latitude"] as? CLLocationDegrees,
            let longitude = dict["longitude"] as? CLLocationDegrees
        {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let region = MKCoordinateRegion(
                center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            map.setRegion(region, animated: false)
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tapGesture.delegate = self
        map.addGestureRecognizer(tapGesture)
    }

    @objc func handleMapTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: map)
        let coordinate = map.convert(location, toCoordinateFrom: map)

        let arguments: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude
        ]
        channel.invokeMethod("onMapTapped", arguments: arguments)
    }

    func view() -> UIView {
        return map
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "addMarker":
            do {
                try addMarker(call)
                result(nil)
            } catch {
                result(error)
            }
        case "removeMarker":
            do {
                try removeMarker(call)
                result(nil)
            } catch {
                result(error)
            }
        case "updateMarker":
            do {
                try updateMarker(call)
                result(nil)
            } catch {
                result(error)
            }
        case "moveCamera":
            do {
                try moveCamera(call)
                result(nil)
            } catch {
                result(error)
            }
        case "zoom":
            result(getZoomLevel(for: map))
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func addMarker(_ call: FlutterMethodCall) throws {
        guard let args = call.arguments as? [String: Any],
            let id = args["id"] as? String,
            let latitude = args["latitude"] as? Double,
            let longitude = args["longitude"] as? Double
        else {
            throw NSError(domain: "Invalid arguments", code: 0, userInfo: nil)
        }

        let annotation = Annotation(id, latitude: latitude, longitude: longitude)
        // [Platform-specific code | Flutter](https://docs.flutter.dev/platform-integration/platform-channels#codec)
        annotation.image = (args["image"] as? FlutterStandardTypedData).map { value in value.data }
        annotation.minWidth = args["minWidth"] as? CGFloat
        annotation.minHeight = args["minHeight"] as? CGFloat

        map.addAnnotation(annotation)
    }

    func removeMarker(_ call: FlutterMethodCall) throws {
        guard let id = call.arguments as? String else {
            throw NSError(domain: "Invalid arguments", code: 0, userInfo: nil)
        }

        if let annotation = annotation(withId: id) {
            map.removeAnnotation(annotation)
        }
    }

    func updateMarker(_ call: FlutterMethodCall) throws {
        guard let args = call.arguments as? [String: Any],
            let id = args["id"] as? String,
            let latitude = args["latitude"] as? Double,
            let longitude = args["longitude"] as? Double
        else {
            throw NSError(domain: "Invalid arguments", code: 0, userInfo: nil)
        }

        if let annotation = annotation(withId: id) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            UIView.animate(withDuration: 0.25) {
                annotation.coordinate = coordinate
            }
        }
    }

    func moveCamera(_ call: FlutterMethodCall) throws {
        guard let args = call.arguments as? [String: Any]
        else {
            throw NSError(domain: "Invalid arguments", code: 0, userInfo: nil)
        }

        let current = map.camera

        let latitude = args["latitude"] as? Double ?? current.centerCoordinate.latitude
        let longitude = args["longitude"] as? Double ?? current.centerCoordinate.longitude

        let zoom = args["zoom"] as? Double
        let altitude = zoom.map(convertToAltitude) ?? current.altitude

        let heading = args["heading"] as? Double ?? current.heading

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let camera = MKMapCamera(lookingAtCenter: coordinate, fromDistance: altitude, pitch: 0, heading: heading)
        map.setCamera(camera, animated: true)
    }

    func annotation(withId id: String) -> Annotation? {
        return map.annotations.compactMap({ $0 as? Annotation }).first(where: { $0.id == id })
    }

    func convertToAltitude(_ zoom: Double) -> Double {
        // zoom 0 時の高度（この値は例示用です）
        let altitudeAtZoom0 = 591657550.5
        // 緯度による補正
        let altitude = altitudeAtZoom0 / pow(2, zoom)
        return altitude
    }
    
    // ズームレベルを計算する
    func getZoomLevel(for mapView: MKMapView) -> Double {
        let longitudeDelta = mapView.region.span.longitudeDelta
        return log2(360 / longitudeDelta)
    }
}

extension NekonataMapView: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotation = annotation as? Annotation else {
            return nil
        }

        if let view = mapView.dequeueReusableAnnotationView(withIdentifier: annotation.id) {
            return view
        }

        if annotation.image != nil {
            return ImageAnnotationView(annotation: annotation, reuseIdentifier: annotation.id)
        } else {
            return MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: annotation.id)
        }
    }

    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        guard let annotation = annotation as? Annotation else {
            return
        }

        channel.invokeMethod("onMarkerTapped", arguments: annotation.id)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if (animated) {
            return
        }
        
        let zoomLevel = getZoomLevel(for: mapView)
        
        channel.invokeMethod("onZoomEnd", arguments: zoomLevel)
    }
}

extension NekonataMapView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is MKAnnotationView)
    }
}
