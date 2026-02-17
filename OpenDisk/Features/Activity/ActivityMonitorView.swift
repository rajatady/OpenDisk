import SwiftUI
import Charts

struct ActivityMonitorView: View {
    private enum SessionMetric: String, CaseIterable, Identifiable {
        case reclaim
        case duration
        case appCount

        var id: String { rawValue }

        var title: String {
            switch self {
            case .reclaim:
                return "Reclaim"
            case .duration:
                return "Duration"
            case .appCount:
                return "Apps"
            }
        }

        var axisTitle: String {
            switch self {
            case .reclaim:
                return "Reclaim (GB)"
            case .duration:
                return "Duration (s)"
            case .appCount:
                return "Apps"
            }
        }

        var tint: Color {
            switch self {
            case .reclaim:
                return ODColors.accent
            case .duration:
                return ODColors.accentSecondary
            case .appCount:
                return ODColors.safe
            }
        }
    }

    @ObservedObject var viewModel: ActivityMonitorViewModel
    @State private var selectedMetric: SessionMetric = .reclaim

    var body: some View {
        VStack(spacing: ODSpacing.md) {
            header
            summaryCards
            chartPanel
            diskTrendPanel
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

            StatCard(
                title: "Forecast",
                value: projectionValueLabel,
                subtitle: projectionSubtitle
            )
        }
    }

    private var chartPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                HStack(spacing: ODSpacing.md) {
                    Text("Session Trend")
                        .odTextStyle(.heading)
                    Spacer()
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(SessionMetric.allCases) { metric in
                            Text(metric.title).tag(metric)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 260)
                    .accessibilityIdentifier("activity_metric_picker")
                }

                if viewModel.state.samples.isEmpty {
                    Text("No activity yet. Run a scan to populate the chart.")
                        .odTextStyle(.body, color: .textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                } else {
                    Chart(viewModel.state.samples) { sample in
                        LineMark(
                            x: .value("Time", sample.capturedAt),
                            y: .value(selectedMetric.axisTitle, metricValue(for: sample))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(selectedMetric.tint)

                        AreaMark(
                            x: .value("Time", sample.capturedAt),
                            y: .value(selectedMetric.axisTitle, metricValue(for: sample))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [selectedMetric.tint.opacity(0.35), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                        PointMark(
                            x: .value("Time", sample.capturedAt),
                            y: .value(selectedMetric.axisTitle, metricValue(for: sample))
                        )
                        .foregroundStyle(selectedMetric.tint)
                        .symbolSize(24)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartYScale(domain: 0...max(metricCeiling, 1))
                    .frame(minHeight: 220)
                    .animation(ODAnimation.smooth, value: selectedMetric)
                }
            }
        }
        .overlay(
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("activity_chart")
        )
    }

    private var diskTrendPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: ODSpacing.sm) {
                Text("Disk Trend")
                    .odTextStyle(.heading)

                if viewModel.state.snapshots.isEmpty {
                    Text("No timeline snapshots yet. Refresh to start capturing disk trend.")
                        .odTextStyle(.body, color: .textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 180, alignment: .center)
                } else {
                    Chart(viewModel.state.snapshots) { snapshot in
                        LineMark(
                            x: .value("Time", snapshot.capturedAt),
                            y: .value("Used (GB)", reclaimGigabytes(snapshot.usedBytes))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(ODColors.review)

                        LineMark(
                            x: .value("Time", snapshot.capturedAt),
                            y: .value("Free (GB)", reclaimGigabytes(snapshot.freeBytes))
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(ODColors.safe)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(minHeight: 180)

                    HStack(spacing: ODSpacing.md) {
                        legendDot(color: ODColors.review, label: "Used")
                        legendDot(color: ODColors.safe, label: "Free")
                        Spacer()
                        projectionPill
                    }
                }
            }
        }
        .overlay(
            Color.clear
                .accessibilityElement()
                .accessibilityIdentifier("activity_disk_trend_chart")
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

    private var projectionPill: some View {
        HStack(spacing: 4) {
            Image(systemName: "calendar.badge.clock")
                .odIcon(.caption)
                .odForeground(.accent)
            Text(projectionPillLabel)
                .odTextStyle(.caption, color: .textSecondary)
        }
        .padding(.horizontal, ODSpacing.sm)
        .padding(.vertical, 4)
        .background(ODColors.insetSurface.opacity(0.8), in: Capsule())
        .accessibilityIdentifier("activity_projection_label")
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .odTextStyle(.caption, color: .textSecondary)
        }
    }

    private func metricValue(for sample: ActivitySample) -> Double {
        switch selectedMetric {
        case .reclaim:
            return reclaimGigabytes(sample.reclaimBytes)
        case .duration:
            return sample.scanDurationSeconds
        case .appCount:
            return Double(sample.appCount)
        }
    }

    private var metricCeiling: Double {
        let ceiling = viewModel.state.samples
            .map(metricValue(for:))
            .max() ?? 0
        return ceiling * 1.15
    }

    private var projectionValueLabel: String {
        guard let projection = viewModel.state.growthProjection else {
            return "N/A"
        }
        return "\(projection.daysUntilFull)d"
    }

    private var projectionSubtitle: String {
        guard let projection = viewModel.state.growthProjection else {
            return "Need timeline history"
        }
        return "\(Formatting.bytes(projection.averageDailyGrowthBytes))/day growth"
    }

    private var projectionPillLabel: String {
        guard let projection = viewModel.state.growthProjection else {
            return "Projection unavailable"
        }
        return "Projected full in \(projection.daysUntilFull) days"
    }

    private func reclaimGigabytes(_ bytes: Int64) -> Double {
        Double(bytes) / 1_073_741_824
    }
}
