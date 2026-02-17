import SwiftUI

@main
struct OpenDiskApp: App {
    private let container = AppContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView(container: container)
                .frame(minWidth: 1180, minHeight: 760)
        }
        .windowResizability(.contentSize)
    }
}
