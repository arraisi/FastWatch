import SwiftUI

struct SettingsView: View {
    @Environment(FastingManager.self) private var manager

    var body: some View {
        List {
            Section("Protocol") {
                NavigationLink(destination: ProtocolPickerView()) {
                    LabeledContent("Default") {
                        Text(manager.preferences.defaultProtocol.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
                if manager.preferences.defaultProtocol == .custom {
                    NavigationLink(destination: CustomProtocolView()) {
                        LabeledContent("Custom Hours") {
                            Text("\(Int(manager.preferences.customFastingHours)):\(Int(manager.preferences.customEatingHours))")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Notifications") {
                Toggle("Milestones", isOn: Binding(
                    get: { manager.preferences.notifyOnMilestones },
                    set: { manager.preferences.notifyOnMilestones = $0 }
                ))
                Toggle("Goal Reached", isOn: Binding(
                    get: { manager.preferences.notifyOnGoalReached },
                    set: { manager.preferences.notifyOnGoalReached = $0 }
                ))
                Toggle("Eating Window", isOn: Binding(
                    get: { manager.preferences.notifyEatingWindowEnding },
                    set: { manager.preferences.notifyEatingWindowEnding = $0 }
                ))
            }

            Section("Haptics") {
                Toggle("Enabled", isOn: Binding(
                    get: { manager.preferences.hapticsEnabled },
                    set: { manager.preferences.hapticsEnabled = $0 }
                ))
                if manager.preferences.hapticsEnabled {
                    Picker("Intensity", selection: Binding(
                        get: { manager.preferences.hapticIntensity },
                        set: { manager.preferences.hapticIntensity = $0 }
                    )) {
                        Text("Light").tag(HapticIntensity.light)
                        Text("Strong").tag(HapticIntensity.strong)
                    }
                }
            }

            Section("Overtime") {
                Toggle("Reminder", isOn: Binding(
                    get: { manager.preferences.overtimeReminder },
                    set: { manager.preferences.overtimeReminder = $0 }
                ))
            }

            if manager.healthKitManager.isAvailable {
                Section("Health") {
                    Toggle("Save to Health", isOn: Binding(
                        get: { manager.preferences.healthKitEnabled },
                        set: { newValue in
                            if newValue {
                                manager.healthKitManager.requestAuthorization { granted in
                                    manager.preferences.healthKitEnabled = granted
                                }
                            } else {
                                manager.preferences.healthKitEnabled = false
                            }
                        }
                    ))
                    if manager.preferences.healthKitEnabled {
                        Text("Fasts saved as Mindful Sessions")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview("Settings") {
    NavigationStack {
        SettingsView()
    }
    .environment(FastingManager())
}
