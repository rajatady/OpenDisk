import SwiftUI

struct RootView: View {
    @StateObject private var viewModel: RootViewModel

    init(container: AppContainer) {
        _viewModel = StateObject(wrappedValue: RootViewModel(container: container))
    }

    var body: some View {
        ZStack {
            if viewModel.shouldShowOnboarding {
                OnboardingView(viewModel: viewModel.onboardingViewModel) {
                    Task { await viewModel.completeOnboarding() }
                }
                .transition(.asymmetric(
                    insertion: .opacity,
                    removal: .opacity.combined(with: .scale(scale: 0.98))
                ))
            } else {
                MainShellView(rootViewModel: viewModel)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
            }
        }
        .animation(ODAnimation.pageTransition, value: viewModel.shouldShowOnboarding)
    }
}
