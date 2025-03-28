import CoreLocation

@available(iOS 17.0, *)
class BackgroundActivitySessionManager {
    static private var backgroundActivitySession: CLBackgroundActivitySession?

    public static func activate() {
        invalidate()
        
        if Store.useBackgroundActivitySessionManager {
            NSLog("🐱 Activated background session")
            backgroundActivitySession = CLBackgroundActivitySession()
        }
    }

    public static func invalidate() {
        if let session = backgroundActivitySession {
            session.invalidate()
            backgroundActivitySession = nil
        }
    }
}
