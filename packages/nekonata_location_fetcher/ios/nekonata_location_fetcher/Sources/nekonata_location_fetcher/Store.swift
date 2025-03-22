/// プラットフォーム間のKeyとして扱っているので、変更する際は十分に注意すること
/// 便宜上、UserDefaultsに保存する際のKeyと同名にしている
struct Keys {
    static let rawHandle = "rawHandle"
    static let dispatcherRawHandle = "dispatcherRawHandle"
    static let isActivated = "isActivated"
    static let useCLLocationUpdate = "useCLLocationUpdate"
    static let useBackgroundActivitySessionManager = "useBackgroundActivitySessionManager"
    static let distanceFilter: String = "distanceFilter"
    static let interval: String = "interval"
}

@propertyWrapper
internal struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

internal class Store {
    @UserDefault(key: Keys.rawHandle, defaultValue: 0)
    public static var rawHandle: Int

    @UserDefault(key: Keys.dispatcherRawHandle, defaultValue: 0)
    public static var dispatcherRawHandle: Int

    @UserDefault(key: Keys.isActivated, defaultValue: false)
    public static var isActivated: Bool

    @UserDefault(key: Keys.useCLLocationUpdate, defaultValue: true)
    public static var useCLLocationUpdate: Bool
    
    @UserDefault(key: Keys.useBackgroundActivitySessionManager, defaultValue: true)
    public static var useBackgroundActivitySessionManager: Bool

    @UserDefault(key: Keys.distanceFilter, defaultValue: 10.0)
    public static var distanceFilter: Double

    @UserDefault(key: Keys.interval, defaultValue: 5)
    public static var interval: Int
}
