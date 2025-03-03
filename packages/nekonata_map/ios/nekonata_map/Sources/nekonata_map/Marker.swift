import Flutter
import MapKit

class Annotation: NSObject, MKAnnotation {
    let id: String
    @objc dynamic var coordinate: CLLocationCoordinate2D
    var minWidth: CGFloat?
    var minHeight: CGFloat?
    var image: Data?

    init(_ id: String, latitude: Double, longitude: Double) {
        self.id = id
        self.coordinate = CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude
        )
    }
}

class FlutterWidgetAnnotationView: MKAnnotationView {
    init(annotation: Annotation, reuseIdentifier: String) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        if let data = annotation.image,
            let originalImage = UIImage(data: data)
        {
            self.image = originalImage.resized(
                minWidth: annotation.minWidth, minHeight: annotation.minHeight)

            if #available(iOS 16.0, *) {
                anchorPoint = CGPoint(x: 0.5, y: 1.0)
            } else {
                centerOffset = CGPoint(x: 0, y: -self.image!.size.height / 2)
            }
        }

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIImage {
    func resized(minWidth: CGFloat? = nil, minHeight: CGFloat? = nil) -> UIImage? {
        guard minWidth != nil || minHeight != nil else {
            return self
        }

        var scaleFactor: CGFloat = 1.0

        if let minWidth = minWidth, let minHeight = minHeight {
            let widthScale = minWidth / self.size.width
            let heightScale = minHeight / self.size.height
            scaleFactor = max(widthScale, heightScale)
        } else if let minWidth = minWidth {
            scaleFactor = minWidth / self.size.width
        } else if let minHeight = minHeight {
            scaleFactor = minHeight / self.size.height
        }

        let newSize = CGSize(
            width: self.size.width * scaleFactor,
            height: self.size.height * scaleFactor)

        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}
