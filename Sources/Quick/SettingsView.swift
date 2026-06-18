import SwiftUI
import QuickCore

struct SettingsView: View {
    @EnvironmentObject private var model: QuickAppModel

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Quick Settings")
                        .font(.title2)
                        .fontWeight(.semibold)

                    settingsGroup("OpenAI") {
                        LabeledContent("API Key") {
                            SecureField("sk-...", text: $model.apiKey)
                                .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("Base URL") {
                            TextField(
                                "https://api.openai.com",
                                text: Binding(
                                    get: { model.settings.baseURL },
                                    set: { model.settings.baseURL = $0 }
                                )
                            )
                            .textFieldStyle(.roundedBorder)
                        }

                        LabeledContent("Model") {
                            TextField(
                                "gpt-5.4-mini",
                                text: Binding(
                                    get: { model.settings.model },
                                    set: { model.settings.model = $0 }
                                )
                            )
                            .textFieldStyle(.roundedBorder)
                        }

                        Text("For OpenAI-compatible providers, enter the provider root URL or /v1 URL. Quick will call /v1/responses.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    settingsGroup("Translation") {
                        Text("System Prompt")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        TextField(
                            "You are a translation assistant...",
                            text: Binding(
                                get: { model.settings.systemPrompt },
                                set: { model.settings.systemPrompt = $0 }
                            ),
                            axis: .vertical
                        )
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)

                        Text("This is sent as the OpenAI Responses API instructions field. The source text is sent separately as input.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("Double-copy interval")
                                .frame(width: 150, alignment: .leading)
                            Slider(
                                value: Binding(
                                    get: { model.settings.doubleCopyInterval },
                                    set: { model.settings.doubleCopyInterval = $0 }
                                ),
                                in: 0.3...1.5,
                                step: 0.1
                            )
                            Text("\(model.settings.doubleCopyInterval, specifier: "%.1f")s")
                                .monospacedDigit()
                                .frame(width: 42, alignment: .trailing)
                        }
                    }

                    settingsGroup("Shortcut") {
                        Text("Default: press cmd+c+c to translate the current selection.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Toggle(
                            "Enable custom single shortcut",
                            isOn: Binding(
                                get: { model.settings.customShortcutEnabled },
                                set: { model.settings.customShortcutEnabled = $0 }
                            )
                        )

                        HStack {
                            Toggle(
                                "Command",
                                isOn: Binding(
                                    get: { model.settings.customShortcutCommand },
                                    set: { model.settings.customShortcutCommand = $0 }
                                )
                            )
                            Toggle(
                                "Shift",
                                isOn: Binding(
                                    get: { model.settings.customShortcutShift },
                                    set: { model.settings.customShortcutShift = $0 }
                                )
                            )
                            Toggle(
                                "Option",
                                isOn: Binding(
                                    get: { model.settings.customShortcutOption },
                                    set: { model.settings.customShortcutOption = $0 }
                                )
                            )
                            Toggle(
                                "Control",
                                isOn: Binding(
                                    get: { model.settings.customShortcutControl },
                                    set: { model.settings.customShortcutControl = $0 }
                                )
                            )
                        }

                        HStack {
                            Text("Key")
                                .frame(width: 150, alignment: .leading)
                            TextField(
                                "t",
                                text: Binding(
                                    get: { model.settings.customShortcutKey },
                                    set: { model.settings.customShortcutKey = String($0.lowercased().prefix(1)) }
                                )
                            )
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)

                            Text("Custom shortcut copies selection first, then translates.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    settingsGroup("Permissions") {
                        Text("Default cmd+c+c does not need keyboard permissions. Input Monitoring and Accessibility are only needed for custom shortcuts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack {
                            Button("Open Accessibility") {
                                openSystemSettings("Privacy_Accessibility")
                            }

                            Button("Open Input Monitoring") {
                                openSystemSettings("Privacy_ListenEvent")
                            }
                        }
                    }
                }
                .padding(22)
            }

            Divider()

            HStack {
                Button("Save") {
                    model.saveSettings()
                }
                .keyboardShortcut(.defaultAction)

                Text(model.statusMessage)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                Spacer()
            }
            .padding(16)
        }
        .frame(width: 560, height: 620)
    }

    @ViewBuilder
    private func settingsGroup<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func openSystemSettings(_ pane: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
