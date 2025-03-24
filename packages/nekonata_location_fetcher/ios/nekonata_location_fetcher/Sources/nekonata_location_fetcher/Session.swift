import CoreLocation

@available(iOS 17.0, *)
class BackgroundActivitySessionManager {
    static private var backgroundActivitySession: CLBackgroundActivitySession?

    public static func activate() {
        guard backgroundActivitySession == nil else {
            debugPrint("Already activated background session")
            return
        }
        debugPrint("Activated background session")
        backgroundActivitySession = CLBackgroundActivitySession()
    }

    public static func invalidate() {
        if let session = backgroundActivitySession {
            session.invalidate()
            backgroundActivitySession = nil
        }
    }
}
