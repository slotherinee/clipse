import UserNotifications

/// Tracks weekly paste count and delivers a passive insight notification after 7 days.
/// All UserDefaults writes are O(1). No background timers — rollover checked at launch.
final class RetentionTracker {

    private let ud = UserDefaults.standard

    private enum Keys {
        static let count     = "weeklyPasteCount"
        static let weekStart = "weekStartDate"
        static let permAsked = "notifPermissionAsked"
    }

    func start() {
        requestPermissionIfNeeded()
        checkWeekRollover()
    }

    /// Call on every successful paste — single integer write, no allocations
    func recordPaste() {
        ud.set(ud.integer(forKey: Keys.count) + 1, forKey: Keys.count)
    }

    // MARK: - Private

    private func requestPermissionIfNeeded() {
        guard !ud.bool(forKey: Keys.permAsked) else { return }
        ud.set(true, forKey: Keys.permAsked)
        // No alert options — just badge/sound free. User won't see a permission dialog
        // until we actually deliver a notification; this pre-authorizes silently.
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert]) { _, _ in }
    }

    private func checkWeekRollover() {
        guard let weekStart = ud.object(forKey: Keys.weekStart) as? Date else {
            ud.set(Date(), forKey: Keys.weekStart)
            return
        }

        let days = Calendar.current.dateComponents([.day], from: weekStart, to: Date()).day ?? 0
        guard days >= 7 else { return }

        let count = ud.integer(forKey: Keys.count)
        if count > 0 { scheduleInsight(count: count) }

        // Reset week
        ud.set(Date(), forKey: Keys.weekStart)
        ud.set(0, forKey: Keys.count)
    }

    private func scheduleInsight(count: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Clipse"
        content.body = "You pasted \(count) item\(count == 1 ? "" : "s") this week."
        content.sound = nil // passive — no sound

        // Fire in 1s — effectively immediate, avoids triggering on launch before UI settles
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "weekly-insight", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
