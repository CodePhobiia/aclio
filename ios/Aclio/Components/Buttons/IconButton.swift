import SwiftUI

// MARK: - Icon Button
struct IconButton: View {
    let icon: String
    let size: ButtonSize
    let style: ButtonStyle
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    enum ButtonSize {
        case small
        case medium
        case large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 40
            case .large: return 48
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 22
            }
        }
    }
    
    enum ButtonStyle {
        case filled
        case ghost
        case hero // For header buttons on dark background
    }
    
    init(
        icon: String,
        size: ButtonSize = .medium,
        style: ButtonStyle = .ghost,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        Button(action: {
            AclioHaptics.light()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
                .frame(width: size.dimension, height: size.dimension)
                .background(backgroundColor)
                .cornerRadius(AclioRadius.small)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled:
            return colors.textPrimary
        case .ghost:
            return colors.textSecondary
        case .hero:
            return .white.opacity(0.8)
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .filled:
            return colors.pillBackground
        case .ghost:
            return .clear
        case .hero:
            return .white.opacity(0.1)
        }
    }
}

// MARK: - Back Button
struct BackButton: View {
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: {
            AclioHaptics.light()
            action()
        }) {
            Image(systemName: "arrow.left")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AclioColors(colorScheme).textPrimary)
                .frame(width: 40, height: 40)
                .background(AclioColors(colorScheme).pillBackground)
                .cornerRadius(AclioRadius.small)
                .aclioShadow(AclioShadow.xs)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 12) {
            IconButton(icon: "sun.max.fill", size: .small, style: .ghost) {}
            IconButton(icon: "moon.fill", size: .medium, style: .filled) {}
            IconButton(icon: "gearshape.fill", size: .large, style: .ghost) {}
        }
        
        HStack(spacing: 12) {
            BackButton {}
            
            IconButton(icon: "chart.bar.fill", style: .hero) {}
                .background(Color.aclioHeaderBg)
                .cornerRadius(8)
        }
    }
    .padding()
}


