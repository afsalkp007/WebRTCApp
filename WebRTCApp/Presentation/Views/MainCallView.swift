import SwiftUI

/// Main adaptive call view supporting portrait and landscape orientations, dynamic type, and dark/light modes.
public struct MainCallView: View {
    @Bindable public var viewModel: CallViewModel

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    // Picture-in-picture local video position & dragging state
    @State private var pipOffset: CGSize = .zero
    @State private var pipDragTranslation: CGSize = .zero

    public init(viewModel: CallViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            ZStack {
                // Adaptive Background Canvas
                AppColors.surfaceBackground
                    .ignoresSafeArea()

                if isLandscape {
                    // Landscape Layout: Side-by-side video feeds with floating controls
                    LandscapeCallLayout(
                        viewModel: viewModel,
                        geometry: geometry
                    )
                } else {
                    // Portrait Layout: Full-screen remote video with PiP local camera
                    PortraitCallLayout(
                        viewModel: viewModel,
                        geometry: geometry,
                        pipOffset: pipOffset,
                        pipDragTranslation: pipDragTranslation,
                        onDragChanged: { value in
                            pipDragTranslation = value.translation
                        },
                        onDragEnded: { value in
                            pipOffset.width += value.translation.width
                            pipOffset.height += value.translation.height
                            pipDragTranslation = .zero
                        }
                    )
                }

                // Error / Notification Toast Banner
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        ErrorBanner(message: errorMessage) {
                            withAnimation {
                                viewModel.errorMessage = nil
                            }
                        }
                        .padding(.top, AppSpacing.xxLarge)
                        Spacer()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
        .sheet(isPresented: $viewModel.isChatPresented) {
            DataChannelChatSheet(
                messages: $viewModel.chatMessages,
                isDataChannelOpen: viewModel.isDataChannelOpen,
                onSendMessage: { _ in viewModel.sendChatMessage() },
                onClose: { viewModel.isChatPresented = false }
            )
        }
        .sheet(isPresented: $viewModel.isStatsPresented) {
            StatsOverlayView(
                stats: viewModel.connectionStats,
                peerConnectionState: viewModel.peerConnectionState,
                iceConnectionState: viewModel.iceConnectionState,
                signalingState: viewModel.signalingState,
                onClose: { viewModel.isStatsPresented = false }
            )
        }
        .sheet(isPresented: $viewModel.isSettingsPresented) {
            SettingsSheet(
                signalingMode: $viewModel.signalingMode,
                roomId: $viewModel.roomId,
                serverUrlString: $viewModel.serverUrlString,
                localPeerId: $viewModel.localPeerId,
                onClose: { viewModel.isSettingsPresented = false }
            )
        }
        .sheet(isPresented: $viewModel.isManualSignalingPresented) {
            ManualSignalingSheet(
                localSdp: viewModel.manualGeneratedSdp,
                localCandidates: viewModel.manualGeneratedCandidates,
                importText: $viewModel.manualImportText,
                onApplyInput: { viewModel.applyManualSdpInput() },
                onClose: { viewModel.isManualSignalingPresented = false }
            )
        }
    }
}

// MARK: - Portrait Layout

private struct PortraitCallLayout: View {
    let viewModel: CallViewModel
    let geometry: GeometryProxy
    let pipOffset: CGSize
    let pipDragTranslation: CGSize
    let onDragChanged: (DragGesture.Value) -> Void
    let onDragEnded: (DragGesture.Value) -> Void

    var body: some View {
        ZStack {
            // Background Remote Video Stream
            VideoStreamView(
                title: "Remote Peer",
                isVideoEnabled: viewModel.callState.isCallActive,
                isMuted: false,
                isLocal: false
            )
            .ignoresSafeArea()

            // Header Controls & Indicators
            VStack {
                TopNavigationBar(viewModel: viewModel)
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.top, AppSpacing.small)

                Spacer()

                // Bottom Floating Controls Dock
                CallControlsBar(
                    isCallActive: viewModel.callState.isCallActive,
                    isAudioMuted: viewModel.mediaSettings.isAudioMuted,
                    isVideoEnabled: viewModel.mediaSettings.isVideoEnabled,
                    isSpeakerphoneOn: viewModel.mediaSettings.isSpeakerphoneOn,
                    isDataChannelOpen: viewModel.isDataChannelOpen,
                    unreadMessageCount: viewModel.chatMessages.filter { !$0.isLocal }.count,
                    onToggleAudio: { viewModel.toggleMute() },
                    onToggleVideo: { viewModel.toggleVideo() },
                    onSwitchCamera: { viewModel.switchCamera() },
                    onToggleSpeaker: { viewModel.toggleSpeakerphone() },
                    onToggleCall: {
                        if viewModel.callState.isCallActive {
                            viewModel.endCall()
                        } else {
                            viewModel.startCall(asInitiator: true)
                        }
                    },
                    onOpenChat: { viewModel.isChatPresented = true },
                    onOpenStats: { viewModel.isStatsPresented = true }
                )
                .padding(.bottom, AppSpacing.medium)
            }

            // Draggable Picture-in-Picture Local Camera
            VStack {
                HStack {
                    Spacer()
                    VideoStreamView(
                        title: "You",
                        isVideoEnabled: viewModel.mediaSettings.isVideoEnabled,
                        isMuted: viewModel.mediaSettings.isAudioMuted,
                        isLocal: true,
                        cameraPosition: viewModel.mediaSettings.cameraPosition
                    )
                    .frame(width: 120, height: 170)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))
                    .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
                    .offset(
                        x: pipOffset.width + pipDragTranslation.width,
                        y: pipOffset.height + pipDragTranslation.height
                    )
                    .gesture(
                        DragGesture()
                            .onChanged(onDragChanged)
                            .onEnded(onDragEnded)
                    )
                    .padding(.trailing, AppSpacing.medium)
                    .padding(.top, 70)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Landscape Layout

private struct LandscapeCallLayout: View {
    let viewModel: CallViewModel
    let geometry: GeometryProxy

    var body: some View {
        ZStack {
            HStack(spacing: AppSpacing.small) {
                // Remote Video Feed
                VideoStreamView(
                    title: "Remote Peer",
                    isVideoEnabled: viewModel.callState.isCallActive,
                    isMuted: false,
                    isLocal: false
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Local Video Feed
                VideoStreamView(
                    title: "You",
                    isVideoEnabled: viewModel.mediaSettings.isVideoEnabled,
                    isMuted: viewModel.mediaSettings.isAudioMuted,
                    isLocal: true,
                    cameraPosition: viewModel.mediaSettings.cameraPosition
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, AppSpacing.small)
            .padding(.top, 56)
            .padding(.bottom, 72)

            // Top Header Bar
            VStack {
                TopNavigationBar(viewModel: viewModel)
                    .padding(.horizontal, AppSpacing.large)
                    .padding(.top, AppSpacing.xSmall)
                Spacer()

                // Floating Controls Dock
                CallControlsBar(
                    isCallActive: viewModel.callState.isCallActive,
                    isAudioMuted: viewModel.mediaSettings.isAudioMuted,
                    isVideoEnabled: viewModel.mediaSettings.isVideoEnabled,
                    isSpeakerphoneOn: viewModel.mediaSettings.isSpeakerphoneOn,
                    isDataChannelOpen: viewModel.isDataChannelOpen,
                    unreadMessageCount: viewModel.chatMessages.filter { !$0.isLocal }.count,
                    onToggleAudio: { viewModel.toggleMute() },
                    onToggleVideo: { viewModel.toggleVideo() },
                    onSwitchCamera: { viewModel.switchCamera() },
                    onToggleSpeaker: { viewModel.toggleSpeakerphone() },
                    onToggleCall: {
                        if viewModel.callState.isCallActive {
                            viewModel.endCall()
                        } else {
                            viewModel.startCall(asInitiator: true)
                        }
                    },
                    onOpenChat: { viewModel.isChatPresented = true },
                    onOpenStats: { viewModel.isStatsPresented = true }
                )
                .padding(.bottom, AppSpacing.xSmall)
            }
        }
    }
}

// MARK: - Navigation Header

private struct TopNavigationBar: View {
    let viewModel: CallViewModel

    var body: some View {
        HStack {
            // Room & Signaling Info Pill
            HStack(spacing: AppSpacing.xxSmall) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.brandPrimary)

                Text(viewModel.roomId)
                    .font(AppTypography.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)
            }
            .padding(.horizontal, AppSpacing.small)
            .padding(.vertical, AppSpacing.xxSmall + 2)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())

            Spacer()

            // Quality Badge
            if viewModel.callState.isCallActive {
                QualityBadgeView(
                    quality: viewModel.connectionStats.quality,
                    rttMs: viewModel.connectionStats.rttMs,
                    packetLossRate: viewModel.connectionStats.packetLossRate
                )
            }

            Spacer()

            // Action Buttons
            HStack(spacing: AppSpacing.xSmall) {
                if viewModel.signalingMode == .manual {
                    Button {
                        viewModel.isManualSignalingPresented = true
                    } label: {
                        Image(systemName: "doc.plaintext.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.textPrimary)
                            .padding(AppSpacing.xSmall)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Manual SDP Signaling")
                }

                Button {
                    viewModel.isSettingsPresented = true
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(AppColors.textPrimary)
                        .padding(AppSpacing.xSmall)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Settings")
            }
        }
    }
}

// MARK: - Error Banner

private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.small) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppColors.statusDisconnected)

            Text(message)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.textPrimary)
                .lineLimit(2)

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .padding(.horizontal, AppSpacing.medium)
        .padding(.vertical, AppSpacing.small)
        .background(AppColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous)
                .stroke(AppColors.statusDisconnected.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 8, y: 4)
        .padding(.horizontal, AppSpacing.medium)
    }
}
