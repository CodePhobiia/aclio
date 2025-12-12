import Foundation
import SwiftUI

// MARK: - String Localization Extension
extension String {
    /// Returns the localized version of this string
    /// Usage: "common.ok".localized
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    /// Returns the localized version with arguments
    /// Usage: "error.message".localized(with: errorCode, description)
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}

// MARK: - Localized Text View
/// A SwiftUI view that displays localized text
/// Usage: LocalizedText("common.ok")
struct LocalizedText: View {
    let key: String
    let arguments: [CVarArg]
    
    init(_ key: String, _ arguments: CVarArg...) {
        self.key = key
        self.arguments = arguments
    }
    
    var body: some View {
        if arguments.isEmpty {
            Text(key.localized)
        } else {
            Text(String(format: key.localized, arguments: arguments))
        }
    }
}

// MARK: - Localization Keys
/// Centralized namespace for all localization keys
/// Usage: L10n.Common.ok.localized
enum L10n {
    
    enum Common {
        static let ok = "common.ok"
        static let cancel = "common.cancel"
        static let save = "common.save"
        static let delete = "common.delete"
        static let edit = "common.edit"
        static let done = "common.done"
        static let next = "common.next"
        static let back = "common.back"
        static let skip = "common.skip"
        static let retry = "common.retry"
        static let loading = "common.loading"
        static let error = "common.error"
        static let success = "common.success"
    }
    
    enum Onboarding {
        static let welcomeTitle = "onboarding.welcome.title"
        static let welcomeSubtitle = "onboarding.welcome.subtitle"
        static let getStarted = "onboarding.welcome.getStarted"
        static let feature1Title = "onboarding.feature1.title"
        static let feature1Description = "onboarding.feature1.description"
        static let feature2Title = "onboarding.feature2.title"
        static let feature2Description = "onboarding.feature2.description"
        static let feature3Title = "onboarding.feature3.title"
        static let feature3Description = "onboarding.feature3.description"
    }
    
    enum Profile {
        static let setupTitle = "profile.setup.title"
        static let nameLabel = "profile.setup.name.label"
        static let namePlaceholder = "profile.setup.name.placeholder"
        static let ageLabel = "profile.setup.age.label"
        static let agePlaceholder = "profile.setup.age.placeholder"
        static let genderLabel = "profile.setup.gender.label"
        static let continueButton = "profile.setup.continue"
    }
    
    enum Dashboard {
        static let greetingMorning = "dashboard.greeting.morning"
        static let greetingAfternoon = "dashboard.greeting.afternoon"
        static let greetingEvening = "dashboard.greeting.evening"
        static let subtitle = "dashboard.subtitle"
        static let createGoal = "dashboard.createGoal"
        static let newGoal = "dashboard.newGoal"
        static let activeGoals = "dashboard.activeGoals"
        static let searchPlaceholder = "dashboard.searchPlaceholder"
        static let noGoalsTitle = "dashboard.noGoals.title"
        static let noGoalsSubtitle = "dashboard.noGoals.subtitle"
        static let noResultsTitle = "dashboard.noResults.title"
        static let noResultsSubtitle = "dashboard.noResults.subtitle"
    }
    
    enum NewGoal {
        static let title = "newGoal.title"
        static let placeholder = "newGoal.placeholder"
        static let suggestions = "newGoal.suggestions"
        static let customize = "newGoal.customize"
        static let icon = "newGoal.icon"
        static let color = "newGoal.color"
        static let dueDate = "newGoal.dueDate"
        static let frequency = "newGoal.frequency"
        static let frequencyDaily = "newGoal.frequency.daily"
        static let frequencyWeekly = "newGoal.frequency.weekly"
        static let frequencyMonthly = "newGoal.frequency.monthly"
        static let frequencyAny = "newGoal.frequency.any"
        static let generate = "newGoal.generate"
        static let generating = "newGoal.generating"
    }
    
    enum GoalDetail {
        static let progress = "goalDetail.progress"
        static let steps = "goalDetail.steps"
        static let completed = "goalDetail.completed"
        static let nextStep = "goalDetail.nextStep"
        static let expand = "goalDetail.expand"
        static let doItForMe = "goalDetail.doItForMe"
        static let viewExpanded = "goalDetail.viewExpanded"
        static let extend = "goalDetail.extend"
        static let delete = "goalDetail.delete"
        static let deleteConfirmTitle = "goalDetail.deleteConfirm.title"
        static let deleteConfirmMessage = "goalDetail.deleteConfirm.message"
        static let celebrateTitle = "goalDetail.celebrate.title"
        static let celebrateMessage = "goalDetail.celebrate.message"
    }
    
    enum Chat {
        static let title = "chat.title"
        static let subtitle = "chat.subtitle"
        static let inputPlaceholder = "chat.inputPlaceholder"
        static let quickMotivation = "chat.quickPrompt.motivation"
        static let quickFocus = "chat.quickPrompt.focus"
        static let quickConsistency = "chat.quickPrompt.consistency"
        static let quickTips = "chat.quickPrompt.tips"
    }
    
    enum Settings {
        static let title = "settings.title"
        static let profile = "settings.profile"
        static let editProfile = "settings.editProfile"
        static let appearance = "settings.appearance"
        static let darkMode = "settings.darkMode"
        static let notifications = "settings.notifications"
        static let premium = "settings.premium"
        static let restore = "settings.restore"
        static let legal = "settings.legal"
        static let privacy = "settings.privacy"
        static let terms = "settings.terms"
        static let about = "settings.about"
        static let version = "settings.version"
        static let logout = "settings.logout"
        static let deleteAccount = "settings.deleteAccount"
    }
    
    enum Premium {
        static let title = "premium.title"
        static let subtitle = "premium.subtitle"
        static let feature1 = "premium.feature1"
        static let feature2 = "premium.feature2"
        static let feature3 = "premium.feature3"
        static let feature4 = "premium.feature4"
        static let weekly = "premium.weekly"
        static let monthly = "premium.monthly"
        static let yearly = "premium.yearly"
        static let bestValue = "premium.bestValue"
        static let freeTrial = "premium.freeTrial"
        static let subscribe = "premium.subscribe"
        static let restore = "premium.restore"
        static let terms = "premium.terms"
        static let privacy = "premium.privacy"
    }
    
    enum Gamification {
        static let level = "gamification.level"
        static let points = "gamification.points"
        static let streak = "gamification.streak"
        static let dailyBonus = "gamification.dailyBonus"
        static let claimBonus = "gamification.claimBonus"
        static let levelUpTitle = "gamification.levelUp.title"
        static let levelUpMessage = "gamification.levelUp.message"
        static let progressHub = "gamification.progressHub"
    }
    
    enum Error {
        static let network = "error.network"
        static let server = "error.server"
        static let timeout = "error.timeout"
        static let rateLimited = "error.rateLimited"
        static let validation = "error.validation"
        static let unknown = "error.unknown"
    }
    
    enum Accessibility {
        static let goalProgress = "accessibility.goal.progress"
        static let stepToggle = "accessibility.step.toggle"
        static let stepCompleted = "accessibility.step.completed"
        static let stepIncomplete = "accessibility.step.incomplete"
        static let buttonBack = "accessibility.button.back"
        static let buttonSettings = "accessibility.button.settings"
        static let buttonChat = "accessibility.button.chat"
    }
    
    enum Offline {
        static let banner = "offline.banner"
        static let pending = "offline.pending"
        static let syncing = "offline.syncing"
    }
    
    enum Validation {
        static let goalEmpty = "validation.goal.empty"
        static let goalTooShort = "validation.goal.tooShort"
        static let goalTooLong = "validation.goal.tooLong"
        static let goalInappropriate = "validation.goal.inappropriate"
        static let nameEmpty = "validation.name.empty"
        static let nameTooShort = "validation.name.tooShort"
        static let nameTooLong = "validation.name.tooLong"
        static let nameInvalid = "validation.name.invalid"
        static let ageInvalid = "validation.age.invalid"
        static let ageTooYoung = "validation.age.tooYoung"
        static let messageEmpty = "validation.message.empty"
        static let messageTooLong = "validation.message.tooLong"
    }
}

// MARK: - Localization Manager
/// Manages app localization settings
final class LocalizationManager {
    static let shared = LocalizationManager()
    
    private init() {}
    
    /// Current language code (e.g., "en", "es", "fr")
    var currentLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }
    
    /// All supported languages
    var supportedLanguages: [String] {
        Bundle.main.localizations.filter { $0 != "Base" }
    }
    
    /// Check if a specific language is supported
    func isLanguageSupported(_ languageCode: String) -> Bool {
        supportedLanguages.contains(languageCode)
    }
    
    /// Get display name for a language code
    func displayName(for languageCode: String) -> String {
        Locale.current.localizedString(forLanguageCode: languageCode) ?? languageCode
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension String {
    /// For previews: shows key if translation missing
    var localizedPreview: String {
        let localized = NSLocalizedString(self, comment: "")
        return localized == self ? "[\(self)]" : localized
    }
}
#endif

