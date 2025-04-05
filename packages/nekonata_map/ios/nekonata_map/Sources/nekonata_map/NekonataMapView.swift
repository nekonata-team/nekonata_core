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
    private var mapView: MKMapView
    private var channel: FlutterMethodChannel

    private var initialCoordinates: CLLocationCoordinate2D?

    private var regionDidChangeWorkItem: DispatchWorkItem?
    private var preZoomLevel: Double?

    private var baseDistance: Double = 0
    private var setUpFinished: Bool = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        channel = FlutterMethodChannel(
            name: "nekonata_map_\(viewId)", binaryMessenger: messenger!)
        mapView = MKMapView(frame: frame)

        super.init()

        // channel setup
        channel.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }

        // map setup
        mapView.delegate = self
        if let dict = args as? [String: Any],
            let latitude = dict["latitude"] as? CLLocationDegrees,
            let longitude = dict["longitude"] as? CLLocationDegrees
        {
            initialCoordinates = CLLocationCoordinate2D(
                latitude: latitude, longitude: longitude)
        }
        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(handleMapTap(_:)))
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        mapView.addGestureRecognizer(tapGesture)

        // state setup
        preZoomLevel = zoomLevel()
    }
    
    func view() -> UIView {
        return mapView
    }

    public func handle(
        _ call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
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
                result(self.zoomLevel())
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

        let annotation = Annotation(
            id, latitude: latitude, longitude: longitude)
        // [Platform-specific code | Flutter](https://docs.flutter.dev/platform-integration/platform-channels#codec)
        annotation.image = (args["image"] as? FlutterStandardTypedData).map {
            value in value.data
        }
        annotation.minWidth = args["minWidth"] as? CGFloat
        annotation.minHeight = args["minHeight"] as? CGFloat

        mapView.addAnnotation(annotation)
    }

    func removeMarker(_ call: FlutterMethodCall) {
        guard let id = call.arguments as? String else {
            return
        }

        if let annotation = annotation(withId: id) {
            mapView.removeAnnotation(annotation)
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
            let coordinate = CLLocationCoordinate2D(
                latitude: latitude, longitude: longitude)
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
            if let view = mapView.view(for: annotation) {
                UIView.animate(withDuration: 0.25) {
                    view.alpha = isVisible ? 1 : 0
                }
            }
        }
    }

    func moveCamera(_ call: FlutterMethodCall) {
        guard let args = call.arguments as? [String: Any] else { return }

        let current = mapView.camera
        let latitude =
            args["latitude"] as? Double ?? current.centerCoordinate.latitude
        let longitude =
            args["longitude"] as? Double ?? current.centerCoordinate.longitude
        let zoom = args["zoom"] as? Double ?? zoomLevel()
        let heading = args["heading"] as? Double ?? current.heading
        let animated = args["animated"] as! Bool

        let coordinate = CLLocationCoordinate2D(
            latitude: latitude, longitude: longitude)

        // ズームレベルに応じた距離（赤道での理想値）
        let unadjustedDistance = baseDistance / pow(2, zoom - 2)

        // 中心座標の緯度による補正
        let latFactor = cos(coordinate.latitude * .pi / 180)
        let targetDistanceWithLatitude = unadjustedDistance * latFactor

        // 画面回転によるバウンディングボックスの補正
        // fromDistanceは見える範囲に影響しているらしく、回転時には見える範囲が変わるため係数を掛ける必要がある
        let mapSize = mapView.bounds.size
        let originalWidth = Double(mapSize.width)
        let originalHeight = Double(mapSize.height)
        let angle = heading * .pi / 180.0
        let rotatedWidth =
            abs(cos(angle)) * originalWidth + abs(sin(angle)) * originalHeight
        let correctionFactor = originalWidth / rotatedWidth
        let adjustedDistance = targetDistanceWithLatitude * correctionFactor

        let camera = MKMapCamera(
            lookingAtCenter: coordinate,
            fromDistance: adjustedDistance,
            pitch: current.pitch,
            heading: heading)
        mapView.setCamera(camera, animated: animated)
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
        var latDelta = maxLat - minLat
        var lonDelta = maxLon - minLon

        // 過剰な値を制限
        let maxDelta: Double = 180.0
        latDelta = min(latDelta, maxDelta)
        lonDelta = min(lonDelta, maxDelta)

        // マップのサイズ取得
        let mapWidth = mapView.bounds.size.width
        let mapHeight = mapView.bounds.size.height

        // マップの幅または高さがゼロの場合は処理を中断
        guard mapWidth > 0, mapHeight > 0 else { return }

        // ピクセルベースのパディングを緯度・経度の割合に変換
        let latPadding = (paddingPx / mapHeight) * latDelta
        let lonPadding = (paddingPx / mapWidth) * lonDelta

        let span = MKCoordinateSpan(
            latitudeDelta: latDelta + latPadding,
            longitudeDelta: lonDelta + lonPadding)
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: centerLat, longitude: centerLon), span: span)

        mapView.setRegion(region, animated: true)
    }

    func annotation(withId id: String) -> Annotation? {
        return mapView.annotations.compactMap({ $0 as? Annotation }).first(
            where: { $0.id == id })
    }

    func zoomLevel() -> Double {
        let longitudeDelta = mapView.region.span.longitudeDelta
        let zoomLevel = log2(360 / longitudeDelta)
        // 小数第一位まで
        let roundedZoomLevel = round(10 * zoomLevel) / 10
        return roundedZoomLevel
    }
}

extension NekonataMapView: MKMapViewDelegate {
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        guard !setUpFinished else { return }

        let baseCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        mapView.setCenter(baseCoordinate, zoomLevel: 2, animated: false)

        if #available(iOS 13.0, *) {
            baseDistance = mapView.camera.centerCoordinateDistance
        } else {
            baseDistance = mapView.camera.altitude
        }

        //        debugPrint(baseDistance)

        if let coordinate = initialCoordinates {
            let region = MKCoordinateRegion(
                center: coordinate, latitudinalMeters: 1000,
                longitudinalMeters: 1000)
            mapView.setRegion(region, animated: false)
        }

        setUpFinished = true

        channel.invokeMethod("onMapReady", arguments: nil)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation)
        -> MKAnnotationView?
    {
        guard let annotation = annotation as? Annotation else {
            return nil
        }

        if let view = mapView.dequeueReusableAnnotationView(
            withIdentifier: annotation.id)
        {
            return view
        }

        if annotation.image != nil {
            return ImageAnnotationView(
                annotation: annotation, reuseIdentifier: annotation.id)
        } else {
            return MKMarkerAnnotationView(
                annotation: annotation, reuseIdentifier: annotation.id)
        }
    }

    func mapView(_ mapView: MKMapView, didSelect annotation: MKAnnotation) {
        guard let annotation = annotation as? Annotation else {
            return
        }
        
        // １秒後にdeselect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            mapView.deselectAnnotation(annotation, animated: true)
        }
        
        channel.invokeMethod("onMarkerTapped", arguments: annotation.id)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        guard setUpFinished else { return }
        
        channel.invokeMethod("onCameraMove", arguments: nil)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard setUpFinished else { return }
        
        regionDidChangeWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            let zoomLevel = self.zoomLevel()
            if preZoomLevel != zoomLevel {
                self.channel.invokeMethod("onZoomEnd", arguments: zoomLevel)
                preZoomLevel = zoomLevel
            }
        }

        regionDidChangeWorkItem = workItem
        // 0.2秒後に実行（この間に連続イベントがあればキャンセルされる）
        // Flutter側でUIの処理をする可能性があるので、メインスレッドで実行する
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
}

extension NekonataMapView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch
    )
        -> Bool
    {
        !(touch.view is MKAnnotationView)
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer:
            UIGestureRecognizer
    ) -> Bool {
        true
    }
}

extension NekonataMapView {
    @objc func handleMapTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)

        let arguments: [String: Any] = [
            "latitude": coordinate.latitude,
            "longitude": coordinate.longitude,
        ]
        channel.invokeMethod("onMapTapped", arguments: arguments)
    }
}

extension MKMapView {
    func setCenter(
        _ coordinate: CLLocationCoordinate2D, zoomLevel: Double, animated: Bool
    ) {
        // ズームレベルに基づいて緯度デルタを計算
        let span = MKCoordinateSpan(
            latitudeDelta: 360 / pow(2, zoomLevel),
            longitudeDelta: 360 / pow(2, zoomLevel))
        let region = MKCoordinateRegion(center: coordinate, span: span)
        setRegion(region, animated: animated)
    }
}
