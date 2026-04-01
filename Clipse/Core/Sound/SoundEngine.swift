import AppKit

/// Stateless sound playback. Bool guard checked first — zero cost when disabled.
enum SoundEngine {

    static func playTick() {
        guard AppSettings.shared.soundEnabled else { return }
        NSSound(named: "Tink")?.play()
    }

    static func playWhoosh() {
        guard AppSettings.shared.soundEnabled else { return }
        NSSound(named: "Pop")?.play()
    }
}
