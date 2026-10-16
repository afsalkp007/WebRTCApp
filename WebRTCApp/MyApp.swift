import SwiftUI

@main
struct WebRTCApp: App {
    @State private var viewModel = CallViewModel()

    var body: some Scene {
        WindowGroup {
            MainCallView(viewModel: viewModel)
        }
    }
}
