import SwiftUI
import AppKit

final class OdakAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Refresh the running app's Dock icon even when Launch Services has
        // retained the placeholder from an earlier development build.
        guard let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
              let icon = NSImage(contentsOf: iconURL) else { return }
        NSApplication.shared.applicationIconImage = icon
    }
}

@main
struct ios_testApp: App {
    @NSApplicationDelegateAdaptor(OdakAppDelegate.self) private var appDelegate
    @StateObject private var store = TaskStore()

    var body: some Scene {
        WindowGroup("Odak") {
            ContentView()
                .environmentObject(store)
                .environment(\.locale, Locale(identifier: "tr_TR"))
        }
        .defaultSize(width: 1000, height: 740)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
    }
}
