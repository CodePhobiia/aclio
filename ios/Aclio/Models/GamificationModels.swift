import Foundation

// MARK: - Points Configuration
struct PointsConfig {
    static let stepComplete = 10
    static let goalComplete = 50
    static let dailyBonus = 25
    static let streakBonus = 5 // per day of streak
    static let firstGoal = 30
}

// MARK: - Level Model
struct Level: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let minPoints: Int
    let iconName: String
    
    var level: Int { id }
    
    static let all: [Level] = [
        Level(id: 1, name: "Beginner", minPoints: 0, iconName: "star"),
        Level(id: 2, name: "Explorer", minPoints: 100, iconName: "bolt"),
        Level(id: 3, name: "Achiever", minPoints: 300, iconName: "flame"),
        Level(id: 4, name: "Champion", minPoints: 600, iconName: "trophy"),
        Level(id: 5, name: "Master", minPoints: 1000, iconName: "medal"),
        Level(id: 6, name: "Expert", minPoints: 1500, iconName: "crown"),
        Level(id: 7, name: "Legend", minPoints: 2500, iconName: "diamond"),
        Level(id: 8, name: "Elite", minPoints: 4000, iconName: "sparkles"),
        Level(id: 9, name: "Grandmaster", minPoints: 6000, iconName: "rocket"),
        Level(id: 10, name: "Ultimate", minPoints: 10000, iconName: "scope"),
    ]
    
    var systemIcon: String {
        switch iconName {
        case "star": return "star.fill"
        case "bolt": return "bolt.fill"
        case "flame": return "flame.fill"
        case "trophy": return "trophy.fill"
        case "medal": return "medal.fill"
        case "crown": return "crown.fill"
        case "diamond": return "diamond.fill"
        case "sparkles": return "sparkles"
        case "rocket": return "paperplane.fill"
        case "scope": return "scope"
        default: return "star.fill"
        }
    }
    
    static func getLevel(for points: Int) -> Level {
        for level in all.reversed() {
            if points >= level.minPoints {
                return level
            }
        }
        return all[0]
    }
    
    static func getNextLevel(for points: Int) -> Level? {
        let current = getLevel(for: points)
        guard let index = all.firstIndex(where: { $0.id == current.id }),
              index + 1 < all.count else { return nil }
        return all[index + 1]
    }
    
    static func getLevelProgress(for points: Int) -> Double {
        let current = getLevel(for: points)
        guard let next = getNextLevel(for: points) else { return 1.0 }
        let progressInLevel = Double(points - current.minPoints)
        let levelRange = Double(next.minPoints - current.minPoints)
        return progressInLevel / levelRange
    }
}

// MARK: - Streak Model
struct StreakData: Codable, Equatable {
    var current: Int
    var best: Int
    var lastActive: String? // Date string "Mon Jan 01 2024"
    
    init(current: Int = 0, best: Int = 0, lastActive: String? = nil) {
        self.current = current
        self.best = best
        self.lastActive = lastActive
    }
    
    var todayString: String {
        Date().formatted(date: .complete, time: .omitted)
    }
    
    var yesterdayString: String {
        Calendar.current.date(byAdding: .day, value: -1, to: Date())?.formatted(date: .complete, time: .omitted) ?? ""
    }
    
    var isActiveToday: Bool {
        lastActive == todayString
    }
    
    mutating func update() -> Int {
        let today = todayString
        let yesterday = yesterdayString
        
        if lastActive == today {
            // Already updated today
            return 0
        } else if lastActive == yesterday {
            // Streak continues
            current += 1
            best = max(best, current)
            lastActive = today
            return PointsConfig.streakBonus * current
        } else {
            // Streak broken, start fresh
            current = 1
            lastActive = today
            return 0
        }
    }
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let desc: String
    let iconName: String
    let gradientId: String
    
    var systemIcon: String {
        switch iconName {
        case "star": return "star.fill"
        case "rocket": return "paperplane.fill"
        case "trophy": return "trophy.fill"
        case "flame": return "flame.fill"
        case "zap", "bolt": return "bolt.fill"
        case "target": return "scope"
        case "award", "medal": return "medal.fill"
        case "activity": return "waveform.path.ecg"
        case "gem", "diamond": return "diamond.fill"
        case "coins": return "bitcoinsign.circle.fill"
        case "crown": return "crown.fill"
        case "sparkles": return "sparkles"
        default: return "star.fill"
        }
    }
    
    static let all: [Achievement] = [
        Achievement(id: "first_goal", name: "Goal Setter", desc: "Created your first goal", iconName: "star", gradientId: "purple"),
        Achievement(id: "first_step", name: "First Step", desc: "Completed your first step", iconName: "rocket", gradientId: "green"),
        Achievement(id: "first_complete", name: "Achiever", desc: "Completed your first goal", iconName: "trophy", gradientId: "gold"),
        Achievement(id: "streak_3", name: "On Fire", desc: "3 day streak", iconName: "flame", gradientId: "red"),
        Achievement(id: "streak_7", name: "Unstoppable", desc: "7 day streak", iconName: "bolt", gradientId: "blue"),
        Achievement(id: "five_goals", name: "Ambitious", desc: "Created 5 goals", iconName: "target", gradientId: "pink"),
        Achievement(id: "three_complete", name: "Hat Trick", desc: "Completed 3 goals", iconName: "medal", gradientId: "teal"),
        Achievement(id: "ten_steps", name: "Step Master", desc: "Completed 10 steps", iconName: "activity", gradientId: "indigo"),
        Achievement(id: "fifty_steps", name: "Dedicated", desc: "Completed 50 steps", iconName: "diamond", gradientId: "cyan"),
        Achievement(id: "hundred_points", name: "Century", desc: "Earned 100 points", iconName: "coins", gradientId: "violet"),
        Achievement(id: "five_hundred_points", name: "Elite", desc: "Earned 500 points", iconName: "crown", gradientId: "yellow"),
        Achievement(id: "level_5", name: "Master", desc: "Reached Level 5", iconName: "sparkles", gradientId: "orange"),
    ]
}

// MARK: - Achievement Checker
struct AchievementChecker {
    
    static func check(
        achievementId: String,
        goals: [Goal],
        streak: Int,
        points: Int
    ) -> Bool {
        switch achievementId {
        case "first_goal":
            return goals.count >= 1
        case "first_step":
            return goals.contains { !$0.completedSteps.isEmpty }
        case "first_complete":
            return goals.contains { $0.isCompleted }
        case "streak_3":
            return streak >= 3
        case "streak_7":
            return streak >= 7
        case "five_goals":
            return goals.count >= 5
        case "three_complete":
            return goals.filter { $0.isCompleted }.count >= 3
        case "ten_steps":
            return goals.reduce(0) { $0 + $1.completedSteps.count } >= 10
        case "fifty_steps":
            return goals.reduce(0) { $0 + $1.completedSteps.count } >= 50
        case "hundred_points":
            return points >= 100
        case "five_hundred_points":
            return points >= 500
        case "level_5":
            return Level.getLevel(for: points).level >= 5
        default:
            return false
        }
    }
    
    static func checkAll(
        unlockedIds: [String],
        goals: [Goal],
        streak: Int,
        points: Int
    ) -> [Achievement] {
        var newlyUnlocked: [Achievement] = []
        
        for achievement in Achievement.all {
            guard !unlockedIds.contains(achievement.id) else { continue }
            
            if check(achievementId: achievement.id, goals: goals, streak: streak, points: points) {
                newlyUnlocked.append(achievement)
            }
        }
        
        return newlyUnlocked
    }
}

// MARK: - Points Popup Data
struct PointsPopup: Equatable {
    let amount: Int
    let reason: String
}

// MARK: - Level Up Data
struct LevelUpData: Equatable {
    let level: Level
}


