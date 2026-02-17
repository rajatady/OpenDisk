import XCTest
@testable import OpenDisk

@MainActor
final class AppManagerViewModelTests: XCTestCase {
    func testLoadAppsPopulatesAndSupportsFiltering() async {
        let viewModel = AppManagerViewModel(container: .mock())

        await viewModel.loadApps()

        XCTAssertGreaterThan(viewModel.state.apps.count, 0)
        viewModel.searchText = "xcode"
        XCTAssertEqual(viewModel.state.filteredApps.count, 1)
    }

    func testExecuteUninstallPlanProducesResult() async {
        let viewModel = AppManagerViewModel(container: .mock())
        await viewModel.loadApps()

        viewModel.selectedAppID = viewModel.state.apps.first?.id
        viewModel.createPlan(mode: .removeEverything)
        await viewModel.executeUninstallPlan()

        XCTAssertNotNil(viewModel.uninstallState.executionResult)
        XCTAssertTrue(viewModel.uninstallState.executionResult?.failures.isEmpty ?? false)
    }
}
