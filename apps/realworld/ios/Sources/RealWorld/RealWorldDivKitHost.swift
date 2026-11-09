import Foundation
import Omnishell

public final class RealWorldDivKitHost: @unchecked Sendable {
    public let delegate = OmnishellDivKitHost()

    public init() {}

    public func parseAstOrFallback(_ astJson: String) -> String {
        if delegate.render(astJson: astJson, onAction: { _ in }) {
            return astJson
        }
        return delegate.lastRenderedAst
    }
}
