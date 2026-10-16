import SwiftUI

/// Glassmorphic floating control dock for call actions and media controls.
public struct CallControlsBar: View {
    public let isCallActive: Bool
    public let isAudioMuted: Bool
    public let isVideoEnabled: Bool
    public let isSpeakerphoneOn: Bool
    public let isDataChannelOpen: Bool
    public let unreadMessageCount: Int

    public let onToggleAudio: () -> Void
    public let onToggleVideo: () -> Void
    public let onSwitchCamera: () -> Void
    public let onToggleSpeaker: () -> Void
    public let onToggleCall: () -> Void
    public let onOpenChat: () -> Void
    public let onOpenStats: () -> Void

    @ScaledMetric private var buttonSize: CGFloat = 40
    @ScaledMetric private var primaryButtonSize: CGFloat = 50
    @ScaledMetric private var iconSize: CGFloat = 18

    public init(
        isCallActive: Bool,
        isAudioMuted: Bool,
        isVideoEnabled: Bool,
        isSpeakerphoneOn: Bool,
        isDataChannelOpen: Bool = false,
        unreadMessageCount: Int = 0,
        onToggleAudio: @escaping () -> Void,
        onToggleVideo: @escaping () -> Void,
        onSwitchCamera: @escaping () -> Void,
        onToggleSpeaker: @escaping () -> Void,
        onToggleCall: @escaping () -> Void,
        onOpenChat: @escaping () -> Void,
        onOpenStats: @escaping () -> Void
    ) {
        self.isCallActive = isCallActive
        self.isAudioMuted = isAudioMuted
        self.isVideoEnabled = isVideoEnabled
        self.isSpeakerphoneOn = isSpeakerphoneOn
        self.isDataChannelOpen = isDataChannelOpen
        self.unreadMessageCount = unreadMessageCount
        self.onToggleAudio = onToggleAudio
        self.onToggleVideo = onToggleVideo
        self.onSwitchCamera = onSwitchCamera
        self.onToggleSpeaker = onToggleSpeaker
        self.onToggleCall = onToggleCall
        self.onOpenChat = onOpenChat
        self.onOpenStats = onOpenStats
    }

    public var body: some View {
        ViewThatFits(in: .horizontal) {
            controlsContent
                .padding(.horizontal, AppSpacing.small)
                .padding(.vertical, AppSpacing.xSmall)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)

            ScrollView(.horizontal, showsIndicators: false) {
                controlsContent
                    .padding(.horizontal, AppSpacing.small)
                    .padding(.vertical, AppSpacing.xSmall)
            }
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 12, y: 6)
        }
    }

    private var controlsContent: some View {
        HStack(spacing: 6) {
            // Audio Mute Button
            ControlButton(
                icon: isAudioMuted ? "mic.slash.fill" : "mic.fill",
                label: isAudioMuted ? "Unmute" : "Mute",
                isActive: !isAudioMuted,
                size: buttonSize,
                iconSize: iconSize,
                action: onToggleAudio
            )

            // Video Camera Button
            ControlButton(
                icon: isVideoEnabled ? "video.fill" : "video.slash.fill",
                label: isVideoEnabled ? "Stop Video" : "Start Video",
                isActive: isVideoEnabled,
                size: buttonSize,
                iconSize: iconSize,
                action: onToggleVideo
            )

            // Switch Camera Button
            ControlButton(
                icon: "camera.rotate.fill",
                label: "Flip Camera",
                isActive: isVideoEnabled,
                size: buttonSize,
                iconSize: iconSize,
                action: onSwitchCamera
            )
            .disabled(!isVideoEnabled)

            // Speakerphone Toggle
            ControlButton(
                icon: isSpeakerphoneOn ? "speaker.wave.3.fill" : "speaker.fill",
                label: isSpeakerphoneOn ? "Speaker" : "Earpiece",
                isActive: isSpeakerphoneOn,
                size: buttonSize,
                iconSize: iconSize,
                action: onToggleSpeaker
            )

            // WebRTC DataChannel Chat
            Button(action: onOpenChat) {
                ZStack(alignment: .topTrailing) {
                    ControlButtonVisual(
                        icon: "bubble.left.and.bubble.right.fill",
                        isActive: isDataChannelOpen,
                        size: buttonSize,
                        iconSize: iconSize
                    )

                    if unreadMessageCount > 0 {
                        Text("\(unreadMessageCount)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(AppColors.brandPrimary)
                            .clipShape(Circle())
                            .offset(x: 4, y: -4)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open DataChannel Chat")

            // Real-Time Stats HUD
            ControlButton(
                icon: "waveform.path.ecg",
                label: "Stats HUD",
                isActive: false,
                size: buttonSize,
                iconSize: iconSize,
                action: onOpenStats
            )

            // Primary Call / Hangup Button
            Button(action: onToggleCall) {
                Image(systemName: isCallActive ? "phone.down.fill" : "phone.fill")
                    .font(.system(size: iconSize + 4, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: primaryButtonSize, height: primaryButtonSize)
                    .background(isCallActive ? AppColors.hangupRed : AppColors.statusConnected)
                    .clipShape(Circle())
                    .shadow(color: (isCallActive ? AppColors.hangupRed : AppColors.statusConnected).opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isCallActive ? "End Call" : "Start Call")
        }
    }
}

// MARK: - Control Button Subview

private struct ControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    let size: CGFloat
    let iconSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ControlButtonVisual(
                icon: icon,
                isActive: isActive,
                size: size,
                iconSize: iconSize
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

private struct ControlButtonVisual: View {
    let icon: String
    let isActive: Bool
    let size: CGFloat
    let iconSize: CGFloat

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: iconSize, weight: .medium))
            .foregroundStyle(isActive ? AppColors.textPrimary : AppColors.textTertiary)
            .frame(width: size, height: size)
            .background(isActive ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
            .clipShape(Circle())
    }
}
