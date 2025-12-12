import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Type
enum NotificationType: String, CaseIterable {
    case dailyReminder = "daily_reminder"
    case goalDueSoon = "goal_due_soon"
    case goalDueToday = "goal_due_today"
    case streakReminder = "streak_reminder"
    case weeklyProgress = "weekly_progress"
    case achievementUnlocked = "achievement_unlocked"
    case motivational = "motivational"
    
    var title: String {
        switch self {
        case .dailyReminder: return "Time to make progress! 🎯"
        case .goalDueSoon: return "Goal deadline approaching ⏰"
        case .goalDueToday: return "Goal due today! ⚡"
        case .streakReminder: return "Keep your streak alive! 🔥"
        case .weeklyProgress: return "Weekly Progress Update 📊"
        case .achievementUnlocked: return "Achievement Unlocked! 🏆"
        case .motivational: return "You've got this! 💪"
        }
    }
    
    var categoryIdentifier: String {
        "aclio_\(rawValue)"
    }
}

// MARK: - Notification Action
enum NotificationAction: String {
    case openGoal = "OPEN_GOAL"
    case markComplete = "MARK_COMPLETE"
    case snooze = "SNOOZE"
    case dismiss = "DISMISS"
}

// MARK: - Scheduled Notification
struct ScheduledNotification: Codable, Identifiable {
    let id: String
    let type: String
    let goalId: Int?
    let scheduledDate: Date
    var isDelivered: Bool
    
    init(type: NotificationType, goalId: Int? = nil, scheduledDate: Date) {
        self.id = UUID().uuidString
        self.type = type.rawValue
        self.goalId = goalId
        self.scheduledDate = scheduledDate
        self.isDelivered = false
    }
}

// MARK: - Notification Service
/// Manages all local notifications for the app.
///
/// Features:
/// - Daily reminder notifications
/// - Goal due date reminders
/// - Streak maintenance reminders
/// - Motivational notifications
/// - Achievement notifications
///
/// Usage:
/// ```swift
/// NotificationService.shared.scheduleDailyReminder(at: hour: 9, minute: 0)
/// NotificationService.shared.scheduleGoalDueReminder(goal: goal)
/// ```
@MainActor
final class NotificationService: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = NotificationService()
    
    // MARK: - State
    @Published private(set) var isAuthorized: Bool = false
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var dailyReminderEnabled: Bool = false {
        didSet {
            if dailyReminderEnabled != oldValue {
                storage.set(dailyReminderEnabled, forKey: storageKeys.dailyReminderEnabled)
                if dailyReminderEnabled {
                    scheduleDailyReminder()
                } else {
                    cancelDailyReminder()
                }
            }
        }
    }
    @Published var dailyReminderTime: Date = Date() {
        didSet {
            if dailyReminderEnabled {
                scheduleDailyReminder()
            }
        }
    }
    
    // MARK: - Dependencies
    private let center = UNUserNotificationCenter.current()
    private let storage = UserDefaults.standard
    
    private enum storageKeys {
        static let dailyReminderEnabled = "aclio_daily_reminder_enabled"
        static let dailyReminderHour = "aclio_daily_reminder_hour"
        static let dailyReminderMinute = "aclio_daily_reminder_minute"
        static let scheduledNotifications = "aclio_scheduled_notifications"
    }
    
    // MARK: - Motivational Messages
    private let motivationalMessages = [
        "Small progress is still progress. Keep going!",
        "Your future self will thank you for the work you do today.",
        "Every step counts. What will you accomplish today?",
        "Success is the sum of small efforts repeated day after day.",
        "You're closer to your goals than you were yesterday!",
        "The only bad workout is the one that didn't happen.",
        "Dream big, start small, act now.",
        "Consistency beats intensity. Show up today!",
        "Your goals are waiting for you. Let's make progress!",
        "One step at a time leads to miles of progress."
    ]
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        center.delegate = self
        loadSettings()
        checkAuthorization()
        setupCategories()
    }
    
    // MARK: - Authorization
    
    /// Requests notification permission from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
            }
            await checkAuthorization()
            return granted
        } catch {
            print("❌ NotificationService: Authorization request failed - \(error)")
            return false
        }
    }
    
    /// Checks current authorization status
    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            self.authorizationStatus = settings.authorizationStatus
            self.isAuthorized = settings.authorizationStatus == .authorized
        }
    }
    
    private func checkAuthorization() {
        Task {
            await checkAuthorization()
        }
    }
    
    // MARK: - Category Setup
    
    private func setupCategories() {
        // Goal reminder category with actions
        let openAction = UNNotificationAction(
            identifier: NotificationAction.openGoal.rawValue,
            title: "Open Goal",
            options: .foreground
        )
        
        let snoozeAction = UNNotificationAction(
            identifier: NotificationAction.snooze.rawValue,
            title: "Remind Later",
            options: []
        )
        
        let goalCategory = UNNotificationCategory(
            identifier: NotificationType.dailyReminder.categoryIdentifier,
            actions: [openAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        let dueSoonCategory = UNNotificationCategory(
            identifier: NotificationType.goalDueSoon.categoryIdentifier,
            actions: [openAction, snoozeAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([goalCategory, dueSoonCategory])
    }
    
    // MARK: - Settings
    
    private func loadSettings() {
        dailyReminderEnabled = storage.bool(forKey: storageKeys.dailyReminderEnabled)
        
        let hour = storage.integer(forKey: storageKeys.dailyReminderHour)
        let minute = storage.integer(forKey: storageKeys.dailyReminderMinute)
        
        if hour > 0 || minute > 0 {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = hour
            components.minute = minute
            if let date = Calendar.current.date(from: components) {
                dailyReminderTime = date
            }
        } else {
            // Default to 9:00 AM
            var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            components.hour = 9
            components.minute = 0
            if let date = Calendar.current.date(from: components) {
                dailyReminderTime = date
            }
        }
    }
    
    private func saveReminderTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: dailyReminderTime)
        storage.set(components.hour ?? 9, forKey: storageKeys.dailyReminderHour)
        storage.set(components.minute ?? 0, forKey: storageKeys.dailyReminderMinute)
    }
    
    // MARK: - Schedule Daily Reminder
    
    /// Schedules a daily reminder notification
    func scheduleDailyReminder() {
        guard isAuthorized else { return }
        
        // Cancel existing daily reminder
        cancelDailyReminder()
        
        let content = UNMutableNotificationContent()
        content.title = NotificationType.dailyReminder.title
        content.body = motivationalMessages.randomElement() ?? "Time to work on your goals!"
        content.sound = .default
        content.categoryIdentifier = NotificationType.dailyReminder.categoryIdentifier
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: dailyReminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "aclio_daily_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ NotificationService: Failed to schedule daily reminder - \(error)")
            } else {
                print("✅ NotificationService: Daily reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
            }
        }
        
        saveReminderTime()
    }
    
    /// Cancels the daily reminder
    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["aclio_daily_reminder"])
    }
    
    // MARK: - Goal Reminders
    
    /// Schedules reminders for a goal with a due date
    func scheduleGoalReminders(for goal: Goal) {
        guard isAuthorized, let dueDate = goal.dueDate else { return }
        
        // Cancel existing reminders for this goal
        cancelGoalReminders(for: goal.id)
        
        let calendar = Calendar.current
        let now = Date()
        
        // Reminder 3 days before
        if let threeDaysBefore = calendar.date(byAdding: .day, value: -3, to: dueDate),
           threeDaysBefore > now {
            scheduleGoalNotification(
                goal: goal,
                date: threeDaysBefore,
                type: .goalDueSoon,
                body: "\"\(goal.name)\" is due in 3 days. You're \(goal.progress)% complete!"
            )
        }
        
        // Reminder 1 day before
        if let oneDayBefore = calendar.date(byAdding: .day, value: -1, to: dueDate),
           oneDayBefore > now {
            scheduleGoalNotification(
                goal: goal,
                date: oneDayBefore,
                type: .goalDueSoon,
                body: "\"\(goal.name)\" is due tomorrow! Let's finish strong. 💪"
            )
        }
        
        // Reminder on due date morning
        var dueDayComponents = calendar.dateComponents([.year, .month, .day], from: dueDate)
        dueDayComponents.hour = 9
        dueDayComponents.minute = 0
        if let dueDayMorning = calendar.date(from: dueDayComponents),
           dueDayMorning > now {
            scheduleGoalNotification(
                goal: goal,
                date: dueDayMorning,
                type: .goalDueToday,
                body: "\"\(goal.name)\" is due today! You've got this! 🎯"
            )
        }
    }
    
    private func scheduleGoalNotification(goal: Goal, date: Date, type: NotificationType, body: String) {
        let content = UNMutableNotificationContent()
        content.title = type.title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = type.categoryIdentifier
        content.userInfo = ["goalId": goal.id]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date),
            repeats: false
        )
        
        let identifier = "aclio_goal_\(goal.id)_\(type.rawValue)_\(Int(date.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        center.add(request) { error in
            if let error = error {
                print("❌ NotificationService: Failed to schedule goal reminder - \(error)")
            }
        }
    }
    
    /// Cancels all reminders for a specific goal
    func cancelGoalReminders(for goalId: Int) {
        center.getPendingNotificationRequests { requests in
            let goalIdentifiers = requests
                .filter { $0.identifier.contains("aclio_goal_\(goalId)_") }
                .map { $0.identifier }
            
            self.center.removePendingNotificationRequests(withIdentifiers: goalIdentifiers)
        }
    }
    
    // MARK: - Streak Reminder
    
    /// Schedules a streak maintenance reminder
    func scheduleStreakReminder() {
        guard isAuthorized else { return }
        
        // Schedule for 8 PM if user hasn't completed anything today
        var components = DateComponents()
        components.hour = 20
        components.minute = 0
        
        let content = UNMutableNotificationContent()
        content.title = NotificationType.streakReminder.title
        content.body = "Don't lose your streak! Complete a step to keep it going."
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "aclio_streak_reminder",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - Achievement Notification
    
    /// Sends an immediate notification for an unlocked achievement
    func sendAchievementNotification(achievementName: String) {
        guard isAuthorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = NotificationType.achievementUnlocked.title
        content.body = "You've earned: \(achievementName)"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "aclio_achievement_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        center.add(request)
    }
    
    // MARK: - Clear All
    
    /// Removes all pending notifications
    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// Clears delivered notifications
    func clearDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
    
    // MARK: - Badge Management
    
    /// Updates the app badge count
    func setBadgeCount(_ count: Int) {
        Task {
            do {
                try await center.setBadgeCount(count)
            } catch {
                print("❌ NotificationService: Failed to set badge count - \(error)")
            }
        }
    }
    
    /// Clears the app badge
    func clearBadge() {
        setBadgeCount(0)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound, .badge]
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        // Handle notification tap or action
        await MainActor.run {
            switch actionIdentifier {
            case NotificationAction.openGoal.rawValue:
                if let goalId = userInfo["goalId"] as? Int {
                    // Post notification to open goal
                    NotificationCenter.default.post(
                        name: .openGoalFromNotification,
                        object: goalId
                    )
                }
                
            case NotificationAction.snooze.rawValue:
                // Reschedule for 1 hour later
                // Implementation would go here
                break
                
            case UNNotificationDefaultActionIdentifier:
                // User tapped the notification
                if let goalId = userInfo["goalId"] as? Int {
                    NotificationCenter.default.post(
                        name: .openGoalFromNotification,
                        object: goalId
                    )
                }
                
            default:
                break
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openGoalFromNotification = Notification.Name("openGoalFromNotification")
}

