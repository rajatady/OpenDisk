import Foundation

actor TimelineStore: TimelineStoreProtocol {
    private var items: [DiskSnapshot] = []

    func save(snapshot: DiskSnapshot) async {
        items.append(snapshot)
        items.sort(by: { $0.capturedAt < $1.capturedAt })
    }

    func snapshots() async -> [DiskSnapshot] {
        items
    }
}
