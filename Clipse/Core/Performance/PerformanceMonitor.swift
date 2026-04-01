import os.log

enum PerformanceMonitor {
    private static let signpostLog = OSLog(subsystem: "com.clipse.app", category: .pointsOfInterest)
    private static let perfLog     = OSLog(subsystem: "com.clipse.app", category: "Performance")

    // Wall-clock start times for interval measurements
    private static var hotkeyFiredAt: UInt64 = 0
    private static var searchStartedAt: UInt64 = 0

    // MARK: - Hotkey → visible

    /// Call when hotkey fires (before panel appears)
    static func hotkeyFired() {
        hotkeyFiredAt = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        os_signpost(.begin, log: signpostLog, name: "hotkey-to-visible")
    }

    /// Call after panel.orderFront — UI is on screen
    static func panelDidAppear() {
        os_signpost(.end, log: signpostLog, name: "hotkey-to-visible")
        guard hotkeyFiredAt > 0 else { return }
        let ms = Double(clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) - hotkeyFiredAt) / 1_000_000
        os_log("⚡ hotkey→visible: %.1f ms", log: perfLog, type: .info, ms)
        hotkeyFiredAt = 0
    }

    // MARK: - Search

    /// Call before FuzzySearch.filter
    static func searchBegin() {
        searchStartedAt = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        os_signpost(.begin, log: signpostLog, name: "fuzzy-search")
    }

    /// Call after FuzzySearch.filter returns
    static func searchEnd(itemCount: Int, resultCount: Int) {
        os_signpost(.end, log: signpostLog, name: "fuzzy-search")
        guard searchStartedAt > 0 else { return }
        let µs = Double(clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW) - searchStartedAt) / 1_000
        os_log("🔍 search: %.0f µs — %{public}d/%{public}d items", log: perfLog, type: .info, µs, resultCount, itemCount)
        searchStartedAt = 0
    }

    // MARK: - Paste

    static func pasteBegin() {
        os_signpost(.begin, log: signpostLog, name: "paste")
    }

    static func pasteEnd() {
        os_signpost(.end, log: signpostLog, name: "paste")
    }

    // MARK: - Clipboard monitor

    /// Log a new item being captured
    static func clipboardCaptured(type: String, contentLength: Int) {
        os_log("📋 captured: type=%{public}@ len=%{public}d", log: perfLog, type: .info, type, contentLength)
    }
}
