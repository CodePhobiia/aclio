import SwiftUI

// MARK: - Level Card
struct LevelCard: View {
    let level: Level
    let points: Int
    let progress: Double
    let nextLevel: Level?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        VStack(spacing: AclioSpacing.space4) {
            // Header
            HStack {
                // Level badge + info
                HStack(spacing: AclioSpacing.space3) {
                    ZStack {
                        Circle()
                            .fill(colors.accentSoft)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: level.systemIcon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(colors.accent)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Level \(level.level)")
                            .font(AclioFont.levelNumber)
                            .foregroundColor(colors.textMuted)
                        
                        Text(level.name)
                            .font(AclioFont.levelName)
                            .foregroundColor(colors.textPrimary)
                    }
                }
                
                Spacer()
                
                // Points
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(points)")
                        .font(AclioFont.pointsValue)
                        .foregroundColor(colors.accent)
                    
                    Text("points")
                        .font(AclioFont.pointsLabel)
                        .foregroundColor(colors.textMuted)
                }
            }
            
            // Progress bar
            VStack(spacing: AclioSpacing.space2) {
                ProgressBar(progress: progress, gradient: AclioGradients.progressFill)
                
                HStack {
                    Text("\(level.minPoints) XP")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textMuted)
                    
                    Spacer()
                    
                    Text(nextLevel != nil ? "\(nextLevel!.minPoints) XP" : "MAX")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textMuted)
                }
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
        LevelCard(
            level: Level.all[2],
            points: 450,
            progress: 0.5,
            nextLevel: Level.all[3]
        )
        
        LevelCard(
            level: Level.all[9],
            points: 12000,
            progress: 1.0,
            nextLevel: nil
        )
    }
    .padding()
    .background(Color.aclioPageBg)
}


