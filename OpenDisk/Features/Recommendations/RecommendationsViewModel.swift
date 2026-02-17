import Foundation
import Combine

@MainActor
final class RecommendationsViewModel: ObservableObject {
    @Published private(set) var state = RecommendationsViewState(
        profile: nil,
        recommendations: [],
        isLoading: false,
        usedCachedResults: false,
        errorMessage: nil
    )

    private let profileService: ProfileInferenceServiceProtocol
    private let semanticDetector: SemanticUnitDetectorProtocol
    private let ranker: RecommendationRankerProtocol
    private let metadataDiscovery: MetadataDiscoveryServiceProtocol
    private let cacheStore: RecommendationsCacheStoreProtocol

    init(container: AppContainer) {
        self.profileService = container.profileInferenceService
        self.semanticDetector = container.semanticUnitDetector
        self.ranker = container.recommendationRanker
        self.metadataDiscovery = container.metadataDiscoveryService
        self.cacheStore = container.recommendationsCacheStore
    }

    func load(apps: [InstalledApp], scope: ScanScope) async {
        state.isLoading = true
        state.usedCachedResults = false
        state.errorMessage = nil

        let rootURL: URL
        switch scope {
        case .home:
            rootURL = URL(fileURLWithPath: NSHomeDirectory())
        case .applications:
            rootURL = URL(fileURLWithPath: "/Applications")
        case .fullDisk:
            rootURL = URL(fileURLWithPath: "/")
        }

        let cacheKey = makeCacheKey(apps: apps, scope: scope, rootURL: rootURL)
        if let cached = await cacheStore.load(key: cacheKey, maxAge: 60 * 20) {
            state.profile = cached.profile
            state.recommendations = cached.recommendations
            state.isLoading = false
            state.usedCachedResults = true
            return
        }

        let metadata = await metadataDiscovery.collectMetadata(in: rootURL, maxDepth: 5, maxSamples: 2_500)
        let profile = await profileService.inferProfile(apps: apps, metadata: metadata)
        let units = await semanticDetector.detectUnits(in: rootURL)
        let recommendations = ranker.rank(profile: profile, apps: apps, semanticUnits: units)

        await cacheStore.save(
            entry: RecommendationsCacheEntry(
                key: cacheKey,
                createdAt: Date(),
                profile: profile,
                recommendations: recommendations
            )
        )

        state.profile = profile
        state.recommendations = recommendations
        state.isLoading = false
    }

    private func makeCacheKey(apps: [InstalledApp], scope: ScanScope, rootURL: URL) -> String {
        let signature = apps
            .sorted(by: { $0.id < $1.id })
            .map { "\($0.id):\($0.trueSizeBytes)" }
            .joined(separator: "|")
        return "\(scope.rawValue)|\(rootURL.path)|\(signature)"
    }
}
