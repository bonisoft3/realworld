import SwiftUI
import RealWorld

@main
struct RealWorldMacApp: App {
    @StateObject private var viewModel: RealWorldViewModel

    init() {
        let app = RealWorldNativeApp()
        app.start()
        _viewModel = StateObject(wrappedValue: RealWorldViewModel(app: app))
    }

    var body: some Scene {
        WindowGroup("Conduit · Omnishell SDUI") {
            RealWorldSwiftUIView(viewModel: viewModel)
                .frame(minWidth: 460, idealWidth: 500, minHeight: 650, idealHeight: 750)
        }
    }
}
