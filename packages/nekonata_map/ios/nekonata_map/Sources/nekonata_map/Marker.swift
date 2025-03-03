import Flutter
import ImageIO
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

class ImageAnnotationView: MKAnnotationView {
    private var imageView: UIImageView!

    init(annotation: Annotation, reuseIdentifier: String) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        guard let data = annotation.image else { return }

        let originalImage: UIImage?
        if data.isGIFData {
            originalImage = UIImage.animatedImage(data: data)
        } else {
            originalImage = UIImage(data: data)
        }

        if let originalImage = originalImage {
            imageView = UIImageView(image: originalImage)
            imageView.contentMode = .scaleAspectFit
            
            let width = annotation.minWidth ?? originalImage.size.width
            let height = annotation.minHeight ?? originalImage.size.height
            
            imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            self.frame = imageView.frame
            
            if let animatedImage = originalImage.images {
                imageView.animationImages = animatedImage
                imageView.animationDuration = originalImage.duration
                imageView.startAnimating()
            }

            addSubview(imageView)

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

    deinit {
        imageView?.stopAnimating()
    }
}

extension UIImage {
    static func animatedImage(data: Data) -> UIImage? {
        let options: [CFString: Any] = [kCGImageSourceShouldCache: false]
        guard let source = CGImageSourceCreateWithData(data as CFData, options as CFDictionary)
        else {
            return nil
        }
        let frameCount = CGImageSourceGetCount(source)
        var images = [UIImage]()
        var duration: TimeInterval = 0.0

        for i in 0..<frameCount {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, options as CFDictionary) {
                let frame = UIImage(cgImage: cgImage)
                images.append(frame)
                duration += UIImage.delayForImage(at: i, source: source)
            }
        }

        // durationが0の場合はデフォルト値
        if duration == 0 {
            duration = Double(frameCount) * 0.1
        }
        return UIImage.animatedImage(with: images, duration: duration)
    }

    private static func delayForImage(at index: Int, source: CGImageSource) -> TimeInterval {
        var delay = 0.1
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        if let gifProperties = (cfProperties as NSDictionary?)?[
            kCGImagePropertyGIFDictionary as String] as? NSDictionary
        {
            if let unclampedDelay = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String]
                as? NSNumber
            {
                delay = unclampedDelay.doubleValue
            } else if let clampedDelay = gifProperties[kCGImagePropertyGIFDelayTime as String]
                as? NSNumber
            {
                delay = clampedDelay.doubleValue
            }
        }
        // 最小値の調整
        if delay < 0.1 {
            delay = 0.1
        }
        return delay
    }
}

extension Data {
    var isGIFData: Bool {
        return self.starts(with: [0x47, 0x49, 0x46, 0x38, 0x39, 0x61])
            || self.starts(with: [0x47, 0x49, 0x46, 0x38, 0x37, 0x61])
    }
}
