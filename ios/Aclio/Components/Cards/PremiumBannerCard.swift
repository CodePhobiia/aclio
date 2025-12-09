import SwiftUI

// MARK: - Premium Banner Card
struct PremiumBannerCard: View {
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        Button(action: {
            AclioHaptics.light()
            onTap()
        }) {
            HStack(spacing: AclioSpacing.space3) {
                // Mascot
                Image("mascot-face")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Premium")
                        .font(AclioFont.cardTitle)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("3-day free trial")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                // CTA
                Text("Start free trial")
                    .font(AclioFont.buttonSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, AclioSpacing.space3)
                    .padding(.vertical, AclioSpacing.space2)
                    .background(AclioGradients.primaryOrange)
                    .cornerRadius(AclioRadius.pill)
            }
            .padding(AclioSpacing.cardPadding)
            .background(
                LinearGradient(
                    colors: [colors.accentSoft, colors.cardBackground],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AclioRadius.card)
                    .stroke(colors.accent.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(AclioRadius.card)
            .aclioCardShadow(isDark: colorScheme == .dark)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    PremiumBannerCard(onTap: {})
        .padding()
        .background(Color.aclioPageBg)
}

