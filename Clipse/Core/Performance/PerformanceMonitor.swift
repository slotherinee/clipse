import os.log

/// os_signpost markers for Instruments — zero overhead in release builds (os_log is optimized away).
enum PerformanceMonitor {
    private static let log = OSLog(subsystem: "com.clipse.app", category: .pointsOfInterest)

    /// Call when hotkey is recognized in CGEventTap callback
    static func hotkeyFired() {
        os_signpost(.begin, log: log, name: "hotkey-to-visible")
    }

    /// Call after panel.orderFront — UI is now on screen
    static func panelDidAppear() {
        os_signpost(.end, log: log, name: "hotkey-to-visible")
    }

    /// Wrap FuzzySearch.filter calls to measure search latency
    static func searchBegin() {
        os_signpost(.begin, log: log, name: "fuzzy-search")
    }

    static func searchEnd() {
        os_signpost(.end, log: log, name: "fuzzy-search")
    }
}
