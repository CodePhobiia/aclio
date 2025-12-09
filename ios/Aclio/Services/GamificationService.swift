import Foundation
import Combine

// MARK: - Gamification Service
final class GamificationService: ObservableObject {
    static let shared = GamificationService()
    
    private let storage = LocalStorageService.shared
    
    // MARK: - Published State
    @Published private(set) var points: Int = 0
    @Published private(set) var streak: StreakData = StreakData()
    @Published private(set) var unlockedAchievements: [String] = []
    @Published var dailyBonusClaimed: Bool = false
    
    // MARK: - UI State
    @Published var showPointsPopup: PointsPopup?
    @Published var showLevelUp: LevelUpData?
    @Published var newAchievement: Achievement?
    
    // MARK: - Computed Properties
    var currentLevel: Level {
        Level.getLevel(for: points)
    }
    
    var nextLevel: Level? {
        Level.getNextLevel(for: points)
    }
    
    var levelProgress: Double {
        Level.getLevelProgress(for: points)
    }
    
    // MARK: - Initialization
    private init() {
        loadState()
    }
    
    private func loadState() {
        points = storage.loadPoints()
        streak = storage.loadStreak()
        unlockedAchievements = storage.loadAchievements()
        dailyBonusClaimed = storage.dailyBonusClaimed
    }
    
    // MARK: - Add Points
    
    @discardableResult
    func addPoints(_ amount: Int, reason: String) -> Int {
        let previousLevel = currentLevel
        points += amount
        storage.savePoints(points)
        
        // Show popup
        showPointsPopup = PointsPopup(amount: amount, reason: reason)
        
        // Check for level up
        let newLevel = currentLevel
        if newLevel.level > previousLevel.level {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showLevelUp = LevelUpData(level: newLevel)
            }
        }
        
        // Auto-dismiss popup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.showPointsPopup = nil
        }
        
        return points
    }
    
    // MARK: - Streak
    
    func updateStreak() {
        let bonus = streak.update()
        storage.saveStreak(streak)
        
        if bonus > 0 {
            addPoints(bonus, reason: "\(streak.current)-day streak!")
        }
    }
    
    // MARK: - Daily Bonus
    
    func claimDailyBonus() -> Bool {
        guard !dailyBonusClaimed else { return false }
        
        storage.claimDailyBonus()
        dailyBonusClaimed = true
        addPoints(PointsConfig.dailyBonus, reason: "Daily login bonus!")
        updateStreak()
        
        return true
    }
    
    // MARK: - Step Completion
    
    func awardStepPoints() {
        addPoints(PointsConfig.stepComplete, reason: "Step completed!")
        updateStreak()
    }
    
    // MARK: - Goal Completion
    
    func awardGoalPoints(isFirstGoal: Bool = false) {
        addPoints(PointsConfig.goalComplete, reason: "Goal achieved!")
        
        if isFirstGoal {
            addPoints(PointsConfig.firstGoal, reason: "First goal bonus!")
        }
    }
    
    // MARK: - Achievements
    
    func checkAchievements(goals: [Goal]) -> [Achievement] {
        let newlyUnlocked = AchievementChecker.checkAll(
            unlockedIds: unlockedAchievements,
            goals: goals,
            streak: streak.current,
            points: points
        )
        
        for achievement in newlyUnlocked {
            unlockedAchievements.append(achievement.id)
            
            // Show achievement notification (staggered)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.newAchievement = achievement
            }
        }
        
        if !newlyUnlocked.isEmpty {
            storage.saveAchievements(unlockedAchievements)
        }
        
        return newlyUnlocked
    }
    
    func dismissAchievement() {
        newAchievement = nil
    }
    
    func dismissLevelUp() {
        showLevelUp = nil
    }
    
    // MARK: - Reset (for testing)
    
    func resetAllProgress() {
        points = 0
        streak = StreakData()
        unlockedAchievements = []
        dailyBonusClaimed = false
        
        storage.savePoints(0)
        storage.saveStreak(StreakData())
        storage.saveAchievements([])
    }
}

