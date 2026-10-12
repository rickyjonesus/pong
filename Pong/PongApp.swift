import SwiftUI

@main
struct PongApp: App {
    @StateObject private var themes = ThemeStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.theme, themes.current)
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}
