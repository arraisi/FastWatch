import SwiftUI

struct ProtocolPickerView: View {
    @Environment(FastingManager.self) private var manager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            ForEach(FastingProtocol.allCases) { proto in
                if proto == .custom {
                    customRow
                } else {
                    protocolRow(proto)
                }
            }
        }
        .navigationTitle("Protocol")
    }

    private func protocolRow(_ proto: FastingProtocol) -> some View {
        Button {
            manager.preferences.defaultProtocol = proto
            dismiss()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(proto.displayName)
                        .font(.headline)
                    Text(proto.shortDescription)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if manager.preferences.defaultProtocol == proto {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.green)
                }
            }
        }
    }

    private var customRow: some View {
        Button {
            manager.preferences.defaultProtocol = .custom
            dismiss()
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Custom")
                        .font(.headline)
                    Spacer()
                    if manager.preferences.defaultProtocol == .custom {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.green)
                    }
                }

                HStack {
                    Text("Fast")
                        .font(.caption2)
                    Spacer()
                    Text("\(Int(manager.preferences.customFastingHours))h")
                        .font(.caption)
                        .monospacedDigit()
                }

                HStack {
                    Text("Eat")
                        .font(.caption2)
                    Spacer()
                    Text("\(Int(manager.preferences.customEatingHours))h")
                        .font(.caption)
                        .monospacedDigit()
                }
            }
        }
    }
}

#Preview("Protocol Picker") {
    NavigationStack {
        ProtocolPickerView()
    }
    .environment(FastingManager())
}

struct CustomProtocolView: View {
    @Environment(FastingManager.self) private var manager

    var body: some View {
        @Bindable var mgr = manager
        List {
            Section("Fasting Hours") {
                Stepper(
                    "\(Int(manager.preferences.customFastingHours))h",
                    value: Binding(
                        get: { manager.preferences.customFastingHours },
                        set: { manager.preferences.customFastingHours = $0 }
                    ),
                    in: 1...72,
                    step: 1
                )
            }
            Section("Eating Hours") {
                Stepper(
                    "\(Int(manager.preferences.customEatingHours))h",
                    value: Binding(
                        get: { manager.preferences.customEatingHours },
                        set: { manager.preferences.customEatingHours = $0 }
                    ),
                    in: 0...24,
                    step: 1
                )
            }
        }
        .navigationTitle("Custom")
    }
}

#Preview("Custom Protocol") {
    NavigationStack {
        CustomProtocolView()
    }
    .environment(FastingManager())
}
