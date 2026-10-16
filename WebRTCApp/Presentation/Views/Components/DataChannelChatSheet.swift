import SwiftUI

/// Sheet providing peer-to-peer real-time text chat over WebRTC DataChannel.
public struct DataChannelChatSheet: View {
    @Binding public var messages: [ChatMessage]
    public let isDataChannelOpen: Bool
    public let onSendMessage: (String) -> Void
    public let onClose: () -> Void

    @State private var inputText: String = ""
    @ScaledMetric private var bubblePadding: CGFloat = 10

    public init(
        messages: Binding<[ChatMessage]>,
        isDataChannelOpen: Bool,
        onSendMessage: @escaping (String) -> Void,
        onClose: @escaping () -> Void
    ) {
        self._messages = messages
        self.isDataChannelOpen = isDataChannelOpen
        self.onSendMessage = onSendMessage
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // DataChannel status header
                HStack(spacing: AppSpacing.xSmall) {
                    Circle()
                        .fill(isDataChannelOpen ? AppColors.statusConnected : AppColors.statusConnecting)
                        .frame(width: 8, height: 8)

                    Text(isDataChannelOpen ? "WebRTC DataChannel Connected" : "Awaiting DataChannel Handshake...")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    Spacer()

                    Text("\(messages.count) messages")
                        .font(AppTypography.caption2)
                        .foregroundStyle(AppColors.textTertiary)
                }
                .padding(.horizontal, AppSpacing.medium)
                .padding(.vertical, AppSpacing.xSmall)
                .background(AppColors.surfaceSecondary)

                Divider()

                // Chat Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: AppSpacing.small) {
                            if messages.isEmpty {
                                EmptyChatPlaceholder(isDataChannelOpen: isDataChannelOpen)
                                    .padding(.top, AppSpacing.xxLarge)
                            } else {
                                ForEach(messages) { message in
                                    ChatBubbleView(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding(AppSpacing.medium)
                    }
                    .onChange(of: messages.count) {
                        if let lastId = messages.last?.id {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Message Input Bar
                HStack(spacing: AppSpacing.small) {
                    TextField("Send message via DataChannel...", text: $inputText)
                        .font(AppTypography.body)
                        .padding(.horizontal, AppSpacing.small)
                        .padding(.vertical, AppSpacing.xSmall + 2)
                        .background(AppColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))
                        .submitLabel(.send)
                        .onSubmit(sendMessage)

                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(canSend ? AppColors.brandPrimary : AppColors.textTertiary)
                    }
                    .disabled(!canSend)
                    .accessibilityLabel("Send message")
                }
                .padding(AppSpacing.medium)
                .background(AppColors.surfaceBackground)
            }
            .navigationTitle("DataChannel Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                        .font(AppTypography.body)
                }
            }
        }
    }

    private var canSend: Bool {
        isDataChannelOpen && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func sendMessage() {
        guard canSend else { return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        inputText = ""
        onSendMessage(text)
    }
}

// MARK: - Subviews

private struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isLocal { Spacer() }

            VStack(alignment: message.isLocal ? .trailing : .leading, spacing: 3) {
                Text(message.senderId)
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textTertiary)

                Text(message.text)
                    .font(AppTypography.body)
                    .foregroundStyle(message.isLocal ? .white : AppColors.textPrimary)
                    .padding(.horizontal, AppSpacing.medium)
                    .padding(.vertical, AppSpacing.small)
                    .background(
                        message.isLocal
                            ? AppColors.brandPrimary
                            : AppColors.surfaceSecondary
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))

                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(AppTypography.caption2)
                    .foregroundStyle(AppColors.textTertiary)
            }

            if !message.isLocal { Spacer() }
        }
    }
}

private struct EmptyChatPlaceholder: View {
    let isDataChannelOpen: Bool

    var body: some View {
        VStack(spacing: AppSpacing.small) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.brandPrimary.opacity(0.5))

            Text("No Messages Yet")
                .font(AppTypography.headline)
                .foregroundStyle(AppColors.textPrimary)

            Text(
                isDataChannelOpen
                    ? "Messages sent here travel directly between peers over the SCTP WebRTC DataChannel."
                    : "Connecting to peer DataChannel..."
            )
            .font(AppTypography.footnote)
            .foregroundStyle(AppColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.large)
        }
    }
}
