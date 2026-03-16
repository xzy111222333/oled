import Foundation

enum SharedStoreKey {
    static let appGroup = "group.com.example.OLEDGuard"
    static let state = "oledguard.app.state"
}

struct SharedStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(suiteName: String = SharedStoreKey.appGroup) {
        self.defaults = UserDefaults(suiteName: suiteName) ?? .standard
    }

    func load() -> AppState {
        guard let data = defaults.data(forKey: SharedStoreKey.state),
              let state = try? decoder.decode(AppState.self, from: data) else {
            return .default
        }
        return state
    }

    func save(_ state: AppState) {
        guard let data = try? encoder.encode(state) else { return }
        defaults.set(data, forKey: SharedStoreKey.state)
    }
}
