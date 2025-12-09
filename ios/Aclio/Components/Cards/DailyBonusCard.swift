import SwiftUI

// MARK: - Daily Bonus Card
struct DailyBonusCard: View {
    let bonusAmount: Int
    let onClaim: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        Button(action: {
            AclioHaptics.success()
            onClaim()
        }) {
            HStack(spacing: AclioSpacing.space3) {
                // Coin icon
                ZStack {
                    Circle()
                        .fill(colors.goldSoft)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "bitcoinsign.circle.fill")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(colors.gold)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Bonus Available!")
                        .font(AclioFont.cardTitle)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("Claim +\(bonusAmount) points")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                // Claim button
                Text("Claim")
                    .font(AclioFont.buttonSmall)
                    .foregroundColor(.white)
                    .padding(.horizontal, AclioSpacing.space4)
                    .padding(.vertical, AclioSpacing.space2)
                    .background(AclioGradients.primaryOrange)
                    .cornerRadius(AclioRadius.pill)
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AclioRadius.card)
                    .stroke(colors.gold.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(AclioRadius.card)
            .aclioCardShadow(isDark: colorScheme == .dark)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    DailyBonusCard(bonusAmount: 25, onClaim: {})
        .padding()
        .background(Color.aclioPageBg)
}

