import SwiftUI
import Omnishell

@MainActor
public final class RealWorldViewModel: ObservableObject {
    @Published public var currentAst: String = ""
    public let app: RealWorldNativeApp

    public init(app: RealWorldNativeApp) {
        self.app = app
        self.currentAst = app.uiAst
        app.onAstChanged = { [weak self] newAst in
            Task { @MainActor [weak self] in
                self?.currentAst = newAst
            }
        }
    }

    public func dispatch(action: String) {
        app.dispatchAction(action)
    }
}

public struct RealWorldSwiftUIView: View {
    @ObservedObject public var viewModel: RealWorldViewModel
    @StateObject private var formContext = FormContext()

    public init(viewModel: RealWorldViewModel) {
        self.viewModel = viewModel
    }

    private var parsedRootNode: DivNode? {
        guard let data = viewModel.currentAst.data(using: .utf8),
              let card = try? JSONDecoder().decode(DivKitCard.self, from: data),
              let firstState = card.card.states.first else {
            return nil
        }
        return firstState.div
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Sticky Top Navigation Bar (Full width background, centered container)
            if let root = parsedRootNode, let header = root.items?.first {
                DivKitNodeView(node: header) { action in
                    viewModel.dispatch(action: action)
                }
                .environmentObject(formContext)
                .frame(maxWidth: 960)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(Color(divHex: "#FFFFFF"))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(divHex: "#E4E1D9")),
                    alignment: .bottom
                )
            }

            // 2. Main Scrollable Content Area (Centered Reading Measure)
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    if let root = parsedRootNode, let items = root.items, items.count > 1 {
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(items.dropFirst().enumerated()), id: \.offset) { _, child in
                                DivKitNodeView(node: child) { action in
                                    viewModel.dispatch(action: action)
                                }
                                .environmentObject(formContext)
                            }
                        }
                        .frame(maxWidth: 720)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    } else if let root = parsedRootNode {
                        DivKitNodeView(node: root) { action in
                            viewModel.dispatch(action: action)
                        }
                        .environmentObject(formContext)
                        .frame(maxWidth: 720)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Conduit · Omnishell SDUI")
                                .font(.headline)
                            Text(viewModel.currentAst)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color(divHex: "#FBFAF7"))
    }
}
