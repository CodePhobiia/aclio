import SwiftUI

// MARK: - Achievement Card
struct AchievementCard: View {
    let achievement: Achievement
    let isUnlocked: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    private var iconGradient: LinearGradient {
        isUnlocked ? AclioGradients.forAchievement(achievement.gradientId) : LinearGradient(colors: [Color.clear], startPoint: .top, endPoint: .bottom)
    }
    
    var body: some View {
        VStack(spacing: AclioSpacing.space2) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? Color.clear : Color.gray.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .fill(iconGradient)
                    )
                
                Image(systemName: achievement.systemIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isUnlocked ? .white : .gray.opacity(0.5))
            }
            
            // Name
            Text(achievement.name)
                .font(AclioFont.achievementTitle)
                .foregroundColor(isUnlocked ? colors.textPrimary : colors.textMuted)
                .lineLimit(1)
            
            // Description
            Text(achievement.desc)
                .font(AclioFont.achievementDesc)
                .foregroundColor(colors.textMuted)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(AclioSpacing.space3)
        .background(
            RoundedRectangle(cornerRadius: AclioRadius.medium)
                .fill(isUnlocked ? colors.accent.opacity(0.1) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AclioRadius.medium)
                .stroke(isUnlocked ? Color.clear : Color.gray.opacity(0.1), lineWidth: 1)
        )
    }
}

// MARK: - Achievement Badge (Compact)
struct AchievementBadge: View {
    let title: String
    let icon: String
    let gradient: LinearGradient
    
    var body: some View {
        HStack(spacing: AclioSpacing.space2) {
            Text(icon)
                .font(.system(size: 16))
            
            Text(title)
                .font(AclioFont.captionMedium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, AclioSpacing.space3)
        .padding(.vertical, AclioSpacing.space2)
        .background(gradient)
        .cornerRadius(AclioRadius.pill)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            AchievementCard(achievement: Achievement.all[0], isUnlocked: true)
            AchievementCard(achievement: Achievement.all[1], isUnlocked: false)
        }
        
        HStack {
            AchievementBadge(title: "Goal Setter", icon: "🏆", gradient: AclioGradients.achievementPurple)
            AchievementBadge(title: "Streak Champion", icon: "⚡", gradient: AclioGradients.achievementTeal)
        }
    }
    .padding()
    .background(Color.aclioPageBg)
}

