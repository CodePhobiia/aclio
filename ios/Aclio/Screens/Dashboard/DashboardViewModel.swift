import Foundation
import Combine

// MARK: - Dashboard View Model
@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let storage = LocalStorageService.shared
    private let gamification = GamificationService.shared
    private let premium = PremiumService.shared
    
    // MARK: - Published State
    @Published var goals: [Goal] = []
    @Published var profile: UserProfile = UserProfile()
    @Published var searchQuery: String = ""
    @Published var isDarkMode: Bool = false
    @Published var isRefreshing: Bool = false
    
    // MARK: - Gamification State (from service)
    var points: Int { gamification.points }
    var streak: StreakData { gamification.streak }
    var dailyBonusClaimed: Bool { gamification.dailyBonusClaimed }
    var currentLevel: Level { gamification.currentLevel }
    var nextLevel: Level? { gamification.nextLevel }
    var levelProgress: Double { gamification.levelProgress }
    var showPointsPopup: PointsPopup? { gamification.showPointsPopup }
    var showLevelUp: LevelUpData? { gamification.showLevelUp }
    
    // MARK: - Premium State (from service)
    var isPremium: Bool { premium.isPremium }
    var showPaywall: Bool {
        get { premium.showPaywall }
        set { premium.showPaywall = newValue }
    }
    
    // MARK: - Computed Properties
    var greeting: String {
        UserProfile.greeting()
    }
    
    var displayName: String {
        profile.displayName
    }
    
    var filteredGoals: [Goal] {
        let activeGoals = goals.filter { !$0.isCompleted }
        
        if searchQuery.isEmpty {
            return activeGoals
        }
        
        let query = searchQuery.lowercased()
        return activeGoals.filter { goal in
            goal.name.lowercased().contains(query) ||
            goal.steps.contains { $0.title.lowercased().contains(query) }
        }
    }
    
    var todaysTasks: [FocusTask] {
        goals
            .filter { !$0.isCompleted }
            .compactMap { goal -> FocusTask? in
                guard let nextStep = goal.nextStep else { return nil }
                return FocusTask(step: nextStep, goal: goal)
            }
            .prefix(3)
            .map { $0 }
    }
    
    // MARK: - Initialization
    init() {
        loadData()
    }
    
    // MARK: - Data Loading
    func loadData() {
        goals = storage.loadGoals()
        profile = storage.loadProfile() ?? UserProfile()
        isDarkMode = storage.loadTheme()
    }
    
    func refresh() async {
        isRefreshing = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        loadData()
        isRefreshing = false
    }
    
    // MARK: - Goal Actions
    func setActiveGoal(_ goal: Goal) -> Goal {
        return goal
    }
    
    func deleteGoal(_ goal: Goal) {
        goals.removeAll { $0.id == goal.id }
        storage.saveGoals(goals)
    }
    
    func toggleStep(goalId: Int, stepId: Int) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        
        let wasCompleted = goals[index].isStepCompleted(stepId)
        goals[index].toggleStep(stepId)
        storage.saveGoals(goals)
        
        // Award points if completing (not uncompleting)
        if !wasCompleted {
            gamification.awardStepPoints()
            _ = gamification.checkAchievements(goals: goals)
        }
    }
    
    // MARK: - Premium Actions
    func handlePremiumFeature(onSuccess: @escaping () -> Void) {
        if premium.canCreateGoal(currentCount: goals.count) {
            onSuccess()
        } else {
            premium.showPaywall = true
        }
    }
    
    func goalsRemaining() -> Int {
        premium.getGoalsRemaining(currentCount: goals.count)
    }
    
    // MARK: - Theme
    func toggleTheme() {
        isDarkMode.toggle()
        storage.saveTheme(isDarkMode)
    }
    
    // MARK: - Daily Bonus
    func claimDailyBonus() {
        _ = gamification.claimDailyBonus()
    }
    
    // MARK: - Level Up Dismiss
    func dismissLevelUp() {
        gamification.dismissLevelUp()
    }
}

