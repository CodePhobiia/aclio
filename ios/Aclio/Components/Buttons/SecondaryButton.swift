import SwiftUI

// MARK: - Secondary Button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let style: ButtonStyle
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    enum ButtonStyle {
        case outlined
        case ghost
        case destructive
    }
    
    init(
        _ title: String,
        icon: String? = nil,
        style: ButtonStyle = .outlined,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
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
            HStack(spacing: AclioSpacing.space2) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Text(title)
                    .font(AclioFont.buttonMedium)
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: AclioRadius.button)
                    .stroke(borderColor, lineWidth: style == .outlined ? 1.5 : 0)
            )
            .cornerRadius(AclioRadius.button)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .outlined:
            return colors.accent
        case .ghost:
            return colors.textSecondary
        case .destructive:
            return colors.destructive
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .outlined:
            return colors.accentSoft
        case .ghost:
            return .clear
        case .destructive:
            return colors.destructiveSoft
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outlined:
            return colors.accent.opacity(0.3)
        case .ghost:
            return .clear
        case .destructive:
            return colors.destructive.opacity(0.3)
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        SecondaryButton("Outlined Button", icon: "arrow.right", style: .outlined) {}
        
        SecondaryButton("Ghost Button", style: .ghost) {}
        
        SecondaryButton("Delete", icon: "trash", style: .destructive) {}
    }
    .padding()
}


