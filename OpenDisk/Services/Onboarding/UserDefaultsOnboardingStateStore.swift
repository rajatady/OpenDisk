import Foundation

final class UserDefaultsOnboardingStateStore: OnboardingStateStoreProtocol {
    private enum Keys {
        static let completed = "onboarding.completed"
        static let lastCompletedAt = "onboarding.lastCompletedAt"
        static let selectedScope = "onboarding.selectedScope"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults) {
        self.defaults = defaults
    }

    var isCompleted: Bool {
        get { defaults.bool(forKey: Keys.completed) }
        set { defaults.set(newValue, forKey: Keys.completed) }
    }

    var lastCompletedAt: Date? {
        get { defaults.object(forKey: Keys.lastCompletedAt) as? Date }
        set { defaults.set(newValue, forKey: Keys.lastCompletedAt) }
    }

    var selectedScope: ScanScope {
        get {
            guard
                let raw = defaults.string(forKey: Keys.selectedScope),
                let value = ScanScope(rawValue: raw)
            else {
                return .applications
            }
            return value
        }
        set { defaults.set(newValue.rawValue, forKey: Keys.selectedScope) }
    }
}
