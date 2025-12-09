import Foundation

// MARK: - Storage Keys
private enum StorageKey: String {
    case goals = "aclio_goals"
    case profile = "aclio_profile"
    case onboarded = "aclio_onboarded"
    case theme = "aclio_theme"
    case points = "aclio_points"
    case streak = "aclio_streak"
    case achievements = "aclio_achievements"
    case premium = "aclio_premium"
    case notifications = "aclio_notifications"
    case location = "aclio_location"
    case dailyBonus = "aclio_daily_bonus"
    case doItForMeUses = "aclio_doitforme_uses"
    case expandUses = "aclio_expand_uses"
    case expandedSteps = "aclio_expanded_steps"
}

// MARK: - Local Storage Service
final class LocalStorageService {
    static let shared = LocalStorageService()
    
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {}
    
    // MARK: - Goals
    
    func saveGoals(_ goals: [Goal]) {
        if let data = try? encoder.encode(goals) {
            defaults.set(data, forKey: StorageKey.goals.rawValue)
        }
    }
    
    func loadGoals() -> [Goal] {
        guard let data = defaults.data(forKey: StorageKey.goals.rawValue),
              let goals = try? decoder.decode([Goal].self, from: data) else {
            return []
        }
        return goals
    }
    
    // MARK: - User Profile
    
    func saveProfile(_ profile: UserProfile) {
        if let data = try? encoder.encode(profile) {
            defaults.set(data, forKey: StorageKey.profile.rawValue)
        }
    }
    
    func loadProfile() -> UserProfile? {
        guard let data = defaults.data(forKey: StorageKey.profile.rawValue),
              let profile = try? decoder.decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    // MARK: - Onboarding
    
    var hasOnboarded: Bool {
        get { defaults.bool(forKey: StorageKey.onboarded.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.onboarded.rawValue) }
    }
    
    func completeOnboarding() {
        hasOnboarded = true
    }
    
    func resetOnboarding() {
        hasOnboarded = false
    }
    
    // MARK: - Theme
    
    func saveTheme(_ isDark: Bool) {
        defaults.set(isDark ? "dark" : "light", forKey: StorageKey.theme.rawValue)
    }
    
    func loadTheme() -> Bool {
        defaults.string(forKey: StorageKey.theme.rawValue) == "dark"
    }
    
    // MARK: - Points
    
    func savePoints(_ points: Int) {
        defaults.set(points, forKey: StorageKey.points.rawValue)
    }
    
    func loadPoints() -> Int {
        defaults.integer(forKey: StorageKey.points.rawValue)
    }
    
    // MARK: - Streak
    
    func saveStreak(_ streak: StreakData) {
        if let data = try? encoder.encode(streak) {
            defaults.set(data, forKey: StorageKey.streak.rawValue)
        }
    }
    
    func loadStreak() -> StreakData {
        guard let data = defaults.data(forKey: StorageKey.streak.rawValue),
              let streak = try? decoder.decode(StreakData.self, from: data) else {
            return StreakData()
        }
        return streak
    }
    
    // MARK: - Achievements
    
    func saveAchievements(_ ids: [String]) {
        if let data = try? encoder.encode(ids) {
            defaults.set(data, forKey: StorageKey.achievements.rawValue)
        }
    }
    
    func loadAchievements() -> [String] {
        guard let data = defaults.data(forKey: StorageKey.achievements.rawValue),
              let ids = try? decoder.decode([String].self, from: data) else {
            return []
        }
        return ids
    }
    
    // MARK: - Premium
    
    var isPremium: Bool {
        get { defaults.bool(forKey: StorageKey.premium.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.premium.rawValue) }
    }
    
    // MARK: - Notifications
    
    var notificationsEnabled: Bool {
        get { defaults.bool(forKey: StorageKey.notifications.rawValue) }
        set { defaults.set(newValue, forKey: StorageKey.notifications.rawValue) }
    }
    
    // MARK: - Location
    
    func saveLocation(_ location: LocationData?) {
        if let location = location, let data = try? encoder.encode(location) {
            defaults.set(data, forKey: StorageKey.location.rawValue)
        } else {
            defaults.removeObject(forKey: StorageKey.location.rawValue)
        }
    }
    
    func loadLocation() -> LocationData? {
        guard let data = defaults.data(forKey: StorageKey.location.rawValue),
              let location = try? decoder.decode(LocationData.self, from: data) else {
            return nil
        }
        return location
    }
    
    // MARK: - Daily Bonus
    
    var dailyBonusClaimed: Bool {
        let today = Date().formatted(date: .complete, time: .omitted)
        return defaults.string(forKey: StorageKey.dailyBonus.rawValue) == today
    }
    
    func claimDailyBonus() {
        let today = Date().formatted(date: .complete, time: .omitted)
        defaults.set(today, forKey: StorageKey.dailyBonus.rawValue)
    }
    
    // MARK: - Daily Usage Limits
    
    func getDailyUses(for feature: PremiumFeatureType) -> Int {
        let key = "aclio_\(feature.storageKey)"
        guard let data = defaults.data(forKey: key),
              let usage = try? decoder.decode(DailyUsage.self, from: data),
              usage.isToday else {
            return 0
        }
        return usage.count
    }
    
    func incrementDailyUses(for feature: PremiumFeatureType) -> Int {
        let key = "aclio_\(feature.storageKey)"
        let currentCount = getDailyUses(for: feature)
        let usage = DailyUsage(date: DailyUsage.todayString(), count: currentCount + 1)
        
        if let data = try? encoder.encode(usage) {
            defaults.set(data, forKey: key)
        }
        
        return currentCount + 1
    }
    
    func getRemainingUses(for feature: PremiumFeatureType) -> Int {
        if isPremium { return .max }
        return max(0, feature.dailyLimit - getDailyUses(for: feature))
    }
    
    // MARK: - Expanded Steps Cache
    
    func saveExpandedStep(goalId: Int, stepId: Int, content: String) {
        var cache = loadExpandedStepsCache()
        cache["\(goalId)-\(stepId)"] = content
        
        if let data = try? encoder.encode(cache) {
            defaults.set(data, forKey: StorageKey.expandedSteps.rawValue)
        }
    }
    
    func loadExpandedStep(goalId: Int, stepId: Int) -> String? {
        let cache = loadExpandedStepsCache()
        return cache["\(goalId)-\(stepId)"]
    }
    
    private func loadExpandedStepsCache() -> [String: String] {
        guard let data = defaults.data(forKey: StorageKey.expandedSteps.rawValue),
              let cache = try? decoder.decode([String: String].self, from: data) else {
            return [:]
        }
        return cache
    }
    
    // MARK: - Clear All Data
    
    func clearAllData() {
        let keys: [StorageKey] = [
            .goals, .profile, .onboarded, .theme, .points, .streak,
            .achievements, .premium, .notifications, .location,
            .dailyBonus, .doItForMeUses, .expandUses, .expandedSteps
        ]
        
        keys.forEach { defaults.removeObject(forKey: $0.rawValue) }
    }
}

