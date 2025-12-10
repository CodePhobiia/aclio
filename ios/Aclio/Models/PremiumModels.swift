import Foundation

// MARK: - Premium Configuration
struct PremiumConfig {
    static let freeGoalLimit = 3
    static let freeDoItForMeDaily = 2
    static let freeExpandDaily = 3
}

// MARK: - Subscription Plan
struct SubscriptionPlan: Identifiable, Equatable {
    let id: String
    let period: String
    let price: String
    let priceValue: Double
    let isBestValue: Bool
    
    var periodLabel: String {
        switch id {
        case "weekly": return "week"
        case "monthly": return "month"
        case "yearly": return "year"
        default: return "month"
        }
    }
    
    static let weekly = SubscriptionPlan(
        id: "weekly",
        period: "Weekly",
        price: "$2.99",
        priceValue: 2.99,
        isBestValue: false
    )
    
    static let monthly = SubscriptionPlan(
        id: "monthly",
        period: "Monthly",
        price: "$7.99",
        priceValue: 7.99,
        isBestValue: false
    )
    
    static let yearly = SubscriptionPlan(
        id: "yearly",
        period: "Yearly",
        price: "$49.99",
        priceValue: 49.99,
        isBestValue: true
    )
    
    // Order: smallest to largest (left to right)
    static let all: [SubscriptionPlan] = [weekly, monthly, yearly]
}

// MARK: - Premium Feature
struct PremiumFeature: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let iconName: String
    
    var systemIcon: String {
        switch iconName {
        case "infinity": return "infinity"
        case "wand": return "wand.and.stars"
        case "share": return "square.and.arrow.up"
        case "sparkles": return "sparkles"
        default: return "star.fill"
        }
    }
    
    static let all: [PremiumFeature] = [
        PremiumFeature(
            title: "Unlimited Goals",
            description: "Create as many goals as you want without restrictions.",
            iconName: "infinity"
        ),
        PremiumFeature(
            title: "Unlimited Do It For Me & Expands",
            description: "AI can generate steps, expansions, and tasks for any goal, anytime.",
            iconName: "wand"
        ),
        PremiumFeature(
            title: "Achievement Sharing",
            description: "Share your milestones, streaks, and completed goals with friends.",
            iconName: "share"
        ),
        PremiumFeature(
            title: "Priority AI Responses",
            description: "Get faster and more accurate AI assistance with priority processing.",
            iconName: "sparkles"
        ),
    ]
}

// MARK: - Daily Usage Tracking
struct DailyUsage: Codable {
    let date: String
    var count: Int
    
    init(date: String = "", count: Int = 0) {
        self.date = date
        self.count = count
    }
    
    static func todayString() -> String {
        Date().formatted(date: .complete, time: .omitted)
    }
    
    var isToday: Bool {
        date == DailyUsage.todayString()
    }
}

// MARK: - Premium Feature Type
enum PremiumFeatureType {
    case createGoal
    case doItForMe
    case expandStep
    case chat
    
    var dailyLimit: Int {
        switch self {
        case .createGoal: return PremiumConfig.freeGoalLimit
        case .doItForMe: return PremiumConfig.freeDoItForMeDaily
        case .expandStep: return PremiumConfig.freeExpandDaily
        case .chat: return .max
        }
    }
    
    var storageKey: String {
        switch self {
        case .createGoal: return "goals_created"
        case .doItForMe: return "doitforme_uses"
        case .expandStep: return "expand_uses"
        case .chat: return "chat_messages"
        }
    }
}

// MARK: - Onboarding Slide
struct OnboardingSlide: Identifiable {
    let id = UUID()
    let iconName: String
    let iconBgHex: String
    let iconColorHex: String
    let imageUrl: String
    let title: String
    let text: String
    let features: [OnboardingFeature]?
    let tasks: [String]?
    let badge: OnboardingBadge?
    
    var systemIcon: String {
        switch iconName {
        case "zap": return "bolt.fill"
        case "check": return "checkmark"
        case "trophy": return "trophy.fill"
        default: return "star.fill"
        }
    }
    
    static let slides: [OnboardingSlide] = [
        OnboardingSlide(
            iconName: "zap",
            iconBgHex: "FF9F43",
            iconColorHex: "FF9F43",
            imageUrl: "lightbulb",
            title: "AI-Powered Goal Planning",
            text: "Transform your aspirations into personalized, AI-generated action plans tailored to your goals.",
            features: [
                OnboardingFeature(iconName: "sparkles", text: "Smart guidance for any goal"),
                OnboardingFeature(iconName: "zap", text: "Personalized action plans"),
                OnboardingFeature(iconName: "target", text: "Tailored to your timeline"),
            ],
            tasks: nil,
            badge: nil
        ),
        OnboardingSlide(
            iconName: "check",
            iconBgHex: "22C55E",
            iconColorHex: "22C55E",
            imageUrl: "clipboard",
            title: "Step-by-Step Guidance",
            text: "Break down your goal into clear, manageable tasks with intelligent coaching that adapts to your progress.",
            features: nil,
            tasks: [
                "Research industry trends",
                "Complete an online course",
                "Build a portfolio project",
                "Connect with mentors",
            ],
            badge: nil
        ),
        OnboardingSlide(
            iconName: "trophy",
            iconBgHex: "FFB347",
            iconColorHex: "FFB347",
            imageUrl: "trophy",
            title: "Track Your Success",
            text: "Celebrate milestones, stay motivated, and watch your streaks grow as you achieve your goals.",
            features: nil,
            tasks: nil,
            badge: OnboardingBadge(iconName: "trophy", text: "7-day streak unlocked")
        ),
    ]
}

struct OnboardingFeature: Identifiable {
    let id = UUID()
    let iconName: String
    let text: String
    
    var systemIcon: String {
        switch iconName {
        case "sparkles": return "sparkles"
        case "zap": return "bolt.fill"
        case "target": return "scope"
        default: return "star.fill"
        }
    }
}

struct OnboardingBadge {
    let iconName: String
    let text: String
    
    var systemIcon: String {
        "trophy.fill"
    }
}

// MARK: - Goal Categories
struct GoalCategories {
    static let all: [String] = [
        "Health & Fitness",
        "Career",
        "Education",
        "Finance",
        "Creative",
        "Personal Growth",
        "Relationships",
        "Travel",
        "Home & Living",
        "Technology"
    ]
}


