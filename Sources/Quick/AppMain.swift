import SwiftUI

@main
struct QuickApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(QuickAppModel.shared)
        }
    }
}
