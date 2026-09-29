import Foundation
import Omnishell

public final class RealWorldDivActionHandler: @unchecked Sendable {
    private let engine: OmnishellEngine

    public init(engine: OmnishellEngine) {
        self.engine = engine
    }

    public func handleAction(_ actionUri: String) -> Bool {
        guard let url = URL(string: actionUri) else {
            fatalError("Malformed action URI: \(actionUri)")
        }

        if url.scheme != "pronto" || url.host != "event" {
            return false
        }

        engine.dispatchAction(actionUri)
        return true
    }
}
