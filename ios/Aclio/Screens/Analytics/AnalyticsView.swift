import SwiftUI

// MARK: - Analytics View
struct AnalyticsView: View {
    let onBack: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private let storage = LocalStorageService.shared
    private let gamification = GamificationService.shared
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    // MARK: - Analytics Data
    private var goals: [Goal] {
        storage.loadGoals()
    }
    
    private var totalGoals: Int {
        goals.count
    }
    
    private var completedGoals: Int {
        goals.filter { $0.isCompleted }.count
    }
    
    private var totalSteps: Int {
        goals.reduce(0) { $0 + $1.steps.count }
    }
    
    private var completedSteps: Int {
        goals.reduce(0) { $0 + $1.completedSteps.count }
    }
    
    private var overallProgress: Int {
        guard totalSteps > 0 else { return 0 }
        return Int((Double(completedSteps) / Double(totalSteps)) * 100)
    }
    
    private var points: Int {
        gamification.points
    }
    
    private var streak: StreakData {
        gamification.streak
    }
    
    private var currentLevel: Level {
        gamification.currentLevel
    }
    
    private var unlockedAchievements: [String] {
        gamification.unlockedAchievements
    }
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView(title: "Analytics", onBack: onBack)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AclioSpacing.sectionGap) {
                        // Overview
                        overviewCard
                        
                        // Stats Grid
                        statsGrid
                        
                        // Level Progress
                        levelSection
                        
                        // Achievements
                        achievementsSection
                        
                        // Completed Goals
                        if completedGoals > 0 {
                            completedGoalsSection
                        }
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space8)
                }
            }
        }
    }
    
    // MARK: - Overview Card
    private var overviewCard: some View {
        HStack(spacing: AclioSpacing.space6) {
            CircleProgressWithLabel(
                progress: Double(overallProgress) / 100,
                size: 100,
                label: "Overall"
            )
            
            VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                Text("Great progress!")
                    .font(AclioFont.title3)
                    .foregroundColor(colors.textPrimary)
                
                Text("You've completed \(completedSteps) steps across \(totalGoals) goals")
                    .font(AclioFont.body)
                    .foregroundColor(colors.textSecondary)
            }
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .aclioCardShadow(isDark: colorScheme == .dark)
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AclioSpacing.space3) {
            StatCard(
                icon: "scope",
                iconBg: colors.accentSoft,
                iconColor: colors.accent,
                value: "\(totalGoals)",
                label: "Total Goals"
            )
            
            StatCard(
                icon: "checkmark",
                iconBg: colors.successSoft,
                iconColor: colors.success,
                value: "\(completedGoals)",
                label: "Completed"
            )
            
            StatCard(
                icon: "waveform.path.ecg",
                iconBg: colors.purpleSoft,
                iconColor: colors.purple,
                value: "\(completedSteps)",
                label: "Steps Done"
            )
            
            StatCard(
                icon: "flame.fill",
                iconBg: Color.aclioRed.opacity(0.1),
                iconColor: .aclioRed,
                value: "\(streak.best)",
                label: "Best Streak"
            )
        }
    }
    
    // MARK: - Level Section
    private var levelSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            Text("Your Level")
                .font(AclioFont.sectionTitle)
                .foregroundColor(colors.textPrimary)
            
            HStack(spacing: AclioSpacing.space4) {
                ZStack {
                    Circle()
                        .fill(colors.accentSoft)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: currentLevel.systemIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(colors.accent)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentLevel.name)
                        .font(AclioFont.cardTitle)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("Level \(currentLevel.level)")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(points)")
                        .font(AclioFont.pointsValue)
                        .foregroundColor(colors.accent)
                    
                    Text("XP")
                        .font(AclioFont.pointsLabel)
                        .foregroundColor(colors.textMuted)
                }
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
            .aclioCardShadow(isDark: colorScheme == .dark)
        }
    }
    
    // MARK: - Achievements Section
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            Text("Achievements (\(unlockedAchievements.count)/\(Achievement.all.count))")
                .font(AclioFont.sectionTitle)
                .foregroundColor(colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AclioSpacing.space3) {
                ForEach(Achievement.all) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: unlockedAchievements.contains(achievement.id)
                    )
                }
            }
        }
    }
    
    // MARK: - Completed Goals Section
    private var completedGoalsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            Text("Completed Goals")
                .font(AclioFont.sectionTitle)
                .foregroundColor(colors.textPrimary)
            
            VStack(spacing: AclioSpacing.space2) {
                ForEach(goals.filter { $0.isCompleted }) { goal in
                    HStack(spacing: AclioSpacing.space3) {
                        ZStack {
                            Circle()
                                .fill(goal.iconColor.bgColor)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: GoalIcons.systemName(for: goal.iconKey))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(goal.iconColor.fgColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(goal.name)
                                .font(AclioFont.cardTitle)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("\(goal.steps.count) steps completed")
                                .font(AclioFont.caption)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("Done")
                                .font(AclioFont.captionMedium)
                        }
                        .foregroundColor(colors.success)
                        .padding(.horizontal, AclioSpacing.space3)
                        .padding(.vertical, AclioSpacing.space1)
                        .background(colors.successSoft)
                        .cornerRadius(AclioRadius.full)
                    }
                    .padding(AclioSpacing.space3)
                    .background(colors.cardBackground)
                    .cornerRadius(AclioRadius.medium)
                }
            }
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let icon: String
    let iconBg: Color
    let iconColor: Color
    let value: String
    let label: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack(spacing: AclioSpacing.space3) {
            ZStack {
                Circle()
                    .fill(iconBg)
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AclioFont.statSmall)
                    .foregroundColor(colors.textPrimary)
                
                Text(label)
                    .font(AclioFont.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AclioSpacing.space3)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.medium)
        .aclioCardShadow(isDark: colorScheme == .dark)
    }
}

// MARK: - Preview
#Preview {
    AnalyticsView(onBack: {})
}

