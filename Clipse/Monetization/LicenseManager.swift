import Foundation

enum LicenseStatus: Equatable {
    case trial(daysLeft: Int)
    case free
    case pro
}

final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    @Published private(set) var status: LicenseStatus

    /// Debug override — set true in Settings to simulate Pro without purchase
    @Published var debugProOverride: Bool = false {
        didSet { UserDefaults.standard.set(debugProOverride, forKey: "debugProOverride") }
    }

    /// True during trial OR after purchase — used by ClipboardStore.isPro closure
    var isPro: Bool {
        if debugProOverride { return true }
        switch status {
        case .pro, .trial: return true
        case .free: return false
        }
    }

    private enum Keys {
        static let licensed = "isProLicensed"
    }

    private init() {
        status = LicenseManager.computeStatus()
        debugProOverride = UserDefaults.standard.bool(forKey: "debugProOverride")
    }

    /// Refresh status — call on applicationDidBecomeActive to keep trial countdown current
    func refresh() {
        status = LicenseManager.computeStatus()
    }

    /// Called after successful StoreKit purchase (Stage 16)
    func unlock() {
        UserDefaults.standard.set(true, forKey: Keys.licensed)
        status = .pro
    }

    // MARK: - Private

    private static func computeStatus() -> LicenseStatus {
        if UserDefaults.standard.bool(forKey: Keys.licensed) { return .pro }
        let first = AppSettings.shared.firstLaunchDate
        let days = Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 0
        let left = max(0, 14 - days)
        return left > 0 ? .trial(daysLeft: left) : .free
    }
}
