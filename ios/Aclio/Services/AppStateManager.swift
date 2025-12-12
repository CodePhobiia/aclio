import Foundation
import Combine

// MARK: - App State Manager
/// Centralized state management for the Aclio app.
/// Provides a single source of truth for app-wide state including:
/// - User data (profile, goals)
/// - Premium status
/// - Gamification state (points, streak, level)
/// - Theme preferences
///
/// Usage:
/// ```swift
/// @EnvironmentObject var appStateManager: AppStateManager
/// ```
@MainActor
final class AppStateManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AppStateManager()
    
    // MARK: - Dependencies
    private let storage = LocalStorageService.shared
    private let apiService = ApiService.shared
    private let gamification = GamificationService.shared
    private let premium = PremiumService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - User State
    /// Current user profile
    @Published private(set) var profile: UserProfile?
    
    /// All user goals
    @Published private(set) var goals: [Goal] = []
    
    /// Whether user has completed onboarding
    @Published private(set) var hasOnboarded: Bool = false
    
    // MARK: - Premium State
    /// Whether user has premium subscription
    @Published private(set) var isPremium: Bool = false
    
    /// Whether to show paywall
    @Published var showPaywall: Bool = false
    
    // MARK: - Gamification State
    /// User's total points
    @Published private(set) var points: Int = 0
    
    /// User's current streak data
    @Published private(set) var streak: StreakData = StreakData()
    
    /// Whether daily bonus has been claimed
    @Published private(set) var dailyBonusClaimed: Bool = false
    
    /// User's current level
    @Published private(set) var currentLevel: Level = Level.all[0]
    
    /// Progress to next level (0.0 - 1.0)
    @Published private(set) var levelProgress: Double = 0
    
    /// User's earned achievements
    @Published private(set) var achievements: [String] = []
    
    // MARK: - UI State
    /// Current theme mode
    @Published var isDarkMode: Bool = false
    
    /// Whether data is loading
    @Published private(set) var isLoading: Bool = false
    
    /// Last error that occurred
    @Published var lastError: AppError?
    
    // MARK: - Computed Properties
    
    /// Active (non-completed) goals
    var activeGoals: [Goal] {
        goals.filter { !$0.isCompleted }
    }
    
    /// Completed goals
    var completedGoals: [Goal] {
        goals.filter { $0.isCompleted }
    }
    
    /// Total completed steps across all goals
    var totalCompletedSteps: Int {
        goals.reduce(0) { $0 + $1.completedStepsCount }
    }
    
    /// Total steps across all goals
    var totalSteps: Int {
        goals.reduce(0) { $0 + $1.totalStepsCount }
    }
    
    /// Overall completion percentage
    var overallProgress: Int {
        guard totalSteps > 0 else { return 0 }
        return Int((Double(totalCompletedSteps) / Double(totalSteps)) * 100)
    }
    
    /// Next level to reach
    var nextLevel: Level? {
        gamification.nextLevel
    }
    
    /// Points needed for next level
    var pointsToNextLevel: Int {
        guard let next = nextLevel else { return 0 }
        return next.requiredPoints - points
    }
    
    /// Number of remaining free goals
    var remainingFreeGoals: Int {
        premium.getGoalsRemaining(currentCount: goals.count)
    }
    
    /// Whether user can create a new goal
    var canCreateGoal: Bool {
        premium.canCreateGoal(currentCount: goals.count)
    }
    
    // MARK: - Initialization
    
    private init() {
        loadAllData()
        observeServices()
    }
    
    // MARK: - Service Observation
    
    private func observeServices() {
        // Observe gamification changes
        gamification.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncGamificationState()
            }
            .store(in: &cancellables)
        
        // Observe premium changes
        premium.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.syncPremiumState()
            }
            .store(in: &cancellables)
        
        // Initial sync
        syncGamificationState()
        syncPremiumState()
    }
    
    private func syncGamificationState() {
        points = gamification.points
        streak = gamification.streak
        dailyBonusClaimed = gamification.dailyBonusClaimed
        currentLevel = gamification.currentLevel
        levelProgress = gamification.levelProgress
        achievements = storage.loadAchievements()
    }
    
    private func syncPremiumState() {
        isPremium = premium.isPremium
        showPaywall = premium.showPaywall
    }
    
    // MARK: - Data Loading
    
    /// Loads all data from local storage
    func loadAllData() {
        profile = storage.loadProfile()
        goals = storage.loadGoals()
        hasOnboarded = storage.hasOnboarded
        isDarkMode = storage.loadTheme()
        syncGamificationState()
        syncPremiumState()
    }
    
    /// Refreshes all data (for pull-to-refresh)
    func refreshData() async {
        isLoading = true
        
        // Brief delay for UI feedback
        try? await Task.sleep(nanoseconds: 300_000_000)
        
        loadAllData()
        
        // Check premium status with RevenueCat
        await premium.checkSubscriptionStatus()
        
        isLoading = false
    }
    
    // MARK: - Profile Management
    
    /// Updates user profile
    func updateProfile(_ newProfile: UserProfile) {
        profile = newProfile
        storage.saveProfile(newProfile)
    }
    
    /// Completes onboarding
    func completeOnboarding() {
        hasOnboarded = true
        storage.completeOnboarding()
    }
    
    // MARK: - Goal Management
    
    /// Adds a new goal
    func addGoal(_ goal: Goal) {
        goals.insert(goal, at: 0)
        storage.saveGoals(goals)
        
        // Award points for first goal
        let isFirstGoal = goals.count == 1
        if isFirstGoal {
            gamification.awardGoalPoints(isFirstGoal: true)
        }
        
        _ = gamification.checkAchievements(goals: goals)
    }
    
    /// Updates an existing goal
    func updateGoal(_ goal: Goal) {
        guard let index = goals.firstIndex(where: { $0.id == goal.id }) else { return }
        goals[index] = goal
        storage.saveGoals(goals)
    }
    
    /// Deletes a goal
    func deleteGoal(_ goalId: Int) {
        goals.removeAll { $0.id == goalId }
        storage.saveGoals(goals)
    }
    
    /// Toggles step completion
    func toggleStep(goalId: Int, stepId: Int) {
        guard let index = goals.firstIndex(where: { $0.id == goalId }) else { return }
        
        let wasCompleted = goals[index].isStepCompleted(stepId)
        goals[index].toggleStep(stepId)
        storage.saveGoals(goals)
        
        // Award points if completing (not uncompleting)
        if !wasCompleted {
            gamification.awardStepPoints()
            
            // Check for goal completion
            if goals[index].isCompleted {
                gamification.awardGoalPoints()
            }
            
            _ = gamification.checkAchievements(goals: goals)
        }
    }
    
    /// Gets a specific goal by ID
    func getGoal(by id: Int) -> Goal? {
        goals.first { $0.id == id }
    }
    
    // MARK: - Theme Management
    
    /// Toggles dark mode
    func toggleTheme() {
        isDarkMode.toggle()
        storage.saveTheme(isDarkMode)
        NotificationCenter.default.post(name: .themeChanged, object: isDarkMode)
    }
    
    /// Sets theme mode
    func setTheme(isDark: Bool) {
        isDarkMode = isDark
        storage.saveTheme(isDark)
        NotificationCenter.default.post(name: .themeChanged, object: isDark)
    }
    
    // MARK: - Premium Management
    
    /// Shows the paywall
    func requestPaywall() {
        showPaywall = true
        premium.showPaywall = true
    }
    
    /// Dismisses the paywall
    func dismissPaywall() {
        showPaywall = false
        premium.showPaywall = false
    }
    
    // MARK: - Gamification Actions
    
    /// Claims daily bonus points
    func claimDailyBonus() {
        _ = gamification.claimDailyBonus()
    }
    
    // MARK: - Data Reset
    
    /// Clears all user data (for logout)
    func clearAllData() {
        storage.clearAllData()
        profile = nil
        goals = []
        hasOnboarded = false
        points = 0
        streak = StreakData()
        achievements = []
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let themeChanged = Notification.Name("themeChanged")
    static let goalsUpdated = Notification.Name("goalsUpdated")
    static let profileUpdated = Notification.Name("profileUpdated")
}

