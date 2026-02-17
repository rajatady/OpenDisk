import SwiftUI
import Charts

struct ActivityMonitorView: View {
    @ObservedObject var viewModel: ActivityMonitorViewModel

    var body: some View {
        VStack(spacing: ODSpacing.md) {
            header
            summaryCards
            chartPanel
            sessionList
        }
        .padding(ODSpacing.lg)
        .odCanvasBackground()
        .task {
            await viewModel.refresh()
        }
    }

    private var header: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.xs) {
                Text("Activity Monitor")
                    .odTextStyle(.display)
                Text("Live clarity into scan throughput, cache efficiency, and reclaim trends.")
                    .odTextStyle(.body, color: .textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var summaryCards: some View {
        HStack(spacing: ODSpacing.md) {
            StatCard(
                title: "Avg Scan Duration",
                value: String(format: "%.1fs", viewModel.state.summary?.averageScanDurationSeconds ?? 0),
                subtitle: "Across recent sessions"
            )

            StatCard(
                title: "Cache Hit Rate",
                value: "\(Int((viewModel.state.summary?.cacheHitRate ?? 0) * 100))%",
                subtitle: "Catalog + recommendations"
            )

            StatCard(
                title: "Peak Reclaim",
                value: Formatting.bytes(viewModel.state.summary?.peakReclaimBytes ?? 0),
                subtitle: "Highest single-session potential"
            )
        }
    }

    private var chartPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                Text("Session Trend")
                    .odTextStyle(.heading)

                if viewModel.state.samples.isEmpty {
                    Text("No activity yet. Run a scan to populate the chart.")
                        .odTextStyle(.body, color: .textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                } else {
                    Chart(viewModel.state.samples) { sample in
                        LineMark(
                            x: .value("Time", sample.capturedAt),
                            y: .value("Reclaim (GB)", reclaimGigabytes(sample.reclaimBytes))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(ODColorToken.accent.color)

                        AreaMark(
                            x: .value("Time", sample.capturedAt),
                            y: .value("Reclaim (GB)", reclaimGigabytes(sample.reclaimBytes))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [ODColorToken.accent.color.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        BarMark(
                            x: .value("Time", sample.capturedAt),
                            y: .value("Apps", sample.appCount)
                        )
                        .opacity(0.20)
                        .foregroundStyle(ODColorToken.safe.color)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(minHeight: 220)
                }
            }
        }
        .overlay(
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("activity_chart")
        )
    }

    private var sessionList: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                Text("Recent Sessions")
                    .odTextStyle(.heading)

                if viewModel.state.samples.isEmpty {
                    Text("No sessions recorded yet.")
                        .odTextStyle(.body, color: .textSecondary)
                } else {
                    ForEach(Array(viewModel.state.samples.suffix(8).reversed())) { sample in
                        HStack(spacing: ODSpacing.md) {
                            Text(Formatting.relativeDate(sample.capturedAt))
                                .odTextStyle(.caption, color: .textSecondary)
                                .frame(width: 120, alignment: .leading)

                            Text("\(sample.appCount) apps")
                                .odTextStyle(.body)

                            Text("\(sample.recommendationCount) recommendations")
                                .odTextStyle(.caption, color: .textSecondary)

                            Spacer()

                            if sample.usedCachedCatalog {
                                Text("Cached")
                                    .odTextStyle(.caption, color: .safe)
                            } else {
                                Text("Live")
                                    .odTextStyle(.caption, color: .review)
                            }

                            Text(String(format: "%.1fs", sample.scanDurationSeconds))
                                .odTextStyle(.caption, color: .textSecondary)

                            SizeBadge(bytes: sample.reclaimBytes)
                        }
                        .odSurfaceCard(selected: false)
                    }
                }
            }
        }
    }

    private func reclaimGigabytes(_ bytes: Int64) -> Double {
        Double(bytes) / 1_073_741_824
    }
}
