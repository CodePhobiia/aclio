import SwiftUI

// MARK: - Streak Card
struct StreakCard: View {
    let streak: StreakData
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        VStack(spacing: AclioSpacing.space4) {
            // Header
            HStack {
                // Streak icon + info
                HStack(spacing: AclioSpacing.space3) {
                    ZStack {
                        Circle()
                            .fill(Color.aclioRed.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.aclioRed)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Streak")
                            .font(AclioFont.caption)
                            .foregroundColor(colors.textMuted)
                        
                        Text("\(streak.current) day\(streak.current != 1 ? "s" : "")")
                            .font(AclioFont.levelName)
                            .foregroundColor(colors.textPrimary)
                    }
                }
                
                Spacer()
                
                // Best streak
                VStack(alignment: .trailing, spacing: 0) {
                    Text("Best")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textMuted)
                    
                    Text("\(streak.best) days")
                        .font(AclioFont.cardTitle)
                        .foregroundColor(colors.textPrimary)
                }
            }
            
            // Day dots
            HStack(spacing: AclioSpacing.space2) {
                ForEach(0..<7, id: \.self) { index in
                    let isActive = index < streak.current
                    let isToday = (index == streak.current - 1) || (streak.current == 0 && index == 0)
                    
                    Circle()
                        .fill(isActive ? Color.aclioRed : colors.border)
                        .frame(width: isToday && streak.current > 0 ? 12 : 8, height: isToday && streak.current > 0 ? 12 : 8)
                        .overlay(
                            Circle()
                                .stroke(isToday && streak.current > 0 ? Color.aclioRed.opacity(0.3) : .clear, lineWidth: 2)
                        )
                }
                
                Spacer()
            }
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .aclioCardShadow(isDark: colorScheme == .dark)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        StreakCard(streak: StreakData(current: 5, best: 12))
        StreakCard(streak: StreakData(current: 0, best: 3))
    }
    .padding()
    .background(Color.aclioPageBg)
}


