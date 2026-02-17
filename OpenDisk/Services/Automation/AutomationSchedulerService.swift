import Foundation

actor AutomationSchedulerService: AutomationSchedulerProtocol {
    private(set) var rules: [AutomationRule] = []

    func schedule(rules: [AutomationRule]) async {
        self.rules = rules
    }
}
