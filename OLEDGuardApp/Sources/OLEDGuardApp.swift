import SwiftUI

@main
struct OLEDGuardApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .preferredColorScheme(.light)
                .task {
                    model.handleScenePhaseChange(.active)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            model.handleScenePhaseChange(phase)
        }
    }
}
