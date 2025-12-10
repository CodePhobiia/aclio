import SwiftUI

// MARK: - Aclio Typography System
struct AclioFont {
    
    // MARK: - Display / Large Titles
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title1 = Font.system(size: 28, weight: .semibold, design: .default)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // MARK: - Greeting (Dashboard)
    static let greeting = Font.system(size: 28, weight: .semibold, design: .default)
    static let greetingSubtitle = Font.system(size: 15, weight: .regular, design: .default)
    
    // MARK: - Section Headers
    static let sectionTitle = Font.system(size: 17, weight: .semibold, design: .default)
    static let sectionSubtitle = Font.system(size: 14, weight: .regular, design: .default)
    
    // MARK: - Card Content
    static let cardTitle = Font.system(size: 15, weight: .semibold, design: .default)
    static let cardSubtitle = Font.system(size: 13, weight: .regular, design: .default)
    static let cardMeta = Font.system(size: 12, weight: .medium, design: .default)
    
    // MARK: - Body Text
    static let body = Font.system(size: 15, weight: .regular, design: .default)
    static let bodyMedium = Font.system(size: 15, weight: .medium, design: .default)
    static let bodySemibold = Font.system(size: 15, weight: .semibold, design: .default)
    
    // MARK: - Captions & Pills
    static let caption = Font.system(size: 12, weight: .regular, design: .default)
    static let captionMedium = Font.system(size: 12, weight: .medium, design: .default)
    static let pill = Font.system(size: 12, weight: .medium, design: .default)
    
    // MARK: - Buttons
    static let buttonLarge = Font.system(size: 17, weight: .semibold, design: .default)
    static let buttonMedium = Font.system(size: 15, weight: .semibold, design: .default)
    static let buttonSmall = Font.system(size: 13, weight: .semibold, design: .default)
    
    // MARK: - Numbers & Stats
    static let statLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let statMedium = Font.system(size: 24, weight: .bold, design: .rounded)
    static let statSmall = Font.system(size: 18, weight: .bold, design: .rounded)
    
    // MARK: - Input Fields
    static let input = Font.system(size: 16, weight: .regular, design: .default)
    static let inputLabel = Font.system(size: 14, weight: .medium, design: .default)
    static let inputPlaceholder = Font.system(size: 16, weight: .regular, design: .default)
    
    // MARK: - Navigation
    static let navTitle = Font.system(size: 17, weight: .semibold, design: .default)
    static let navButton = Font.system(size: 17, weight: .regular, design: .default)
    
    // MARK: - Welcome / Onboarding
    static let welcomeTitle = Font.system(size: 40, weight: .bold, design: .rounded)
    static let welcomeTagline = Font.system(size: 18, weight: .medium, design: .default)
    static let onboardingTitle = Font.system(size: 26, weight: .bold, design: .default)
    static let onboardingText = Font.system(size: 16, weight: .regular, design: .default)
    
    // MARK: - Chat
    static let chatMessage = Font.system(size: 15, weight: .regular, design: .default)
    static let chatName = Font.system(size: 14, weight: .semibold, design: .default)
    static let chatStatus = Font.system(size: 12, weight: .regular, design: .default)
    
    // MARK: - Step Items
    static let stepTitle = Font.system(size: 15, weight: .semibold, design: .default)
    static let stepDescription = Font.system(size: 14, weight: .regular, design: .default)
    static let stepDuration = Font.system(size: 12, weight: .medium, design: .default)
    static let stepPrefix = Font.system(size: 13, weight: .medium, design: .default)
    
    // MARK: - Level / Gamification
    static let levelNumber = Font.system(size: 13, weight: .medium, design: .default)
    static let levelName = Font.system(size: 16, weight: .semibold, design: .default)
    static let pointsValue = Font.system(size: 20, weight: .bold, design: .rounded)
    static let pointsLabel = Font.system(size: 11, weight: .medium, design: .default)
    
    // MARK: - Achievement
    static let achievementTitle = Font.system(size: 12, weight: .semibold, design: .default)
    static let achievementDesc = Font.system(size: 10, weight: .regular, design: .default)
    
    // MARK: - Paywall
    static let paywallTitle = Font.system(size: 24, weight: .bold, design: .default)
    static let paywallFeatureTitle = Font.system(size: 15, weight: .semibold, design: .default)
    static let paywallFeatureDesc = Font.system(size: 13, weight: .regular, design: .default)
    static let paywallPrice = Font.system(size: 28, weight: .bold, design: .rounded)
    static let paywallPeriod = Font.system(size: 14, weight: .regular, design: .default)
}

// MARK: - Text Style Modifiers
extension View {
    func aclioTextStyle(_ font: Font, color: Color) -> some View {
        self
            .font(font)
            .foregroundColor(color)
    }
}

// MARK: - Line Height Modifier
struct LineHeightModifier: ViewModifier {
    let lineHeight: CGFloat
    let fontSize: CGFloat
    
    func body(content: Content) -> some View {
        content
            .lineSpacing(lineHeight - fontSize)
            .padding(.vertical, (lineHeight - fontSize) / 2)
    }
}

extension View {
    func lineHeight(_ lineHeight: CGFloat, fontSize: CGFloat) -> some View {
        modifier(LineHeightModifier(lineHeight: lineHeight, fontSize: fontSize))
    }
}


