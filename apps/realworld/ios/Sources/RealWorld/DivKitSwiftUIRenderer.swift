import SwiftUI

@MainActor
public final class FormContext: ObservableObject {
    @Published public var fields: [String: String] = [:]

    public init() {}

    public func binding(for id: String) -> Binding<String> {
        Binding(
            get: { self.fields[id] ?? "" },
            set: { self.fields[id] = $0 }
        )
    }

    public func reset() {
        fields.removeAll()
    }
}

public struct DivKitCard: Decodable, Sendable {
    public let card: DivCardContent
}

public struct DivCardContent: Decodable, Sendable {
    public let logId: String?
    public let states: [DivState]

    enum CodingKeys: String, CodingKey {
        case logId = "log_id"
        case states
    }
}

public struct DivState: Decodable, Sendable {
    public let stateId: Int?
    public let div: DivNode

    enum CodingKeys: String, CodingKey {
        case stateId = "state_id"
        case div
    }
}

public struct DivAction: Decodable, Sendable {
    public let url: String?
}

public struct DivEdgeInsets: Decodable, Sendable {
    public let left: CGFloat?
    public let right: CGFloat?
    public let top: CGFloat?
    public let bottom: CGFloat?
}

public struct DivBorderStroke: Decodable, Sendable {
    public let color: String?
    public let width: CGFloat?
}

public struct DivBorder: Decodable, Sendable {
    public let cornerRadius: CGFloat?
    public let stroke: DivBorderStroke?

    enum CodingKeys: String, CodingKey {
        case cornerRadius = "corner_radius"
        case stroke
    }
}

public struct DivBackground: Decodable, Sendable {
    public let type: String?
    public let color: String?
}

public struct DivNode: Decodable, Sendable, Identifiable {
    public var idValue: String {
        id ?? "\(type)_\(text?.hashValue ?? 0)_\(hintText?.hashValue ?? 0)_\(items?.count ?? 0)"
    }

    public var id: String?
    public let type: String
    public let orientation: String?
    public let text: String?
    public let hintText: String?
    public let keyboardType: String?
    public let lineCount: Int?
    public let fontFamily: String?
    public let fontSize: CGFloat?
    public let fontWeight: String?
    public let textColor: String?
    public let paddings: DivEdgeInsets?
    public let margins: DivEdgeInsets?
    public let border: DivBorder?
    public let background: [DivBackground]?
    public let actions: [DivAction]?
    public let items: [DivNode]?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case orientation
        case text
        case hintText = "hint_text"
        case keyboardType = "keyboard_type"
        case lineCount = "line_count"
        case fontFamily = "font_family"
        case fontSize = "font_size"
        case fontWeight = "font_weight"
        case textColor = "text_color"
        case paddings
        case margins
        case border
        case background
        case actions
        case items
    }
}

public struct DivKitNodeView: View {
    public let node: DivNode
    public let onAction: (String) -> Void
    @EnvironmentObject private var formContext: FormContext

    public init(node: DivNode, onAction: @escaping (String) -> Void) {
        self.node = node
        self.onAction = onAction
    }

    public var body: some View {
        renderNodeContent()
            .applyMargins(node.margins)
            .applyPaddings(node.paddings)
            .applyBackground(node.background)
            .applyBorder(node.border)
            .applyActions(node.actions, formContext: formContext, onAction: onAction)
    }

    @ViewBuilder
    private func renderNodeContent() -> some View {
        switch node.type {
        case "separator":
            Spacer()
        case "gallery":
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if let items = node.items {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, child in
                            DivKitNodeView(node: child, onAction: onAction)
                        }
                    }
                }
            }
        case "text":
            renderTextView()
        case "input":
            renderInputView()
        case "container":
            renderContainerView()
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func renderTextView() -> some View {
        let rawText = node.text ?? ""
        let weight: Font.Weight = {
            switch node.fontWeight {
            case "bold": return .bold
            case "medium": return .semibold
            default: return .regular
            }
        }()

        let font: Font = {
            let size = node.fontSize ?? 15
            let design: Font.Design = (node.fontFamily == "serif") ? .serif : .default
            return .system(size: size, weight: weight, design: design)
        }()

        let fgColor: Color = {
            if let hex = node.textColor {
                return Color(divHex: hex)
            }
            return Color.primary
        }()

        Text(rawText)
            .font(font)
            .foregroundColor(fgColor)
    }

    @ViewBuilder
    private func renderInputView() -> some View {
        let fieldId = node.id ?? "field"
        let placeholder = node.hintText ?? ""
        let isMultiline = (node.lineCount ?? 1) > 1 || node.keyboardType == "multi_line_text"
        let binding = formContext.binding(for: fieldId)

        let font: Font = {
            let size = node.fontSize ?? 15
            let design: Font.Design = (node.fontFamily == "serif") ? .serif : .default
            let weight: Font.Weight = {
                switch node.fontWeight {
                case "bold": return .bold
                case "medium": return .semibold
                default: return .regular
                }
            }()
            return .system(size: size, weight: weight, design: design)
        }()

        if isMultiline {
            ZStack(alignment: .topLeading) {
                if binding.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(font)
                        .foregroundColor(Color(divHex: "#9AA0A6"))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                TextEditor(text: binding)
                    .font(font)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .frame(minHeight: CGFloat((node.lineCount ?? 8) * 24))
            }
        } else {
            TextField(placeholder, text: binding)
                .font(font)
                .textFieldStyle(.plain)
        }
    }

    @ViewBuilder
    private func renderContainerView() -> some View {
        let isHorizontal = node.orientation == "horizontal"
        if isHorizontal {
            HStack(spacing: 8) {
                if let items = node.items {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, child in
                        DivKitNodeView(node: child, onAction: onAction)
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 8) {
                if let items = node.items {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, child in
                        DivKitNodeView(node: child, onAction: onAction)
                    }
                }
            }
        }
    }
}

private extension View {
    func applyPaddings(_ insets: DivEdgeInsets?) -> some View {
        self.padding(EdgeInsets(
            top: insets?.top ?? 0,
            leading: insets?.left ?? 0,
            bottom: insets?.bottom ?? 0,
            trailing: insets?.right ?? 0
        ))
    }

    func applyMargins(_ insets: DivEdgeInsets?) -> some View {
        self.padding(EdgeInsets(
            top: insets?.top ?? 0,
            leading: insets?.left ?? 0,
            bottom: insets?.bottom ?? 0,
            trailing: insets?.right ?? 0
        ))
    }

    @ViewBuilder
    func applyBackground(_ backgrounds: [DivBackground]?) -> some View {
        if let bg = backgrounds?.first, let hex = bg.color {
            self.background(Color(divHex: hex))
        } else {
            self
        }
    }

    @ViewBuilder
    func applyBorder(_ border: DivBorder?) -> some View {
        let radius = border?.cornerRadius ?? 0
        if let stroke = border?.stroke, let colorHex = stroke.color {
            let strokeColor = Color(divHex: colorHex)
            let strokeWidth = stroke.width ?? 1
            self.clipShape(RoundedRectangle(cornerRadius: radius))
                .overlay(
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
        } else if radius > 0 {
            self.clipShape(RoundedRectangle(cornerRadius: radius))
        } else {
            self
        }
    }

    @ViewBuilder
    func applyActions(_ actions: [DivAction]?, formContext: FormContext, onAction: @escaping (String) -> Void) -> some View {
        if let firstAction = actions?.first, let url = firstAction.url, !url.isEmpty {
            Button(action: {
                var finalUrl = url
                if url == "pronto://event/PUBLISH_ARTICLE" {
                    var queryPairs: [String] = []
                    for (k, v) in formContext.fields {
                        if let ek = k.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                           let ev = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                            queryPairs.append("\(ek)=\(ev)")
                        }
                    }
                    if !queryPairs.isEmpty {
                        finalUrl = "pronto://event/PUBLISH_ARTICLE?" + queryPairs.joined(separator: "&")
                    }
                    formContext.reset()
                }
                onAction(finalUrl)
            }) {
                self
            }
            .buttonStyle(.plain)
        } else {
            self
        }
    }
}

public extension Color {
    init(divHex: String) {
        var cleanHex = divHex.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanHex.hasPrefix("#") {
            cleanHex.removeFirst()
        }
        var rgbValue: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&rgbValue)
        let red, green, blue, alpha: Double
        if cleanHex.count == 8 {
            alpha = Double((rgbValue & 0xFF000000) >> 24) / 255.0
            red = Double((rgbValue & 0x00FF0000) >> 16) / 255.0
            green = Double((rgbValue & 0x0000FF00) >> 8) / 255.0
            blue = Double(rgbValue & 0x000000FF) / 255.0
        } else if cleanHex.count == 6 {
            alpha = 1.0
            red = Double((rgbValue & 0xFF0000) >> 16) / 255.0
            green = Double((rgbValue & 0x00FF00) >> 8) / 255.0
            blue = Double(rgbValue & 0x0000FF) / 255.0
        } else {
            alpha = 1.0; red = 0.0; green = 0.0; blue = 0.0
        }
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
