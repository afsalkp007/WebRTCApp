import SwiftUI

/// Renders a video stream (local or remote) with fallback placeholders when video is disabled or connecting.
public struct VideoStreamView: View {
    public let title: String
    public let isVideoEnabled: Bool
    public let isMuted: Bool
    public let isLocal: Bool
    public let cameraPosition: CameraPosition?
    public let showHeaderBadges: Bool

    @ScaledMetric private var badgeIconSize: CGFloat = 14
    @ScaledMetric private var avatarSize: CGFloat = 72

    public init(
        title: String,
        isVideoEnabled: Bool = true,
        isMuted: Bool = false,
        isLocal: Bool = false,
        cameraPosition: CameraPosition? = nil,
        showHeaderBadges: Bool = true
    ) {
        self.title = title
        self.isVideoEnabled = isVideoEnabled
        self.isMuted = isMuted
        self.isLocal = isLocal
        self.cameraPosition = cameraPosition
        self.showHeaderBadges = showHeaderBadges
    }

    public var body: some View {
        ZStack {
            if isVideoEnabled {
                // Active video feed (simulated test canvas / camera feed preview)
                ActiveVideoFeed(isLocal: isLocal)
            } else {
                // Video disabled avatar placeholder
                VideoPlaceholder(title: title, avatarSize: avatarSize)
            }

            // Stream overlay metadata & badges
            if showHeaderBadges {
                VStack {
                    HStack(spacing: AppSpacing.xxSmall) {
                        StreamBadge(
                            title: title,
                            icon: isLocal ? "person.fill" : "person.2.fill"
                        )

                        Spacer()

                        if isMuted {
                            Image(systemName: "mic.slash.fill")
                                .font(.system(size: badgeIconSize, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(AppSpacing.xxSmall + 2)
                                .background(AppColors.hangupRed)
                                .clipShape(Circle())
                        }
                    }
                    .padding(AppSpacing.xSmall)

                    Spacer()
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Subviews

private struct ActiveVideoFeed: View {
    let isLocal: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Simulated camera visual pattern with subtle gradient animation
                LinearGradient(
                    colors: isLocal
                        ? [Color(red: 0.12, green: 0.15, blue: 0.25), Color(red: 0.05, green: 0.08, blue: 0.16)]
                        : [Color(red: 0.08, green: 0.10, blue: 0.18), Color(red: 0.02, green: 0.03, blue: 0.07)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Grid pattern resembling video viewport
                GridOverlay()
                    .opacity(0.12)

                VStack(spacing: AppSpacing.xxSmall) {
                    Image(systemName: isLocal ? "video.fill" : "person.crop.rectangle.fill")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(AppColors.brandPrimary.opacity(0.85))

                    Text(isLocal ? "Local Camera Feed" : "Remote WebRTC Stream")
                        .font(AppTypography.caption)
                        .foregroundStyle(.white.opacity(0.75))

                    Text("720p • 30 FPS • H.264")
                        .font(AppTypography.monospaceStats)
                        .foregroundStyle(.white.opacity(0.50))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

private struct VideoPlaceholder: View {
    let title: String
    let avatarSize: CGFloat

    var body: some View {
        ZStack {
            AppColors.surfaceSecondary

            VStack(spacing: AppSpacing.small) {
                Circle()
                    .fill(AppColors.brandPrimary.opacity(0.15))
                    .frame(width: avatarSize, height: avatarSize)
                    .overlay(
                        Text(title.prefix(1).uppercased())
                            .font(AppTypography.title)
                            .foregroundStyle(AppColors.brandPrimary)
                    )

                Text("Camera Off")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

private struct StreamBadge: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: AppSpacing.xxSmall) {
            Image(systemName: icon)
                .font(.caption2)
            Text(title)
                .font(AppTypography.caption2)
                .fontWeight(.medium)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, AppSpacing.xSmall)
        .padding(.vertical, AppSpacing.xxSmall)
        .background(.ultraThinMaterial)
        .foregroundStyle(.white)
        .clipShape(Capsule())
    }
}

private struct GridOverlay: View {
    var body: some View {
        Canvas { context, size in
            let step: CGFloat = 30
            var path = Path()
            for x in stride(from: 0, through: size.width, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, through: size.height, by: step) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            context.stroke(path, with: .color(.white), lineWidth: 0.5)
        }
    }
}
