import SwiftUI

/// A visual skin for the game. Purely cosmetic: gameplay never reads these values.
struct Theme: Identifiable, Equatable {
    let id: String
    let name: String
    let background: Color
    let paddle: Color
    let ball: Color
    let net: Color
    /// Scores and labels.
    let text: Color
    /// Buttons and highlights.
    let accent: Color
    /// Draw paddles / ball with a soft glow.
    let glow: Bool
    /// `nil` means the theme is free.
    let productID: String?

    var isFree: Bool { productID == nil }
}

extension Theme {
    static let productPrefix = "com.white-oak-ai.pong.theme."
    /// Non-consumable that unlocks every paid theme (including future ones).
    static let bundleProductID = productPrefix + "all"

    static let classic = Theme(
        id: "classic", name: "Classic",
        background: .black, paddle: .white, ball: .white,
        net: .white.opacity(0.4), text: .white, accent: .white,
        glow: false, productID: nil)

    static let neon = Theme(
        id: "neon", name: "Neon",
        background: Color(hex: 0x0B0221), paddle: Color(hex: 0x00F0FF), ball: Color(hex: 0xFF2BD6),
        net: Color(hex: 0xFF2BD6).opacity(0.45), text: .white, accent: Color(hex: 0x00F0FF),
        glow: true, productID: productPrefix + "neon")

    static let terminal = Theme(
        id: "terminal", name: "Terminal",
        background: Color(hex: 0x021A0A), paddle: Color(hex: 0x33FF66), ball: Color(hex: 0x33FF66),
        net: Color(hex: 0x33FF66).opacity(0.35), text: Color(hex: 0x33FF66), accent: Color(hex: 0x33FF66),
        glow: true, productID: productPrefix + "terminal")

    static let sunset = Theme(
        id: "sunset", name: "Sunset",
        background: Color(hex: 0x2A0A2E), paddle: Color(hex: 0xFF8A3D), ball: Color(hex: 0xFFD166),
        net: Color(hex: 0xFF5E78).opacity(0.45), text: Color(hex: 0xFFE5D0), accent: Color(hex: 0xFF5E78),
        glow: false, productID: productPrefix + "sunset")

    static let ocean = Theme(
        id: "ocean", name: "Ocean",
        background: Color(hex: 0x03203C), paddle: Color(hex: 0x4FC3F7), ball: Color(hex: 0xE0F7FA),
        net: Color(hex: 0x4FC3F7).opacity(0.35), text: Color(hex: 0xE0F7FA), accent: Color(hex: 0x29B6F6),
        glow: false, productID: productPrefix + "ocean")

    static let gold = Theme(
        id: "gold", name: "Gold",
        background: Color(hex: 0x0D0D0D), paddle: Color(hex: 0xD4AF37), ball: Color(hex: 0xFFF1B8),
        net: Color(hex: 0xD4AF37).opacity(0.4), text: Color(hex: 0xFFF1B8), accent: Color(hex: 0xD4AF37),
        glow: true, productID: productPrefix + "gold")

    static let paper = Theme(
        id: "paper", name: "Paper",
        background: Color(hex: 0xF5F1E6), paddle: Color(hex: 0x1B1B1B), ball: Color(hex: 0xC8372D),
        net: Color(hex: 0x1B1B1B).opacity(0.3), text: Color(hex: 0x1B1B1B), accent: Color(hex: 0x1B1B1B),
        glow: false, productID: productPrefix + "paper")

    static let all: [Theme] = [.classic, .neon, .terminal, .sunset, .ocean, .gold, .paper]

    static var paidProductIDs: [String] { all.compactMap(\.productID) + [bundleProductID] }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Environment

private struct ThemeKey: EnvironmentKey {
    static let defaultValue = Theme.classic
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

// MARK: - Shared drawing

extension GraphicsContext {
    /// Fills `path` with `color`, adding a glow when the theme asks for one.
    mutating func fill(_ path: Path, color: Color, theme: Theme) {
        if theme.glow {
            drawLayer { layer in
                layer.addFilter(.shadow(color: color.opacity(0.9), radius: 8))
                layer.fill(path, with: .color(color))
            }
        } else {
            fill(path, with: .color(color))
        }
    }
}
