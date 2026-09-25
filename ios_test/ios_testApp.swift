import SwiftUI

@main
struct ios_testApp: App {
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
