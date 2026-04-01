import Foundation

/// App-wide persistent settings. Singleton — accessed from AppDelegate, MenuBarController, Monitor.
final class AppSettings: ObservableObject {
    static let shared = AppSettings()

    // Default exclusions — password managers
    static let defaultExclusions: Set<String> = [
        "com.agilebits.onepassword7",
        "com.agilebits.onepassword-osx",
        "com.bitwarden.desktop",
        "com.apple.keychainaccess",
        "com.lastpass.lastpass",
        "com.dashlane.dashlane-osx",
        "com.1password.1password"
    ]

    @Published var excludedBundleIDs: Set<String> {
        didSet { UserDefaults.standard.set(Array(excludedBundleIDs), forKey: Keys.exclusions) }
    }

    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: Keys.sound) }
    }

    /// Set once at first launch — used by LicenseManager (Stage 11) for trial countdown.
    let firstLaunchDate: Date

    private enum Keys {
        static let exclusions = "excludedBundleIDs"
        static let sound      = "soundEnabled"
        static let launch     = "firstLaunchDate"
    }

    private init() {
        let ud = UserDefaults.standard

        if let saved = ud.stringArray(forKey: Keys.exclusions) {
            excludedBundleIDs = Set(saved)
        } else {
            excludedBundleIDs = AppSettings.defaultExclusions
        }

        soundEnabled = ud.object(forKey: Keys.sound) as? Bool ?? false

        if let date = ud.object(forKey: Keys.launch) as? Date {
            firstLaunchDate = date
        } else {
            let now = Date()
            ud.set(now, forKey: Keys.launch)
            firstLaunchDate = now
        }
    }
}
