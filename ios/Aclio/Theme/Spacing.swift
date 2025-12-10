import SwiftUI

// MARK: - Aclio Spacing System (8pt Grid)
struct AclioSpacing {
    
    // MARK: - Base Units
    static let space1: CGFloat = 4
    static let space2: CGFloat = 8
    static let space3: CGFloat = 12
    static let space4: CGFloat = 16
    static let space5: CGFloat = 20
    static let space6: CGFloat = 24
    static let space8: CGFloat = 32
    static let space10: CGFloat = 40
    static let space12: CGFloat = 48
    
    // MARK: - Semantic Spacing
    static let sectionGap: CGFloat = 16
    static let cardPadding: CGFloat = 16
    static let cardGap: CGFloat = 12
    static let headerOverlap: CGFloat = -32
    
    // MARK: - Screen Padding
    static let screenHorizontal: CGFloat = 20
    static let screenVertical: CGFloat = 16
    
    // MARK: - Component Spacing
    static let buttonPaddingH: CGFloat = 24
    static let buttonPaddingV: CGFloat = 16
    static let inputPaddingH: CGFloat = 16
    static let inputPaddingV: CGFloat = 14
    static let chipPaddingH: CGFloat = 16
    static let chipPaddingV: CGFloat = 8
    
    // MARK: - Icon Sizes
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 20
    static let iconLarge: CGFloat = 24
    static let iconXL: CGFloat = 32
    static let iconXXL: CGFloat = 48
    
    // MARK: - Avatar / Image Sizes
    static let avatarSmall: CGFloat = 32
    static let avatarMedium: CGFloat = 44
    static let avatarLarge: CGFloat = 64
    static let mascotSmall: CGFloat = 40
    static let mascotMedium: CGFloat = 64
    static let mascotLarge: CGFloat = 120
    static let mascotXL: CGFloat = 180
    
    // MARK: - Progress Indicators
    static let progressBarHeight: CGFloat = 6
    static let progressCircleSmall: CGFloat = 32
    static let progressCircleMedium: CGFloat = 56
    static let progressCircleLarge: CGFloat = 100
    static let progressStrokeWidth: CGFloat = 6
    
    // MARK: - Checkbox / Toggle
    static let checkboxSize: CGFloat = 24
    static let toggleWidth: CGFloat = 51
    static let toggleHeight: CGFloat = 31
    
    // MARK: - Tab Bar
    static let tabBarHeight: CGFloat = 56
    
    // MARK: - FAB (Floating Action Button)
    static let fabHeight: CGFloat = 56
    static let fabRadius: CGFloat = 28
}

// MARK: - Aclio Corner Radii
struct AclioRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 100
    
    // MARK: - Semantic Radii
    static let card: CGFloat = 16
    static let button: CGFloat = 14
    static let pill: CGFloat = 12
    static let input: CGFloat = 12
    static let chip: CGFloat = 8
    static let avatar: CGFloat = 100
    static let modal: CGFloat = 24
}

// MARK: - Aclio Shadows
struct AclioShadow {
    
    static let xs = Shadow(color: Color.black.opacity(0.04), radius: 2, x: 0, y: 1)
    static let small = Shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
    static let medium = Shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    static let large = Shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 6)
    static let xl = Shadow(color: Color.black.opacity(0.12), radius: 24, x: 0, y: 8)
    
    // MARK: - Card Shadow
    static let card = Shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
    
    // MARK: - Button Shadow (Orange glow)
    static let buttonOrange = Shadow(color: Color(hex: "FF9F3A").opacity(0.3), radius: 12, x: 0, y: 4)
    
    // MARK: - Dark Mode Shadows
    static let cardDark = Shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 2)
    static let largeDark = Shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 8)
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
}

// MARK: - Shadow View Modifier
extension View {
    func aclioShadow(_ shadow: AclioShadow.Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func aclioCardShadow(isDark: Bool = false) -> some View {
        let shadow = isDark ? AclioShadow.cardDark : AclioShadow.card
        return self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
}

// MARK: - Animation Durations
struct AclioAnimation {
    static let fast: Double = 0.15
    static let normal: Double = 0.25
    static let slow: Double = 0.4
    static let springResponse: Double = 0.5
    static let springDamping: Double = 0.7
    
    static let spring = Animation.spring(response: springResponse, dampingFraction: springDamping)
    static let easeOut = Animation.easeOut(duration: normal)
    static let easeInOut = Animation.easeInOut(duration: normal)
}

// MARK: - Haptic Feedback
struct AclioHaptics {
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}


