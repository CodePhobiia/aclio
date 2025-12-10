import SwiftUI

// MARK: - Dashboard View
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    
    let onNavigateToNewGoal: () -> Void
    let onNavigateToGoalDetail: (Goal) -> Void
    let onNavigateToSettings: () -> Void
    let onNavigateToAnalytics: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            // Page Background
            colors.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero Header (extends into safe area)
                    heroSection
                        .background(
                            GeometryReader { geo in
                                Color.aclioHeaderBg
                                    .frame(height: geo.frame(in: .global).minY > 0 ? geo.frame(in: .global).minY + geo.size.height : geo.size.height)
                                    .offset(y: geo.frame(in: .global).minY > 0 ? -geo.frame(in: .global).minY : 0)
                            }
                        )
                    
                    // Content
                    VStack(spacing: AclioSpacing.sectionGap) {
                        // Premium Banner
                        if !viewModel.isPremium {
                            PremiumBannerCard {
                                viewModel.showPremiumPaywall()
                            }
                            .padding(.horizontal, AclioSpacing.screenHorizontal)
                        }
                        
                        // Search Bar
                        SearchBar(text: $viewModel.searchQuery, placeholder: "Search goals...")
                            .padding(.horizontal, AclioSpacing.screenHorizontal)
                        
                        // Today's Focus
                        if !viewModel.todaysTasks.isEmpty && viewModel.searchQuery.isEmpty {
                            FocusCard(tasks: viewModel.todaysTasks) { task in
                                viewModel.toggleStep(goalId: task.goalId, stepId: task.stepId)
                            }
                            .padding(.horizontal, AclioSpacing.screenHorizontal)
                        }
                        
                        // Active Goals Section
                        goalsSection
                        
                        // Gamification Section (only when not searching)
                        if viewModel.searchQuery.isEmpty {
                            gamificationSection
                        }
                    }
                    .padding(.top, AclioSpacing.space4)
                    .padding(.bottom, AclioSpacing.space10 + 80) // Space for FAB
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            
            // FAB
            VStack {
                Spacer()
                fabButton
            }
            
            // Points Popup
            if let popup = viewModel.showPointsPopup {
                pointsPopup(popup)
            }
            
            // Level Up Modal
            if let levelUp = viewModel.showLevelUp {
                levelUpModal(levelUp)
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(onDismiss: { viewModel.dismissPaywall() })
        }
        .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space4) {
            // Top icons
            HStack {
                Spacer()
                
                HStack(spacing: AclioSpacing.space2) {
                    IconButton(icon: viewModel.isDarkMode ? "sun.max.fill" : "moon.fill", style: .hero) {
                        viewModel.toggleTheme()
                    }
                    
                    IconButton(icon: "chart.bar.fill", style: .hero) {
                        onNavigateToAnalytics()
                    }
                    
                    IconButton(icon: "gearshape.fill", style: .hero) {
                        onNavigateToSettings()
                    }
                }
            }
            .padding(.top, AclioSpacing.space3)
            
            // Greeting
            VStack(alignment: .leading, spacing: AclioSpacing.space1) {
                Text("\(viewModel.greeting), \(viewModel.displayName)!")
                    .font(AclioFont.greeting)
                    .foregroundColor(.aclioHeroText)
                
                Text("Let's make progress on your goals today.")
                    .font(AclioFont.greetingSubtitle)
                    .foregroundColor(.aclioHeroTextDim)
            }
            
            // CTA Button
            Button(action: {
                viewModel.handlePremiumFeature {
                    onNavigateToNewGoal()
                }
            }) {
                HStack(spacing: AclioSpacing.space2) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Create New Goal")
                        .font(AclioFont.buttonMedium)
                }
                .foregroundColor(.aclioHeaderBg)
                .padding(.horizontal, AclioSpacing.space5)
                .padding(.vertical, AclioSpacing.space3)
                .background(Color.white)
                .cornerRadius(AclioRadius.button)
            }
            .padding(.top, AclioSpacing.space2)
        }
        .padding(.horizontal, AclioSpacing.screenHorizontal)
        .padding(.bottom, AclioSpacing.space6)
        .padding(.top, ScreenSize.safeTop)
    }
    
    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            SectionHeader("Active Goals")
                .padding(.horizontal, AclioSpacing.screenHorizontal)
            
            if viewModel.filteredGoals.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: AclioSpacing.cardGap) {
                    ForEach(Array(viewModel.filteredGoals.enumerated()), id: \.element.id) { index, goal in
                        GoalCard(goal: goal, onTap: {
                            onNavigateToGoalDetail(goal)
                        }, onDelete: {
                            viewModel.deleteGoal(goal)
                        })
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AclioSpacing.space4) {
            Image(systemName: viewModel.searchQuery.isEmpty ? "scope" : "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(colors.accent)
            
            Text(viewModel.searchQuery.isEmpty ? "No goals yet" : "No goals found")
                .font(AclioFont.title3)
                .foregroundColor(colors.textPrimary)
            
            Text(viewModel.searchQuery.isEmpty
                 ? "Tap \"New Goal\" to set your first goal and let AI create your action plan!"
                 : "No goals match \"\(viewModel.searchQuery)\". Try a different search.")
                .font(AclioFont.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AclioSpacing.space8)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Gamification Section
    private var gamificationSection: some View {
        VStack(spacing: AclioSpacing.sectionGap) {
            // Level Card
            LevelCard(
                level: viewModel.currentLevel,
                points: viewModel.points,
                progress: viewModel.levelProgress,
                nextLevel: viewModel.nextLevel
            )
            .padding(.horizontal, AclioSpacing.screenHorizontal)
            
            // Daily Bonus
            if !viewModel.dailyBonusClaimed {
                DailyBonusCard(bonusAmount: PointsConfig.dailyBonus) {
                    viewModel.claimDailyBonus()
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
            }
            
            // Streak Card
            StreakCard(streak: viewModel.streak)
                .padding(.horizontal, AclioSpacing.screenHorizontal)
            
            // Progress Hub
            progressHub
            
            // Achievement badges
            achievementBadges
        }
    }
    
    // MARK: - Progress Hub
    private var progressHub: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            Text("Progress Hub")
                .font(AclioFont.cardTitle)
                .foregroundColor(colors.textPrimary)
            
            HStack(spacing: AclioSpacing.space2) {
                HStack(spacing: 4) {
                    Text("🔥")
                    Text("\(viewModel.streak.current)-day streak")
                        .font(AclioFont.captionMedium)
                }
                .padding(.horizontal, AclioSpacing.space3)
                .padding(.vertical, AclioSpacing.space2)
                .background(Color.aclioRed.opacity(0.1))
                .cornerRadius(AclioRadius.full)
                
                HStack(spacing: 4) {
                    Text("⭐")
                    Text("Level \(viewModel.currentLevel.level) \(viewModel.currentLevel.name)")
                        .font(AclioFont.captionMedium)
                }
                .padding(.horizontal, AclioSpacing.space3)
                .padding(.vertical, AclioSpacing.space2)
                .background(colors.goldSoft)
                .cornerRadius(AclioRadius.full)
            }
        }
        .padding(.horizontal, AclioSpacing.screenHorizontal)
    }
    
    // MARK: - Achievement Badges
    private var achievementBadges: some View {
        HStack(spacing: AclioSpacing.space3) {
            AchievementBadge(title: "Goal Setter", icon: "🏆", gradient: AclioGradients.achievementPurple)
            AchievementBadge(title: "Streak Champion", icon: "⚡", gradient: AclioGradients.achievementTeal)
        }
        .padding(.horizontal, AclioSpacing.screenHorizontal)
    }
    
    // MARK: - FAB
    private var fabButton: some View {
        Button(action: {
            viewModel.handlePremiumFeature {
                onNavigateToNewGoal()
            }
        }) {
            HStack(spacing: AclioSpacing.space2) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("New Goal")
                    .font(AclioFont.buttonMedium)
                
                if !viewModel.isPremium && viewModel.goalsRemaining() <= 1 && viewModel.goalsRemaining() > 0 {
                    Text("(\(viewModel.goalsRemaining()) left)")
                        .font(AclioFont.caption)
                        .opacity(0.8)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, AclioSpacing.space6)
            .padding(.vertical, AclioSpacing.space4)
            .background(AclioGradients.primaryOrange)
            .cornerRadius(AclioRadius.full)
            .aclioShadow(AclioShadow.buttonOrange)
        }
        .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space4)
    }
    
    // MARK: - Points Popup
    private func pointsPopup(_ popup: PointsPopup) -> some View {
        VStack {
            HStack(spacing: AclioSpacing.space2) {
                Image(systemName: "bitcoinsign.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.aclioGold)
                
                Text(popup.reason)
                    .font(AclioFont.bodyMedium)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, AclioSpacing.space5)
            .padding(.vertical, AclioSpacing.space3)
            .background(Color.black.opacity(0.8))
            .cornerRadius(AclioRadius.full)
            
            Spacer()
        }
        .padding(.top, ScreenSize.safeTop + AclioSpacing.space8)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(), value: popup.amount)
    }
    
    // MARK: - Level Up Modal
    private func levelUpModal(_ data: LevelUpData) -> some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissLevelUp()
                }
            
            VStack(spacing: AclioSpacing.space6) {
                ZStack {
                    Circle()
                        .fill(AclioGradients.levelUpGlow)
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: data.level.systemIcon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(colors.accent)
                }
                
                Text("Level Up!")
                    .font(AclioFont.title1)
                    .foregroundColor(colors.textPrimary)
                
                Text("You reached Level \(data.level.level): \(data.level.name)")
                    .font(AclioFont.body)
                    .foregroundColor(colors.textSecondary)
                
                HStack(spacing: AclioSpacing.space2) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(colors.gold)
                    Text("New title unlocked!")
                        .font(AclioFont.bodyMedium)
                        .foregroundColor(colors.textPrimary)
                }
                .padding(.horizontal, AclioSpacing.space4)
                .padding(.vertical, AclioSpacing.space3)
                .background(colors.goldSoft)
                .cornerRadius(AclioRadius.medium)
                
                PrimaryButton("Awesome!") {
                    viewModel.dismissLevelUp()
                }
            }
            .padding(AclioSpacing.space8)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.xxl)
            .padding(.horizontal, AclioSpacing.space8)
        }
    }
}

// MARK: - Preview
#Preview {
    DashboardView(
        onNavigateToNewGoal: {},
        onNavigateToGoalDetail: { _ in },
        onNavigateToSettings: {},
        onNavigateToAnalytics: {}
    )
}

