struct UserDefaultsKeys {
    static let rawHandle = "rawHandle"
    static let dispatcherRawHandle = "dispatcherRawHandle"
    static let isActivated = "isActivated"
    static let useCLServiceSession = "useCLServiceSession"
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
    @UserDefault(key: UserDefaultsKeys.rawHandle, defaultValue: 0)
    public static var rawHandle: Int

    @UserDefault(key: UserDefaultsKeys.dispatcherRawHandle, defaultValue: 0)
    public static var dispatcherRawHandle: Int

    @UserDefault(key: UserDefaultsKeys.isActivated, defaultValue: false)
    public static var isActivated: Bool

    @UserDefault(key: UserDefaultsKeys.useCLServiceSession, defaultValue: true)
    public static var useCLServiceSession: Bool

    @UserDefault(key: UserDefaultsKeys.distanceFilter, defaultValue: 10.0)
    public static var distanceFilter: Double

    @UserDefault(key: UserDefaultsKeys.interval, defaultValue: 5)
    public static var interval: Int
}
