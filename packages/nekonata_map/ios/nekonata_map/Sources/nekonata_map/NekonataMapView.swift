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

    private var regionDidChangeWorkItem: DispatchWorkItem?
    private var preZoomLevel: Double?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        channel = FlutterMethodChannel(name: "nekonata_map_\(viewId)", binaryMessenger: messenger!)
        map = MKMapView(frame: frame)

        super.init()

        // channel setup
        channel.setMethodCallHandler(handle)

        // map setup
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
        tapGesture.cancelsTouchesInView = false
        map.addGestureRecognizer(tapGesture)

        // state setup
        preZoomLevel = getZoomLevel(for: map)
    }

    func view() -> UIView {
        return map
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            switch call.method {
            case "addMarker":
                self.addMarker(call)
                result(nil)
            case "removeMarker":
                self.removeMarker(call)
                result(nil)
            case "updateMarker":
                self.updateMarker(call)
                result(nil)
            case "setMarkerVisible":
                self.setMarkerVisible(call)
                result(nil)
            case "moveCamera":
                self.moveCamera(call)
                result(nil)
            case "setRegion":
                self.setRegion(call)
                result(nil)
            case "zoom":
                result(self.getZoomLevel(for: self.map))
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    func addMarker(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String: Any],
            let id = args["id"] as? String,
            let latitude = args["latitude"] as? Double,
            let longitude = args["longitude"] as? Double
        else {
            return
        }

        let annotation = Annotation(id, latitude: latitude, longitude: longitude)
        // [Platform-specific code | Flutter](https://docs.flutter.dev/platform-integration/platform-channels#codec)
        annotation.image = (args["image"] as? FlutterStandardTypedData).map { value in value.data }
        annotation.minWidth = args["minWidth"] as? CGFloat
        annotation.minHeight = args["minHeight"] as? CGFloat

        map.addAnnotation(annotation)
    }

    func removeMarker(_ call: FlutterMethodCall) {
        guard let id = call.arguments as? String else {
            return
        }

        if let annotation = annotation(withId: id) {
            map.removeAnnotation(annotation)
        }
    }

    func updateMarker(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String: Any],
            let id = args["id"] as? String,
            let latitude = args["latitude"] as? Double,
            let longitude = args["longitude"] as? Double
        else {
            return
        }

        if let annotation = annotation(withId: id) {
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            UIView.animate(withDuration: 0.25) {
                annotation.coordinate = coordinate
            }
        }
    }

    func setMarkerVisible(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String: Any],
            let id = args["id"] as? String,
            let isVisible = args["isVisible"] as? Bool
        else {
            return
        }

        if let annotation = annotation(withId: id) {
            if let view = map.view(for: annotation) {
                UIView.animate(withDuration: 0.25) {
                    view.alpha = isVisible ? 1 : 0
                }
            }
        }
    }

    func moveCamera(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String: Any]
        else {
            return
        }

        let current = map.camera

        let latitude = args["latitude"] as? Double ?? current.centerCoordinate.latitude
        let longitude = args["longitude"] as? Double ?? current.centerCoordinate.longitude

        let zoom = args["zoom"] as? Double
        let altitude = zoom.map(convertToAltitude) ?? current.altitude

        let heading = args["heading"] as? Double ?? current.heading

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let camera = MKMapCamera(
            lookingAtCenter: coordinate, fromDistance: altitude, pitch: 0, heading: heading)
        map.setCamera(camera, animated: true)
    }

    func setRegion(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String: Any],
            let minLat = args["minLatitude"] as? Double,
            let minLon = args["minLongitude"] as? Double,
            let maxLat = args["maxLatitude"] as? Double,
            let maxLon = args["maxLongitude"] as? Double,
            let paddingPx = args["paddingPx"] as? Double
        else { return }

        let centerLat = (minLat + maxLat) / 2
        let centerLon = (minLon + maxLon) / 2

        // 緯度・経度の範囲を計算
        let latDelta = maxLat - minLat
        let lonDelta = maxLon - minLon

        // マップのサイズ取得
        let mapWidth = map.bounds.size.width
        let mapHeight = map.bounds.size.height

        // ピクセルベースのパディングを緯度・経度の割合に変換
        let latPadding = (paddingPx / mapHeight) * latDelta
        let lonPadding = (paddingPx / mapWidth) * lonDelta

        let span = MKCoordinateSpan(
            latitudeDelta: latDelta + latPadding, longitudeDelta: lonDelta + lonPadding)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon), span: span)

        map.setRegion(region, animated: true)
    }

    func annotation(withId id: String) -> Annotation? {
        return map.annotations.compactMap({ $0 as? Annotation }).first(where: { $0.id == id })
    }

    func convertToAltitude(_ zoom: Double) -> Double {
        // zoom 0 時の高度
        let altitudeAtZoom0 = 591657550.5
        // 緯度による補正
        let altitude = altitudeAtZoom0 / pow(2, zoom)
        return altitude
    }

    func getZoomLevel(for mapView: MKMapView) -> Double {
        let longitudeDelta = mapView.region.span.longitudeDelta
        let zoomLevel = log2(360 / longitudeDelta)
        // 小数第一位まで
        let roundedZoomLevel = round(10 * zoomLevel) / 10
        return roundedZoomLevel
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
        // 既存のワークアイテムがあればキャンセルする
        regionDidChangeWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let zoomLevel = self.getZoomLevel(for: mapView)
            if preZoomLevel != zoomLevel {
                self.channel.invokeMethod("onZoomEnd", arguments: zoomLevel)
                preZoomLevel = zoomLevel
            }
        }

        regionDidChangeWorkItem = workItem
        // 0.2秒後に実行（この間に連続イベントがあればキャンセルされる）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}

extension NekonataMapView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
        -> Bool
    {
        !(touch.view is MKAnnotationView)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

extension NekonataMapView {
    @objc func handleMapTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: map)
        let coordinate = map.convert(location, toCoordinateFrom: map)

        let arguments: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
        ]
        channel.invokeMethod("onMapTapped", arguments: arguments)
    }
}
