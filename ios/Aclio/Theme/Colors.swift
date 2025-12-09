import SwiftUI

// MARK: - Aclio Color Palette
extension Color {
    
    // MARK: - Primary Brand Colors
    static let aclioOrange = Color(hex: "FF9F3A")
    static let aclioOrangeDark = Color(hex: "F27C1F")
    static let aclioOrangeLight = Color(hex: "FFBA5C")
    
    // MARK: - Background Colors (Light Mode)
    static let aclioHeaderBg = Color(hex: "0B172A")
    static let aclioPageBg = Color(hex: "F8FAFC")
    static let aclioCardBg = Color.white
    static let aclioPillBg = Color(hex: "F1F5F9")
    static let aclioInputBg = Color(hex: "F1F5F9")
    
    // MARK: - Text Colors (Light Mode)
    static let aclioTextPrimary = Color(hex: "111827")
    static let aclioTextSecondary = Color(hex: "6B7280")
    static let aclioTextMuted = Color(hex: "9CA3AF")
    
    // MARK: - Hero Colors
    static let aclioHeroText = Color.white
    static let aclioHeroTextDim = Color.white.opacity(0.6)
    
    // MARK: - Accent Colors
    static let aclioTeal = Color(hex: "14B8A6")
    static let aclioTealSoft = Color(hex: "14B8A6").opacity(0.1)
    static let aclioTealBg = Color(hex: "E6F7F3")
    
    static let aclioSuccess = Color(hex: "22C55E")
    static let aclioSuccessSoft = Color(hex: "22C55E").opacity(0.1)
    
    static let aclioGold = Color(hex: "FFB347")
    static let aclioGoldSoft = Color(hex: "FFB347").opacity(0.1)
    
    static let aclioPurple = Color(hex: "8B7ED8")
    static let aclioPurpleSoft = Color(hex: "8B7ED8").opacity(0.12)
    static let aclioPurpleBg = Color(hex: "EDE9F8")
    
    static let aclioMint = Color(hex: "4ECDC4")
    static let aclioMintBg = Color(hex: "E5F9F7")
    
    static let aclioPink = Color(hex: "EC4899")
    
    static let aclioRed = Color(hex: "EF4444")
    static let aclioRedSoft = Color(hex: "EF4444").opacity(0.08)
    
    // MARK: - Border Colors
    static let aclioBorder = Color(hex: "E2E8F0")
    static let aclioDashedBorder = Color(hex: "FBBF77")
    
    // MARK: - Progress Bar
    static let aclioProgressBg = Color(hex: "E2E8F0")
    
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Dark Mode Colors
extension Color {
    
    // MARK: - Background Colors (Dark Mode)
    static let aclioDarkBg = Color(hex: "0F172A")
    static let aclioDarkCardBg = Color(hex: "1E293B")
    static let aclioDarkPillBg = Color(hex: "334155")
    static let aclioDarkInputBg = Color(hex: "1E293B")
    
    // MARK: - Text Colors (Dark Mode)
    static let aclioDarkTextPrimary = Color(hex: "F1F5F9")
    static let aclioDarkTextSecondary = Color(hex: "94A3B8")
    static let aclioDarkTextMuted = Color(hex: "64748B")
    
    // MARK: - Accent Colors (Dark Mode - Brighter)
    static let aclioDarkOrange = Color(hex: "FFB347")
    static let aclioDarkOrangeLight = Color(hex: "FFC978")
    static let aclioDarkOrangeSoft = Color(hex: "FFB347").opacity(0.2)
    
    static let aclioDarkTeal = Color(hex: "2DD4BF")
    static let aclioDarkTealSoft = Color(hex: "2DD4BF").opacity(0.15)
    
    static let aclioDarkSuccess = Color(hex: "34D399")
    static let aclioDarkSuccessSoft = Color(hex: "34D399").opacity(0.2)
    
    static let aclioDarkPurple = Color(hex: "A78BFA")
    static let aclioDarkPurpleSoft = Color(hex: "A78BFA").opacity(0.2)
    
    static let aclioDarkRed = Color(hex: "F87171")
    static let aclioDarkRedSoft = Color(hex: "F87171").opacity(0.15)
    
    // MARK: - Border Colors (Dark Mode)
    static let aclioDarkBorder = Color(hex: "334155")
    static let aclioDarkProgressBg = Color(hex: "334155")
}

// MARK: - Semantic Color Provider
struct AclioColors {
    let colorScheme: ColorScheme
    
    init(_ colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }
    
    var isDark: Bool { colorScheme == .dark }
    
    // MARK: - Backgrounds
    var background: Color { isDark ? .aclioDarkBg : .aclioPageBg }
    var cardBackground: Color { isDark ? .aclioDarkCardBg : .aclioCardBg }
    var headerBackground: Color { .aclioHeaderBg }
    var pillBackground: Color { isDark ? .aclioDarkPillBg : .aclioPillBg }
    var inputBackground: Color { isDark ? .aclioDarkInputBg : .aclioInputBg }
    
    // MARK: - Text
    var textPrimary: Color { isDark ? .aclioDarkTextPrimary : .aclioTextPrimary }
    var textSecondary: Color { isDark ? .aclioDarkTextSecondary : .aclioTextSecondary }
    var textMuted: Color { isDark ? .aclioDarkTextMuted : .aclioTextMuted }
    
    // MARK: - Accent
    var accent: Color { isDark ? .aclioDarkOrange : .aclioOrange }
    var accentLight: Color { isDark ? .aclioDarkOrangeLight : .aclioOrangeLight }
    var accentSoft: Color { isDark ? .aclioDarkOrangeSoft : .aclioOrange.opacity(0.1) }
    
    // MARK: - Status
    var success: Color { isDark ? .aclioDarkSuccess : .aclioSuccess }
    var successSoft: Color { isDark ? .aclioDarkSuccessSoft : .aclioSuccessSoft }
    
    var teal: Color { isDark ? .aclioDarkTeal : .aclioTeal }
    var tealSoft: Color { isDark ? .aclioDarkTealSoft : .aclioTealSoft }
    
    var purple: Color { isDark ? .aclioDarkPurple : .aclioPurple }
    var purpleSoft: Color { isDark ? .aclioDarkPurpleSoft : .aclioPurpleSoft }
    
    var destructive: Color { isDark ? .aclioDarkRed : .aclioRed }
    var destructiveSoft: Color { isDark ? .aclioDarkRedSoft : .aclioRedSoft }
    
    var gold: Color { .aclioGold }
    var goldSoft: Color { .aclioGoldSoft }
    
    // MARK: - Borders
    var border: Color { isDark ? .aclioDarkBorder : .aclioBorder }
    var progressBackground: Color { isDark ? .aclioDarkProgressBg : .aclioProgressBg }
}

// MARK: - Environment Key
private struct AclioColorsKey: EnvironmentKey {
    static let defaultValue = AclioColors(.light)
}

extension EnvironmentValues {
    var aclioColors: AclioColors {
        get { self[AclioColorsKey.self] }
        set { self[AclioColorsKey.self] = newValue }
    }
}

// MARK: - Icon Color Combinations (for goal icons)
struct IconColor: Identifiable, Equatable, Codable {
    let id: Int
    let background: String
    let foreground: String
    
    var bgColor: Color { Color(hex: background) }
    var fgColor: Color { Color(hex: foreground) }
    
    static let options: [IconColor] = [
        IconColor(id: 0, background: "FFF3E6", foreground: "FF9F3A"), // Orange
        IconColor(id: 1, background: "EDE9F8", foreground: "8B7ED8"), // Purple
        IconColor(id: 2, background: "FFF4E6", foreground: "F27C1F"), // Deep Orange
        IconColor(id: 3, background: "E6F7F3", foreground: "22C55E"), // Green
    ]
}

