import SwiftUI
import UniformTypeIdentifiers

/// Sheet allowing manual air-gapped SDP and ICE candidate exchange between devices.
public struct ManualSignalingSheet: View {
    public let localSdp: String
    public let localCandidates: [String]
    @Binding public var importText: String
    public let onApplyInput: () -> Void
    public let onClose: () -> Void

    @State private var selectedTab: Int = 0
    @State private var copyFeedback: Bool = false

    public init(
        localSdp: String,
        localCandidates: [String],
        importText: Binding<String>,
        onApplyInput: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.localSdp = localSdp
        self.localCandidates = localCandidates
        self._importText = importText
        self.onApplyInput = onApplyInput
        self.onClose = onClose
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Signaling Tab", selection: $selectedTab) {
                    Text("Export Local").tag(0)
                    Text("Import Remote").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(AppSpacing.medium)

                if selectedTab == 0 {
                    ExportView(
                        sdp: localSdp,
                        candidates: localCandidates,
                        copyFeedback: copyFeedback,
                        onCopy: copyToClipboard
                    )
                } else {
                    ImportView(
                        importText: $importText,
                        onApply: onApplyInput
                    )
                }
            }
            .navigationTitle("Manual SDP Signaling")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: onClose)
                }
            }
        }
    }

    private func copyToClipboard() {
        let textToCopy = !localSdp.isEmpty ? localSdp : localCandidates.joined(separator: "\n")
        UIPasteboard.general.string = textToCopy
        withAnimation {
            copyFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copyFeedback = false
            }
        }
    }
}

// MARK: - Subviews

private struct ExportView: View {
    let sdp: String
    let candidates: [String]
    let copyFeedback: Bool
    let onCopy: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.medium) {
                Text("Copy the generated local description or ICE candidate and transfer it to the remote peer.")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColors.textSecondary)

                VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                    Text("LOCAL SDP OFFER / ANSWER")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    Text(sdp.isEmpty ? "No active SDP generated yet. Start call first." : sdp)
                        .font(AppTypography.monospaceStats)
                        .padding(AppSpacing.small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.surfaceSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall, style: .continuous))
                }

                if !candidates.isEmpty {
                    VStack(alignment: .leading, spacing: AppSpacing.xxSmall) {
                        Text("GATHERED ICE CANDIDATES (\(candidates.count))")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        ForEach(candidates, id: \.self) { candidate in
                            Text(candidate)
                                .font(AppTypography.monospaceStats)
                                .padding(AppSpacing.xxSmall)
                                .background(AppColors.surfaceSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall, style: .continuous))
                        }
                    }
                }

                Button(action: onCopy) {
                    HStack {
                        Image(systemName: copyFeedback ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        Text(copyFeedback ? "Copied to Clipboard!" : "Copy Local SDP to Clipboard")
                    }
                    .font(AppTypography.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(AppSpacing.medium)
                    .background(copyFeedback ? AppColors.statusConnected : AppColors.brandPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))
                }
                .disabled(sdp.isEmpty && candidates.isEmpty)
            }
            .padding(AppSpacing.medium)
        }
    }
}

private struct ImportView: View {
    @Binding var importText: String
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.medium) {
            Text("Paste the remote peer's SDP offer/answer JSON or raw SDP text below:")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColors.textSecondary)

            TextEditor(text: $importText)
                .font(AppTypography.monospaceStats)
                .padding(AppSpacing.xSmall)
                .background(AppColors.surfaceSecondary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusMedium, style: .continuous))
                .frame(maxHeight: 240)

            HStack {
                Button("Paste from Clipboard") {
                    if let string = UIPasteboard.general.string {
                        importText = string
                    }
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Apply Remote SDP") {
                    onApply()
                }
                .buttonStyle(.borderedProminent)
                .disabled(importText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Spacer()
        }
        .padding(AppSpacing.medium)
    }
}
