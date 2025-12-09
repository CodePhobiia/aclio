import SwiftUI

// MARK: - Aclio Gradient Definitions
struct AclioGradients {
    
    // MARK: - Primary Brand Gradients
    static let primaryOrange = LinearGradient(
        colors: [Color(hex: "FFBA5C"), Color(hex: "FF9632")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let premiumOrange = LinearGradient(
        colors: [Color(hex: "FFB347"), Color(hex: "FF9F3A")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Background Gradients
    static let pageBackground = LinearGradient(
        colors: [Color(hex: "F8FAFC"), Color(hex: "EEF4FA")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let darkPageBackground = LinearGradient(
        colors: [Color(hex: "0F172A"), Color(hex: "0A0F1A")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let heroBackground = LinearGradient(
        colors: [Color(hex: "0B172A"), Color(hex: "162236")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Card Gradients (Subtle)
    static let cardSubtle = LinearGradient(
        colors: [Color.white, Color(hex: "FAFBFC")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let darkCardSubtle = LinearGradient(
        colors: [Color(hex: "1E293B"), Color(hex: "1A2433")],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Achievement Gradients (from gamification.js)
    static let achievementPurple = LinearGradient(
        colors: [Color(hex: "8B5CF6"), Color(hex: "6D28D9")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementGreen = LinearGradient(
        colors: [Color(hex: "10B981"), Color(hex: "059669")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementGold = LinearGradient(
        colors: [Color(hex: "F59E0B"), Color(hex: "D97706")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementRed = LinearGradient(
        colors: [Color(hex: "EF4444"), Color(hex: "DC2626")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementBlue = LinearGradient(
        colors: [Color(hex: "3B82F6"), Color(hex: "1D4ED8")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementPink = LinearGradient(
        colors: [Color(hex: "EC4899"), Color(hex: "DB2777")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementTeal = LinearGradient(
        colors: [Color(hex: "14B8A6"), Color(hex: "0D9488")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementIndigo = LinearGradient(
        colors: [Color(hex: "6366F1"), Color(hex: "4F46E5")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementCyan = LinearGradient(
        colors: [Color(hex: "0EA5E9"), Color(hex: "0284C7")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementViolet = LinearGradient(
        colors: [Color(hex: "A855F7"), Color(hex: "9333EA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementYellow = LinearGradient(
        colors: [Color(hex: "FACC15"), Color(hex: "EAB308")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let achievementOrange = LinearGradient(
        colors: [Color(hex: "F97316"), Color(hex: "EA580C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Paywall Card Gradient
    static let paywallCard = LinearGradient(
        colors: [Color(hex: "FF9F3A"), Color(hex: "F27C1F")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Button Shimmer Effect
    static let buttonShimmer = LinearGradient(
        colors: [
            Color.white.opacity(0),
            Color.white.opacity(0.3),
            Color.white.opacity(0)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Progress Bar Gradient
    static let progressFill = LinearGradient(
        colors: [Color(hex: "FF9F3A"), Color(hex: "FFB347")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let progressFillTeal = LinearGradient(
        colors: [Color(hex: "14B8A6"), Color(hex: "2DD4BF")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let progressFillSuccess = LinearGradient(
        colors: [Color(hex: "22C55E"), Color(hex: "34D399")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Level Up Glow
    static let levelUpGlow = RadialGradient(
        colors: [Color(hex: "FFB347").opacity(0.4), Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 150
    )
    
    // MARK: - Mascot Glow
    static let mascotGlow = RadialGradient(
        colors: [Color(hex: "FF9F3A").opacity(0.2), Color.clear],
        center: .center,
        startRadius: 0,
        endRadius: 100
    )
}

// MARK: - Gradient Helper for Achievements
extension AclioGradients {
    static func forAchievement(_ gradientId: String) -> LinearGradient {
        switch gradientId {
        case "purple": return achievementPurple
        case "green": return achievementGreen
        case "gold", "amber": return achievementGold
        case "red": return achievementRed
        case "blue": return achievementBlue
        case "pink": return achievementPink
        case "teal": return achievementTeal
        case "indigo": return achievementIndigo
        case "cyan": return achievementCyan
        case "violet": return achievementViolet
        case "yellow": return achievementYellow
        case "orange": return achievementOrange
        default: return achievementPurple
        }
    }
}

// MARK: - Animated Gradient Background
struct AnimatedGradientBackground: View {
    @State private var animateGradient = false
    let colors: [Color]
    
    init(_ colors: [Color] = [Color(hex: "0B172A"), Color(hex: "1E3A5F")]) {
        self.colors = colors
    }
    
    var body: some View {
        LinearGradient(
            colors: colors,
            startPoint: animateGradient ? .topLeading : .bottomLeading,
            endPoint: animateGradient ? .bottomTrailing : .topTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                animateGradient.toggle()
            }
        }
    }
}

