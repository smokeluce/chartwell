import Foundation

final class Settings {
    static let shared = Settings()
    private let d = UserDefaults.standard

    var useRecordsName: Bool {
        get { return (d.object(forKey: "useRecordsName") as? Bool) ?? true }
        set { d.set(newValue, forKey: "useRecordsName") }
    }

    var customName: String {
        get { return d.string(forKey: "customName") ?? "" }
        set { d.set(newValue, forKey: "customName") }
    }
}
