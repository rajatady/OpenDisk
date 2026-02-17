import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

final class AICapabilityService: AICapabilityServiceProtocol {
    private let environment: [String: String]

    init(processInfo: ProcessInfo = .processInfo, environmentOverride: [String: String]? = nil) {
        self.environment = environmentOverride ?? processInfo.environment
    }

    func capabilityStatus() -> AICapabilityStatus {
        if let forced = environment["OPENDISK_AI_SUPPORTED"] {
            return forced == "1"
                ? .supported
                : .unsupported(reason: "Apple Intelligence support is required by this build policy.")
        }

        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            if model.isAvailable {
                return .supported
            }

            switch model.availability {
            case .available:
                return .supported
            case .unavailable(let reason):
                return .unsupported(reason: "Apple Intelligence unavailable: \(reasonDescription(reason)).")
            @unknown default:
                return .unsupported(reason: "Apple Intelligence unavailable for an unknown reason.")
            }
        }

        return .unsupported(reason: "Foundation Models requires macOS 26 or newer.")
        #else
        return .unsupported(reason: "Foundation Models framework is unavailable. OpenDisk requires Apple Intelligence support.")
        #endif
    }

    #if canImport(FoundationModels)
    @available(macOS 26.0, *)
    private func reasonDescription(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "device not eligible"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence is not enabled in system settings"
        case .modelNotReady:
            return "model assets are not ready"
        @unknown default:
            return "unknown condition"
        }
    }
    #endif
}
