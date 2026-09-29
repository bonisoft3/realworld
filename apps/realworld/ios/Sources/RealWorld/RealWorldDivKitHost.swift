import Foundation

public final class RealWorldDivKitHost: @unchecked Sendable {
    public init() {}

    public func parseAstOrFallback(_ astJson: String) -> String {
        guard let data = astJson.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              json["card"] != nil else {
            return renderFallbackErrorScreen("DivKit AST missing 'card' root element or invalid JSON", rawAst: astJson)
        }
        return astJson
    }

    private func renderFallbackErrorScreen(_ errorMessage: String, rawAst: String) -> String {
        let escapedMessage = (try? String(data: JSONEncoder().encode(errorMessage), encoding: .utf8)) ?? "\"Render Error\""
        return """
        {
          "card": {
            "log_id": "error_boundary_fallback",
            "states": [
              {
                "state_id": 0,
                "div": {
                  "type": "container",
                  "orientation": "vertical",
                  "paddings": { "top": 32, "bottom": 32, "left": 16, "right": 16 },
                  "items": [
                    {
                      "type": "text",
                      "text": "Native Render Error",
                      "font_size": 20,
                      "font_weight": "bold",
                      "text_color": "#A93226"
                    },
                    {
                      "type": "text",
                      "text": \(escapedMessage),
                      "font_size": 14,
                      "text_color": "#16181A",
                      "margins": { "top": 8 }
                    }
                  ]
                }
              }
            ]
          }
        }
        """
    }
}
