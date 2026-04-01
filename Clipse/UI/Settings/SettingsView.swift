import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @State private var launchAtLogin: Bool = (SMAppService.mainApp.status == .enabled)
    @State private var newExclusion: String = ""

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

                Toggle("Sound Feedback", isOn: $settings.soundEnabled)
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
                    Text("Trial — 14 days").foregroundStyle(.orange)
                }
                Button("Unlock Pro — $9.99") {}
                    .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420, height: 320)
    }
}
