public class Store {
    public static var rawHandle: Int {
        get {
            return UserDefaults.standard.integer(forKey: "rawHandle")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "rawHandle")
        }
    }

    public static var dispatcherRawHandle: Int {
        get {
            return UserDefaults.standard.integer(forKey: "dispatcherRawHandle")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "dispatcherRawHandle")
        }
    }

    public static var isActivated: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "isActivated")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "isActivated")
        }
    }
}
