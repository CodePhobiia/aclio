import Foundation

// MARK: - Analytics Event
/// Represents an analytics event to be tracked
struct AnalyticsEvent: Codable {
    let name: String
    let parameters: [String: String]
    let timestamp: Date
    let sessionId: String
    
    init(name: String, parameters: [String: String] = [:]) {
        self.name = name
        self.parameters = parameters
        self.timestamp = Date()
        self.sessionId = AnalyticsService.shared.sessionId
    }
}

// MARK: - Analytics Event Names
/// Centralized event name constants
enum AnalyticsEventName {
    // MARK: - Onboarding
    static let onboardingStarted = "onboarding_started"
    static let onboardingCompleted = "onboarding_completed"
    static let onboardingSkipped = "onboarding_skipped"
    
    // MARK: - Goals
    static let goalCreated = "goal_created"
    static let goalDeleted = "goal_deleted"
    static let goalCompleted = "goal_completed"
    static let goalViewed = "goal_viewed"
    
    // MARK: - Steps
    static let stepCompleted = "step_completed"
    static let stepUncompleted = "step_uncompleted"
    static let stepExpanded = "step_expanded"
    static let stepDoItForMe = "step_do_it_for_me"
    
    // MARK: - Chat
    static let chatStarted = "chat_started"
    static let chatMessageSent = "chat_message_sent"
    
    // MARK: - Premium
    static let paywallViewed = "paywall_viewed"
    static let purchaseStarted = "purchase_started"
    static let purchaseCompleted = "purchase_completed"
    static let purchaseFailed = "purchase_failed"
    static let purchaseRestored = "purchase_restored"
    
    // MARK: - Gamification
    static let dailyBonusClaimed = "daily_bonus_claimed"
    static let levelUp = "level_up"
    static let achievementUnlocked = "achievement_unlocked"
    
    // MARK: - App Lifecycle
    static let appLaunched = "app_launched"
    static let appBackgrounded = "app_backgrounded"
    static let appForegrounded = "app_foregrounded"
    
    // MARK: - Errors
    static let errorOccurred = "error_occurred"
    static let apiError = "api_error"
    
    // MARK: - Settings
    static let themeChanged = "theme_changed"
    static let notificationsToggled = "notifications_toggled"
}

// MARK: - Analytics Parameter Keys
enum AnalyticsParamKey {
    static let goalId = "goal_id"
    static let goalName = "goal_name"
    static let goalCategory = "goal_category"
    static let stepId = "step_id"
    static let stepTitle = "step_title"
    static let progress = "progress"
    static let productId = "product_id"
    static let price = "price"
    static let level = "level"
    static let points = "points"
    static let errorType = "error_type"
    static let errorMessage = "error_message"
    static let theme = "theme"
    static let source = "source"
    static let duration = "duration"
}

// MARK: - Analytics Service
/// Handles all analytics tracking for the app.
/// 
/// This service provides a privacy-first, local analytics implementation.
/// Events are stored locally and can be exported or sent to a backend.
/// 
/// Usage:
/// ```swift
/// AnalyticsService.shared.track(.goalCreated, parameters: [
///     .goalName: "Learn Swift",
///     .goalCategory: "Education"
/// ])
/// ```
@MainActor
final class AnalyticsService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AnalyticsService()
    
    // MARK: - Configuration
    private let maxStoredEvents = 1000
    private let storage = UserDefaults.standard
    private let storageKey = "aclio_analytics_events"
    private let sessionKey = "aclio_analytics_session"
    
    // MARK: - State
    @Published private(set) var isEnabled: Bool = true
    private(set) var sessionId: String
    private var eventQueue: [AnalyticsEvent] = []
    
    // MARK: - User Properties
    private var userProperties: [String: String] = [:]
    
    // MARK: - Initialization
    
    private init() {
        // Generate or restore session ID
        if let existingSession = storage.string(forKey: sessionKey) {
            sessionId = existingSession
        } else {
            sessionId = UUID().uuidString
            storage.set(sessionId, forKey: sessionKey)
        }
        
        loadStoredEvents()
        setDefaultUserProperties()
    }
    
    // MARK: - User Properties
    
    private func setDefaultUserProperties() {
        userProperties["app_version"] = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        userProperties["build_number"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        userProperties["os_version"] = UIDevice.current.systemVersion
        userProperties["device_model"] = UIDevice.current.model
        userProperties["locale"] = Locale.current.identifier
    }
    
    /// Sets a custom user property
    func setUserProperty(_ value: String, forKey key: String) {
        userProperties[key] = value
    }
    
    /// Sets premium status for analytics
    func setPremiumStatus(_ isPremium: Bool) {
        userProperties["is_premium"] = isPremium ? "true" : "false"
    }
    
    // MARK: - Event Tracking
    
    /// Tracks an event with the given name and parameters
    func track(_ eventName: String, parameters: [String: String] = [:]) {
        guard isEnabled else { return }
        
        // Merge with user properties
        var allParams = userProperties
        for (key, value) in parameters {
            allParams[key] = value
        }
        
        let event = AnalyticsEvent(name: eventName, parameters: allParams)
        eventQueue.append(event)
        
        // Debug logging
        #if DEBUG
        print("📊 Analytics: \(eventName)")
        if !parameters.isEmpty {
            print("   Parameters: \(parameters)")
        }
        #endif
        
        // Trim queue if too large
        if eventQueue.count > maxStoredEvents {
            eventQueue.removeFirst(eventQueue.count - maxStoredEvents)
        }
        
        // Save to storage
        saveEvents()
    }
    
    // MARK: - Goal Events
    
    func trackGoalCreated(goalId: Int, goalName: String, category: String?) {
        track(AnalyticsEventName.goalCreated, parameters: [
            AnalyticsParamKey.goalId: String(goalId),
            AnalyticsParamKey.goalName: goalName,
            AnalyticsParamKey.goalCategory: category ?? "uncategorized"
        ])
    }
    
    func trackGoalCompleted(goalId: Int, goalName: String) {
        track(AnalyticsEventName.goalCompleted, parameters: [
            AnalyticsParamKey.goalId: String(goalId),
            AnalyticsParamKey.goalName: goalName
        ])
    }
    
    func trackGoalDeleted(goalId: Int) {
        track(AnalyticsEventName.goalDeleted, parameters: [
            AnalyticsParamKey.goalId: String(goalId)
        ])
    }
    
    // MARK: - Step Events
    
    func trackStepCompleted(goalId: Int, stepId: Int, progress: Int) {
        track(AnalyticsEventName.stepCompleted, parameters: [
            AnalyticsParamKey.goalId: String(goalId),
            AnalyticsParamKey.stepId: String(stepId),
            AnalyticsParamKey.progress: String(progress)
        ])
    }
    
    func trackStepExpanded(goalId: Int, stepId: Int) {
        track(AnalyticsEventName.stepExpanded, parameters: [
            AnalyticsParamKey.goalId: String(goalId),
            AnalyticsParamKey.stepId: String(stepId)
        ])
    }
    
    func trackStepDoItForMe(goalId: Int, stepId: Int) {
        track(AnalyticsEventName.stepDoItForMe, parameters: [
            AnalyticsParamKey.goalId: String(goalId),
            AnalyticsParamKey.stepId: String(stepId)
        ])
    }
    
    // MARK: - Premium Events
    
    func trackPaywallViewed(source: String) {
        track(AnalyticsEventName.paywallViewed, parameters: [
            AnalyticsParamKey.source: source
        ])
    }
    
    func trackPurchaseStarted(productId: String) {
        track(AnalyticsEventName.purchaseStarted, parameters: [
            AnalyticsParamKey.productId: productId
        ])
    }
    
    func trackPurchaseCompleted(productId: String, price: String) {
        track(AnalyticsEventName.purchaseCompleted, parameters: [
            AnalyticsParamKey.productId: productId,
            AnalyticsParamKey.price: price
        ])
    }
    
    func trackPurchaseFailed(productId: String, errorMessage: String) {
        track(AnalyticsEventName.purchaseFailed, parameters: [
            AnalyticsParamKey.productId: productId,
            AnalyticsParamKey.errorMessage: errorMessage
        ])
    }
    
    // MARK: - Error Events
    
    func trackError(_ error: AppError, context: String? = nil) {
        track(AnalyticsEventName.errorOccurred, parameters: [
            AnalyticsParamKey.errorType: error.id,
            AnalyticsParamKey.errorMessage: error.errorDescription ?? "unknown",
            AnalyticsParamKey.source: context ?? "unknown"
        ])
    }
    
    // MARK: - Gamification Events
    
    func trackLevelUp(newLevel: Int, points: Int) {
        track(AnalyticsEventName.levelUp, parameters: [
            AnalyticsParamKey.level: String(newLevel),
            AnalyticsParamKey.points: String(points)
        ])
    }
    
    // MARK: - Session Management
    
    /// Starts a new analytics session
    func startNewSession() {
        sessionId = UUID().uuidString
        storage.set(sessionId, forKey: sessionKey)
        track(AnalyticsEventName.appLaunched)
    }
    
    // MARK: - Privacy Controls
    
    /// Enables or disables analytics tracking
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        storage.set(enabled, forKey: "aclio_analytics_enabled")
        
        if !enabled {
            // Clear stored events when disabled
            clearEvents()
        }
    }
    
    /// Clears all stored analytics data
    func clearEvents() {
        eventQueue.removeAll()
        storage.removeObject(forKey: storageKey)
    }
    
    // MARK: - Persistence
    
    private func saveEvents() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(eventQueue) {
            storage.set(data, forKey: storageKey)
        }
    }
    
    private func loadStoredEvents() {
        let decoder = JSONDecoder()
        if let data = storage.data(forKey: storageKey),
           let events = try? decoder.decode([AnalyticsEvent].self, from: data) {
            eventQueue = events
        }
        
        isEnabled = storage.object(forKey: "aclio_analytics_enabled") as? Bool ?? true
    }
    
    // MARK: - Export
    
    /// Exports all stored events as JSON data
    func exportEvents() -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(eventQueue)
    }
    
    /// Returns event count for a specific event name
    func eventCount(for eventName: String) -> Int {
        eventQueue.filter { $0.name == eventName }.count
    }
    
    /// Returns all events (for debugging)
    var allEvents: [AnalyticsEvent] {
        eventQueue
    }
}

// MARK: - Analytics Integration Protocol
/// Protocol for views/services that want to track analytics
protocol AnalyticsTrackable {
    var analyticsService: AnalyticsService { get }
}

extension AnalyticsTrackable {
    var analyticsService: AnalyticsService {
        AnalyticsService.shared
    }
}

