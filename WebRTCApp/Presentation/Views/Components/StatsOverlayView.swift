import SwiftUI

/// Detailed WebRTC diagnostic HUD showing real-time metrics, codecs, and connection states.
public struct StatsOverlayView: View {
    public let stats: ConnectionStats
    public let peerConnectionState: PeerConnectionState
    public let iceConnectionState: IceConnectionState
    public let signalingState: SignalingState
    public let onClose: () -> Void

    public init(
        stats: ConnectionStats,
        peerConnectionState: PeerConnectionState,
        iceConnectionState: IceConnectionState,
        signalingState: SignalingState,
        onClose: @escaping () -> Void
    ) {
        self.stats = stats
        self.peerConnectionState = peerConnectionState
        self.iceConnectionState = iceConnectionState
        self.signalingState = signalingState
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppSpacing.medium) {
                    // Overall Quality Card
                    VStack(alignment: .leading, spacing: AppSpacing.xSmall) {
                        Text("CONNECTION QUALITY")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        HStack {
                            QualityBadgeView(
                                quality: stats.quality,
                                rttMs: stats.rttMs,
                                packetLossRate: stats.packetLossRate
                            )
                            Spacer()
                        }
                    }
                    .padding(AppSpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))

                    // Connection States Grid
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("STATE MACHINE")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        Grid(alignment: .leading, horizontalSpacing: AppSpacing.medium, verticalSpacing: AppSpacing.xSmall) {
                            GridRow {
                                Text("PeerConnection:")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColors.textSecondary)
                                Text(peerConnectionState.rawValue)
                                    .font(AppTypography.monospaceStats)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(stateColor(peerConnectionState.isConnected))
                            }

                            GridRow {
                                Text("ICE Transport:")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColors.textSecondary)
                                Text(iceConnectionState.rawValue)
                                    .font(AppTypography.monospaceStats)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(stateColor(iceConnectionState.isAlive))
                            }

                            GridRow {
                                Text("Signaling State:")
                                    .font(AppTypography.footnote)
                                    .foregroundStyle(AppColors.textSecondary)
                                Text(signalingState.rawValue)
                                    .font(AppTypography.monospaceStats)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.textPrimary)
                            }
                        }
                    }
                    .padding(AppSpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))

                    // Media Pipeline Metrics
                    VStack(alignment: .leading, spacing: AppSpacing.small) {
                        Text("MEDIA STREAM METRICS")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.small) {
                            MetricCard(title: "FPS", value: String(format: "%.1f", stats.fps), unit: "fps")
                            MetricCard(title: "Resolution", value: "\(stats.resolutionWidth)×\(stats.resolutionHeight)", unit: "")
                            MetricCard(title: "Bitrate", value: String(format: "%.0f", stats.bitrateKbps), unit: "kbps")
                            MetricCard(title: "RTT Latency", value: String(format: "%.0f", stats.rttMs), unit: "ms")
                            MetricCard(title: "Packet Loss", value: String(format: "%.2f", stats.packetLossRate * 100), unit: "%")
                            MetricCard(title: "Bytes Sent", value: formatBytes(stats.bytesSent), unit: "")
                            MetricCard(title: "Bytes Recv", value: formatBytes(stats.bytesReceived), unit: "")
                            MetricCard(title: "Video Codec", value: stats.videoCodec, unit: "")
                        }
                    }
                    .padding(AppSpacing.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))
                }
                .padding(AppSpacing.medium)
            }
            .navigationTitle("WebRTC Diagnostics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                        .font(AppTypography.body)
                }
            }
        }
    }

    private func stateColor(_ isGood: Bool) -> Color {
        isGood ? AppColors.statusConnected : AppColors.statusConnecting
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - MetricCard Subview

private struct MetricCard: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
            Text(title)
                .font(AppTypography.caption2)
                .foregroundStyle(AppColors.textTertiary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(AppTypography.monospaceStats)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)

                if !unit.isEmpty {
                    Text(unit)
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .padding(AppSpacing.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surfaceBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall, style: .continuous))
    }
}
