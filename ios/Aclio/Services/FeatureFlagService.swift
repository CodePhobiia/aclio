import Foundation
import Combine
import UIKit
import SwiftUI

// MARK: - Feature Flag
/// Represents a feature that can be toggled on/off
enum FeatureFlag: String, CaseIterable {
    // MARK: - Goal Features
    case aiGoalExpansion = "ai_goal_expansion"
    case aiDoItForMe = "ai_do_it_for_me"
    case goalExtension = "goal_extension"
    case goalDueDates = "goal_due_dates"
    case goalSharing = "goal_sharing"
    
    // MARK: - Chat Features
    case aiChat = "ai_chat"
    case chatStreaming = "chat_streaming"
    
    // MARK: - Gamification Features
    case gamification = "gamification"
    case dailyBonus = "daily_bonus"
    case streaks = "streaks"
    case achievements = "achievements"
    case levels = "levels"
    
    // MARK: - Premium Features
    case premiumSubscription = "premium_subscription"
    case freeTrial = "free_trial"
    
    // MARK: - UI Features
    case darkMode = "dark_mode"
    case animations = "animations"
    case haptics = "haptics"
    
    // MARK: - Analytics & Monitoring
    case analytics = "analytics"
    case crashReporting = "crash_reporting"
    
    // MARK: - Experimental Features
    case newOnboarding = "new_onboarding"
    case betaFeatures = "beta_features"
    case devTools = "dev_tools"
    
    /// Default enabled state for this flag
    var defaultEnabled: Bool {
        switch self {
        // Core features enabled by default
        case .aiGoalExpansion, .aiDoItForMe, .goalExtension, .goalDueDates,
             .aiChat, .chatStreaming,
             .gamification, .dailyBonus, .streaks, .achievements, .levels,
             .premiumSubscription, .freeTrial,
             .darkMode, .animations, .haptics,
             .analytics, .crashReporting:
            return true
            
        // Experimental features disabled by default
        case .goalSharing, .newOnboarding, .betaFeatures, .devTools:
            return false
        }
    }
    
    /// Human-readable name
    var displayName: String {
        switch self {
        case .aiGoalExpansion: return "AI Goal Expansion"
        case .aiDoItForMe: return "AI Do It For Me"
        case .goalExtension: return "Goal Extension"
        case .goalDueDates: return "Goal Due Dates"
        case .goalSharing: return "Goal Sharing"
        case .aiChat: return "AI Chat"
        case .chatStreaming: return "Chat Streaming"
        case .gamification: return "Gamification"
        case .dailyBonus: return "Daily Bonus"
        case .streaks: return "Streaks"
        case .achievements: return "Achievements"
        case .levels: return "Levels"
        case .premiumSubscription: return "Premium Subscription"
        case .freeTrial: return "Free Trial"
        case .darkMode: return "Dark Mode"
        case .animations: return "Animations"
        case .haptics: return "Haptics"
        case .analytics: return "Analytics"
        case .crashReporting: return "Crash Reporting"
        case .newOnboarding: return "New Onboarding (Beta)"
        case .betaFeatures: return "Beta Features"
        case .devTools: return "Developer Tools"
        }
    }
    
    /// Category for grouping in settings
    var category: FlagCategory {
        switch self {
        case .aiGoalExpansion, .aiDoItForMe, .goalExtension, .goalDueDates, .goalSharing:
            return .goals
        case .aiChat, .chatStreaming:
            return .chat
        case .gamification, .dailyBonus, .streaks, .achievements, .levels:
            return .gamification
        case .premiumSubscription, .freeTrial:
            return .premium
        case .darkMode, .animations, .haptics:
            return .ui
        case .analytics, .crashReporting:
            return .monitoring
        case .newOnboarding, .betaFeatures, .devTools:
            return .experimental
        }
    }
    
    enum FlagCategory: String, CaseIterable {
        case goals = "Goals"
        case chat = "Chat"
        case gamification = "Gamification"
        case premium = "Premium"
        case ui = "UI"
        case monitoring = "Monitoring"
        case experimental = "Experimental"
    }
}

// MARK: - Feature Flag Override
struct FeatureFlagOverride: Codable {
    let flag: String
    let enabled: Bool
    let expiresAt: Date?
}

// MARK: - Feature Flag Service
/// Manages feature flags for gradual rollouts and A/B testing.
///
/// Features can be:
/// - Enabled/disabled globally
/// - Overridden locally (for testing)
/// - Rolled out to percentage of users
/// - Time-limited experiments
///
/// Usage:
/// ```swift
/// if FeatureFlagService.shared.isEnabled(.aiChat) {
///     // Show chat feature
/// }
/// ```
@MainActor
final class FeatureFlagService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = FeatureFlagService()
    
    // MARK: - Storage Keys
    private enum StorageKey {
        static let overrides = "aclio_feature_overrides"
        static let remoteFlags = "aclio_remote_flags"
        static let lastFetch = "aclio_flags_last_fetch"
    }
    
    // MARK: - State
    @Published private(set) var overrides: [String: Bool] = [:]
    @Published private(set) var remoteFlags: [String: Bool] = [:]
    
    private let storage = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // User ID for percentage rollouts
    private var userId: String?
    
    // MARK: - Initialization
    
    private init() {
        loadStoredOverrides()
        loadRemoteFlags()
    }
    
    // MARK: - Configuration
    
    /// Sets user ID for percentage-based rollouts
    func setUserId(_ id: String) {
        userId = id
    }
    
    // MARK: - Flag Checking
    
    /// Checks if a feature flag is enabled
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        // Check local overrides first
        if let override = overrides[flag.rawValue] {
            return override
        }
        
        // Check remote configuration
        if let remote = remoteFlags[flag.rawValue] {
            return remote
        }
        
        // Fall back to default
        return flag.defaultEnabled
    }
    
    /// Checks if a feature flag is enabled by raw string key
    func isEnabled(_ key: String) -> Bool {
        if let flag = FeatureFlag(rawValue: key) {
            return isEnabled(flag)
        }
        
        // Check overrides for unknown flags
        if let override = overrides[key] {
            return override
        }
        
        if let remote = remoteFlags[key] {
            return remote
        }
        
        return false
    }
    
    /// Returns the value of a flag (true/false)
    subscript(flag: FeatureFlag) -> Bool {
        isEnabled(flag)
    }
    
    // MARK: - Local Overrides
    
    /// Sets a local override for a feature flag
    func setOverride(_ flag: FeatureFlag, enabled: Bool) {
        overrides[flag.rawValue] = enabled
        saveOverrides()
        objectWillChange.send()
    }
    
    /// Removes a local override
    func removeOverride(_ flag: FeatureFlag) {
        overrides.removeValue(forKey: flag.rawValue)
        saveOverrides()
        objectWillChange.send()
    }
    
    /// Clears all local overrides
    func clearAllOverrides() {
        overrides.removeAll()
        saveOverrides()
        objectWillChange.send()
    }
    
    /// Checks if a flag has a local override
    func hasOverride(_ flag: FeatureFlag) -> Bool {
        overrides[flag.rawValue] != nil
    }
    
    // MARK: - Remote Configuration
    
    /// Fetches feature flags from remote server
    /// In production, this would call your backend API
    func fetchRemoteFlags() async {
        // Placeholder for remote flag fetching
        // In production, you'd call your config service here
        
        // Example implementation:
        /*
        do {
            let url = URL(string: "https://api.aclio.app/config/flags")!
            let (data, _) = try await URLSession.shared.data(from: url)
            let flags = try decoder.decode([String: Bool].self, from: data)
            
            await MainActor.run {
                self.remoteFlags = flags
                self.saveRemoteFlags()
            }
        } catch {
            print("❌ FeatureFlags: Failed to fetch remote flags - \(error)")
        }
        */
        
        storage.set(Date(), forKey: StorageKey.lastFetch)
    }
    
    /// Updates remote flags from a dictionary (for testing or backend push)
    func updateRemoteFlags(_ flags: [String: Bool]) {
        remoteFlags = flags
        saveRemoteFlags()
        objectWillChange.send()
    }
    
    // MARK: - Percentage Rollouts
    
    /// Checks if user is in rollout percentage for a flag
    func isInRollout(flag: FeatureFlag, percentage: Int) -> Bool {
        guard let userId = userId else {
            // No user ID, use device-based rollout
            return isDeviceInRollout(flag: flag, percentage: percentage)
        }
        
        // Hash user ID to get consistent bucket
        let hash = abs(userId.hashValue)
        let bucket = hash % 100
        return bucket < percentage
    }
    
    private func isDeviceInRollout(flag: FeatureFlag, percentage: Int) -> Bool {
        let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let hash = abs((deviceId + flag.rawValue).hashValue)
        let bucket = hash % 100
        return bucket < percentage
    }
    
    // MARK: - Persistence
    
    private func loadStoredOverrides() {
        if let data = storage.data(forKey: StorageKey.overrides),
           let stored = try? decoder.decode([String: Bool].self, from: data) {
            overrides = stored
        }
    }
    
    private func saveOverrides() {
        if let data = try? encoder.encode(overrides) {
            storage.set(data, forKey: StorageKey.overrides)
        }
    }
    
    private func loadRemoteFlags() {
        if let data = storage.data(forKey: StorageKey.remoteFlags),
           let stored = try? decoder.decode([String: Bool].self, from: data) {
            remoteFlags = stored
        }
    }
    
    private func saveRemoteFlags() {
        if let data = try? encoder.encode(remoteFlags) {
            storage.set(data, forKey: StorageKey.remoteFlags)
        }
    }
    
    // MARK: - Debug
    
    /// Returns all flags with their current states
    var allFlags: [(flag: FeatureFlag, enabled: Bool, hasOverride: Bool)] {
        FeatureFlag.allCases.map { flag in
            (flag: flag, enabled: isEnabled(flag), hasOverride: hasOverride(flag))
        }
    }
    
    /// Returns flags grouped by category
    var flagsByCategory: [FeatureFlag.FlagCategory: [(flag: FeatureFlag, enabled: Bool, hasOverride: Bool)]] {
        Dictionary(grouping: allFlags, by: { $0.flag.category })
    }
    
    /// Exports all flag states
    func exportFlags() -> [String: Any] {
        var export: [String: Any] = [:]
        
        for flag in FeatureFlag.allCases {
            export[flag.rawValue] = [
                "enabled": isEnabled(flag),
                "default": flag.defaultEnabled,
                "hasOverride": hasOverride(flag),
                "category": flag.category.rawValue
            ]
        }
        
        return export
    }
}

// MARK: - SwiftUI Property Wrapper
/// Property wrapper for easy feature flag access in views
@propertyWrapper
@MainActor
struct FeatureEnabled: DynamicProperty {
    let flag: FeatureFlag
    @ObservedObject var service = FeatureFlagService.shared
    
    var wrappedValue: Bool {
        service.isEnabled(flag)
    }
    
    init(_ flag: FeatureFlag) {
        self.flag = flag
    }
}

// MARK: - View Modifier for Feature Gating
@MainActor
struct FeatureGateModifier: ViewModifier {
    let flag: FeatureFlag
    let fallback: AnyView?
    @StateObject private var service = FeatureFlagService.shared
    
    func body(content: Content) -> some View {
        if service.isEnabled(flag) {
            content
        } else if let fallback = fallback {
            fallback
        }
    }
}

@MainActor
extension View {
    /// Shows content only if feature flag is enabled
    func featureGated(_ flag: FeatureFlag) -> some View {
        modifier(FeatureGateModifier(flag: flag, fallback: nil))
    }
    
    /// Shows content if feature enabled, otherwise shows fallback
    func featureGated<Fallback: View>(_ flag: FeatureFlag, fallback: Fallback) -> some View {
        modifier(FeatureGateModifier(flag: flag, fallback: AnyView(fallback)))
    }
}

