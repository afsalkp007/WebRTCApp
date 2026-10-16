import SwiftUI

/// Settings sheet for configuring signaling modes, server URLs, and ICE servers.
public struct SettingsSheet: View {
    @Binding public var signalingMode: SignalingMode
    @Binding public var roomId: String
    @Binding public var serverUrlString: String
    @Binding public var localPeerId: String
    public let onClose: () -> Void

    public init(
        signalingMode: Binding<SignalingMode>,
        roomId: Binding<String>,
        serverUrlString: Binding<String>,
        localPeerId: Binding<String>,
        onClose: @escaping () -> Void
    ) {
        self._signalingMode = signalingMode
        self._roomId = roomId
        self._serverUrlString = serverUrlString
        self._localPeerId = localPeerId
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("SIGNALING MODE")) {
                    Picker("Mode", selection: $signalingMode) {
                        ForEach(SignalingMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)

                    Text(signalingMode.description)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Section(header: Text("ROOM & IDENTITY")) {
                    HStack {
                        Text("Room ID")
                        Spacer()
                        TextField("e.g. room-101", text: $roomId)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    HStack {
                        Text("My Peer ID")
                        Spacer()
                        TextField("Peer ID", text: $localPeerId)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }

                if signalingMode == .webSocket {
                    Section(header: Text("WEBSOCKET SIGNALING SERVER")) {
                        TextField("wss://...", text: $serverUrlString)
                            .font(AppTypography.monospaceStats)
                            .keyboardType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                Section(header: Text("DEFAULT ICE SERVERS")) {
                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        Text("STUN: stun.l.google.com:19302")
                            .font(AppTypography.monospaceStats)
                        Text("STUN: stun1.l.google.com:19302")
                            .font(AppTypography.monospaceStats)
                    }
                    .foregroundStyle(AppColors.textSecondary)
                }

                Section(header: Text("ABOUT")) {
                    HStack {
                        Text("WebRTC Engine")
                        Spacer()
                        Text("Google WebRTC / M120")
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    HStack {
                        Text("Minimum Deployment")
                        Spacer()
                        Text("iOS 17.0+")
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    HStack {
                        Text("Supported Orientations")
                        Spacer()
                        Text("Portrait & Landscape")
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
            }
            .navigationTitle("Call Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
    }
}
