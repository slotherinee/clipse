import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject private var license = LicenseManager.shared
    @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)
    @State private var newExclusion: String = ""
    @State private var glowColor: GlowColor = AppSettings.shared.glowColor

    var body: some View {
        Form {
            Section("General") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        // SMAppService can be slow — run off main thread
                        DispatchQueue.global(qos: .userInitiated).async {
                            if enabled {
                                try? SMAppService.mainApp.register()
                            } else {
                                try? SMAppService.mainApp.unregister()
                            }
                        }
                    }
                Toggle("Close panel on focus loss", isOn: $settings.closeOnFocusLoss)
                Picker("Appearance", selection: $settings.panelTheme) {
                    ForEach(PanelTheme.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .fixedSize(horizontal: true, vertical: false)
            }

            Section("App Exclusions") {
                ForEach(Array(settings.excludedBundleIDs).sorted(), id: \.self) { bundleID in
                    HStack {
                        Text(bundleID).font(.system(size: 12, design: .monospaced))
                        Spacer()
                        Button("Remove") { settings.excludedBundleIDs.remove(bundleID) }
                            .buttonStyle(.borderless)
                            .foregroundStyle(.red)
                    }
                }

                HStack {
                    TextField("com.example.app", text: $newExclusion)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        let trimmed = newExclusion.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        settings.excludedBundleIDs.insert(trimmed)
                        newExclusion = ""
                    }
                    .disabled(newExclusion.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Pro") {
                HStack {
                    Text("Status").foregroundStyle(.secondary)
                    Spacer()
                    licenseStatusText
                }
                Toggle("Enable Pro (debug)", isOn: $license.debugProOverride)
                    .foregroundStyle(.secondary)
                if license.isPro {
                    Picker("Glow Color", selection: $glowColor) {
                        ForEach(GlowColor.allCases) { color in
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 10, height: 10)
                                Text(color.label)
                            }
                            .tag(color)
                        }
                    }
                    .onChange(of: glowColor) { settings.glowColor = $0 }
                }
                if case .pro = license.status {} else {
                    Button("Unlock Pro — $9.99") { LicenseManager.shared.unlock() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 520, height: 480)
    }

    @ViewBuilder private var licenseStatusText: some View {
        switch license.status {
        case .pro:
            Text("Pro").foregroundStyle(.green)
        case .trial(let days):
            Text("Trial — \(days) day\(days == 1 ? "" : "s") left").foregroundStyle(.orange)
        case .free:
            Text("Free").foregroundStyle(.secondary)
        }
    }
}
