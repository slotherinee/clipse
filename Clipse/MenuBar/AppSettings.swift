import Foundation
import SwiftUI

// MARK: - Panel Theme

enum PanelTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

// MARK: - Glow Color

enum GlowColor: String, CaseIterable, Identifiable {
    case white   = "white"
    case blue    = "blue"
    case purple  = "purple"
    case pink    = "pink"
    case red     = "red"
    case orange  = "orange"
    case yellow  = "yellow"
    case green   = "green"
    case teal    = "teal"
    case indigo  = "indigo"
    case gold    = "gold"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .white:  return "White"
        case .blue:   return "Blue"
        case .purple: return "Purple"
        case .pink:   return "Pink"
        case .red:    return "Red"
        case .orange: return "Orange"
        case .yellow: return "Yellow"
        case .green:  return "Green"
        case .teal:   return "Teal"
        case .indigo: return "Indigo"
        case .gold:   return "Gold"
        }
    }

    /// Primary glow color, matching macOS system palette
    var color: Color {
        switch self {
        case .white:  return Color(white: 0.95)
        case .blue:   return Color(red: 0.0,  green: 0.48, blue: 1.0)  // macOS blue
        case .purple: return Color(red: 0.68, green: 0.32, blue: 0.87) // macOS purple
        case .pink:   return Color(red: 1.0,  green: 0.18, blue: 0.57) // macOS pink
        case .red:    return Color(red: 1.0,  green: 0.23, blue: 0.19) // macOS red
        case .orange: return Color(red: 1.0,  green: 0.58, blue: 0.0)  // macOS orange
        case .yellow: return Color(red: 1.0,  green: 0.80, blue: 0.0)  // macOS yellow
        case .green:  return Color(red: 0.20, green: 0.78, blue: 0.35) // macOS green
        case .teal:   return Color(red: 0.35, green: 0.78, blue: 0.78)
        case .indigo: return Color(red: 0.37, green: 0.36, blue: 0.90)
        case .gold:   return Color(red: 1.0,  green: 0.71, blue: 0.30)
        }
    }
}

// MARK: - AppSettings

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

    @Published var glowColor: GlowColor {
        didSet { UserDefaults.standard.set(glowColor.rawValue, forKey: Keys.glowColor) }
    }

    @Published var closeOnFocusLoss: Bool {
        didSet { UserDefaults.standard.set(closeOnFocusLoss, forKey: Keys.closeOnFocusLoss) }
    }

    @Published var panelTheme: PanelTheme {
        didSet { UserDefaults.standard.set(panelTheme.rawValue, forKey: Keys.panelTheme) }
    }

    /// Set once at first launch — used by LicenseManager for trial countdown.
    let firstLaunchDate: Date

    private enum Keys {
        static let exclusions      = "excludedBundleIDs"
        static let sound           = "soundEnabled"
        static let launch          = "firstLaunchDate"
        static let glowColor       = "glowColor"
        static let closeOnFocusLoss = "closeOnFocusLoss"
        static let panelTheme       = "panelTheme"
    }

    private init() {
        let ud = UserDefaults.standard

        if let saved = ud.stringArray(forKey: Keys.exclusions) {
            excludedBundleIDs = Set(saved)
        } else {
            excludedBundleIDs = AppSettings.defaultExclusions
        }

        soundEnabled = ud.object(forKey: Keys.sound) as? Bool ?? false

        if let raw = ud.string(forKey: Keys.glowColor), let c = GlowColor(rawValue: raw) {
            glowColor = c
        } else {
            glowColor = .teal
        }

        closeOnFocusLoss = ud.object(forKey: Keys.closeOnFocusLoss) as? Bool ?? true

        if let raw = ud.string(forKey: Keys.panelTheme), let t = PanelTheme(rawValue: raw) {
            panelTheme = t
        } else {
            panelTheme = .system
        }

        if let date = ud.object(forKey: Keys.launch) as? Date {
            firstLaunchDate = date
        } else {
            let now = Date()
            ud.set(now, forKey: Keys.launch)
            firstLaunchDate = now
        }
    }
}
