import Foundation
import Combine

// MARK: - Dashboard View Model
@MainActor
final class DashboardViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let storage = LocalStorageService.shared
    private let gamification = GamificationService.shared
    private let premium = PremiumService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    @Published var goals: [Goal] = []
    @Published var profile: UserProfile = UserProfile()
    @Published var searchQuery: String = ""
    @Published var isDarkMode: Bool = false
    @Published var isRefreshing: Bool = false
    
    // MARK: - Gamification State (forwarded from service)
    @Published var points: Int = 0
    @Published var streak: StreakData = StreakData()
    @Published var dailyBonusClaimed: Bool = false
    @Published var currentLevel: Level = Level.all[0]
    @Published var nextLevel: Level? = Level.all[1]
    @Published var levelProgress: Double = 0
    @Published var showPointsPopup: PointsPopup?
    @Published var showLevelUp: LevelUpData?
    
    // MARK: - Premium State (forwarded from service)
    @Published var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    
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
        observeServices()
    }
    
    // MARK: - Observe Services
    private func observeServices() {
        // Forward all gamification state changes
        gamification.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.points = self.gamification.points
                self.streak = self.gamification.streak
                self.dailyBonusClaimed = self.gamification.dailyBonusClaimed
                self.currentLevel = self.gamification.currentLevel
                self.nextLevel = self.gamification.nextLevel
                self.levelProgress = self.gamification.levelProgress
                self.showPointsPopup = self.gamification.showPointsPopup
                self.showLevelUp = self.gamification.showLevelUp
            }
            .store(in: &cancellables)
        
        // Forward all premium state changes
        premium.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isPremium = self.premium.isPremium
                self.showPaywall = self.premium.showPaywall
            }
            .store(in: &cancellables)
        
        // Initialize with current values
        points = gamification.points
        streak = gamification.streak
        dailyBonusClaimed = gamification.dailyBonusClaimed
        currentLevel = gamification.currentLevel
        nextLevel = gamification.nextLevel
        levelProgress = gamification.levelProgress
        showPointsPopup = gamification.showPointsPopup
        showLevelUp = gamification.showLevelUp
        isPremium = premium.isPremium
        showPaywall = premium.showPaywall
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
            showPaywall = true
            premium.showPaywall = true
        }
    }
    
    func showPremiumPaywall() {
        showPaywall = true
        premium.showPaywall = true
    }
    
    func dismissPaywall() {
        showPaywall = false
        premium.showPaywall = false
    }
    
    func goalsRemaining() -> Int {
        premium.getGoalsRemaining(currentCount: goals.count)
    }
    
    // MARK: - Theme
    func toggleTheme() {
        isDarkMode.toggle()
        storage.saveTheme(isDarkMode)
        // Post notification for app-wide theme change
        NotificationCenter.default.post(name: .themeChanged, object: isDarkMode)
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

