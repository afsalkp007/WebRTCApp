import SwiftUI

/// Indicator badge displaying WebRTC connection quality, RTT latency, and packet loss.
public struct QualityBadgeView: View {
    public let quality: ConnectionQuality
    public let rttMs: Double
    public let packetLossRate: Double

    public init(quality: ConnectionQuality, rttMs: Double, packetLossRate: Double) {
        self.quality = quality
        self.rttMs = rttMs
        self.packetLossRate = packetLossRate
    }

    private var statusColor: Color {
        switch quality {
        case .excellent, .good:
            return AppColors.statusConnected
        case .fair:
            return AppColors.statusConnecting
        case .poor, .disconnected:
            return AppColors.statusDisconnected
        }
    }

    public var body: some View {
        HStack(spacing: AppSpacing.xSmall) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text(quality.rawValue)
                .font(AppTypography.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppColors.textPrimary)

            Divider()
                .frame(height: 12)

            Text("\(Int(rttMs)) ms")
                .font(AppTypography.monospaceStats)
                .foregroundStyle(AppColors.textSecondary)

            if packetLossRate > 0 {
                Text("•")
                    .foregroundStyle(AppColors.textTertiary)
                Text(String(format: "%.1f%% loss", packetLossRate * 100))
                    .font(AppTypography.monospaceStats)
                    .foregroundStyle(packetLossRate > 0.05 ? AppColors.statusDisconnected : AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.small)
        .padding(.vertical, AppSpacing.xxSmall + 2)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
    }
}
