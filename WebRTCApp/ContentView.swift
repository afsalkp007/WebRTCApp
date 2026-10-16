import SwiftUI

/// Root container view hosting the WebRTC call demonstration with Xcode Canvas previews.
public struct ContentView: View {
    @State private var viewModel = CallViewModel()

    public init() {}

    public var body: some View {
        MainCallView(viewModel: viewModel)
    }
}

// MARK: - Previews

#Preview("Light Mode - Idle") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Dark Mode - Connected Call") {
    let vm = CallViewModel()
    vm.callState = .connected(peerId: "Remote-Peer-Alpha")
    vm.isDataChannelOpen = true
    return MainCallView(viewModel: vm)
        .preferredColorScheme(.dark)
}

#Preview("Landscape Orientation") {
    let vm = CallViewModel()
    vm.callState = .connected(peerId: "Remote-Peer-Beta")
    vm.isDataChannelOpen = true
    return MainCallView(viewModel: vm)
        .previewInterfaceOrientation(.landscapeLeft)
}

#Preview("Dynamic Type - Accessibility XXL") {
    let vm = CallViewModel()
    return MainCallView(viewModel: vm)
        .environment(\.dynamicTypeSize, .accessibility3)
}
