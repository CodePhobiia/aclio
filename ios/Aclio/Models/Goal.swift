import Foundation

// MARK: - Goal Model
struct Goal: Identifiable, Codable, Equatable {
    let id: Int
    var name: String
    var category: String?
    var iconKey: String
    var iconColor: IconColor
    var dueDate: Date?
    var steps: [Step]
    var completedSteps: [Int]
    let createdAt: Date
    
    // MARK: - Computed Properties
    var progress: Int {
        guard !steps.isEmpty else { return 0 }
        return Int((Double(completedSteps.count) / Double(steps.count)) * 100)
    }
    
    var isCompleted: Bool {
        progress == 100
    }
    
    var nextStep: Step? {
        steps.first { !completedSteps.contains($0.id) }
    }
    
    var completedStepsCount: Int {
        completedSteps.count
    }
    
    var totalStepsCount: Int {
        steps.count
    }
    
    var dueDateStatus: DueDateStatus? {
        guard let dueDate = dueDate else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        let due = Calendar.current.startOfDay(for: dueDate)
        let days = Calendar.current.dateComponents([.day], from: today, to: due).day ?? 0
        
        if days < 0 {
            return .overdue
        } else if days == 0 {
            return .today
        } else if days <= 3 {
            return .soon(days: days)
        } else {
            return .normal(days: days)
        }
    }
    
    // MARK: - Initializer
    init(
        id: Int = Int(Date().timeIntervalSince1970 * 1000),
        name: String,
        category: String? = nil,
        iconKey: String = "target",
        iconColor: IconColor = IconColor.options[0],
        dueDate: Date? = nil,
        steps: [Step] = [],
        completedSteps: [Int] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.iconKey = iconKey
        self.iconColor = iconColor
        self.dueDate = dueDate
        self.steps = steps
        self.completedSteps = completedSteps
        self.createdAt = createdAt
    }
    
    // MARK: - Mutations
    mutating func toggleStep(_ stepId: Int) {
        if completedSteps.contains(stepId) {
            completedSteps.removeAll { $0 == stepId }
        } else {
            completedSteps.append(stepId)
        }
    }
    
    func isStepCompleted(_ stepId: Int) -> Bool {
        completedSteps.contains(stepId)
    }
}

// MARK: - Due Date Status
enum DueDateStatus: Equatable {
    case overdue
    case today
    case soon(days: Int)
    case normal(days: Int)
    
    var text: String {
        switch self {
        case .overdue: return "Overdue"
        case .today: return "Due today"
        case .soon(let days): return "\(days)d left"
        case .normal(let days): return "\(days)d left"
        }
    }
    
    var isUrgent: Bool {
        switch self {
        case .overdue, .today, .soon: return true
        case .normal: return false
        }
    }
}

// MARK: - Step Model
struct Step: Identifiable, Codable, Equatable {
    let id: Int
    var title: String
    var description: String
    var duration: String?
    
    init(id: Int, title: String, description: String = "", duration: String? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.duration = duration
    }
}

// MARK: - Expanded Step Content
struct ExpandedStepContent: Codable, Equatable {
    let content: String
}

// MARK: - Goal Icon Keys
struct GoalIcons {
    static let keys: [String] = [
        "target", "fitness", "book", "dollar", "palette", "rocket",
        "run", "music", "code", "plane", "home", "heart", "brain", "pencil"
    ]
    
    static func systemName(for key: String) -> String {
        switch key {
        case "target": return "scope"
        case "fitness": return "dumbbell.fill"
        case "book": return "book.fill"
        case "dollar": return "dollarsign.circle.fill"
        case "palette": return "paintpalette.fill"
        case "rocket": return "paperplane.fill"
        case "run": return "figure.run"
        case "music": return "music.note"
        case "code": return "chevron.left.forwardslash.chevron.right"
        case "plane": return "airplane"
        case "home": return "house.fill"
        case "heart": return "heart.fill"
        case "brain": return "brain.head.profile"
        case "pencil": return "pencil"
        default: return "target"
        }
    }
}

// MARK: - Sample Data (for Previews)
extension Goal {
    static let sample = Goal(
        id: 1,
        name: "Learn Swift",
        category: "Education",
        iconKey: "code",
        iconColor: IconColor.options[1],
        dueDate: Calendar.current.date(byAdding: .day, value: 14, to: Date()),
        steps: [
            Step(id: 1, title: "Complete Swift Basics", description: "Learn variables, functions, and control flow", duration: "2 hours"),
            Step(id: 2, title: "Build First App", description: "Create a simple Hello World app", duration: "1 hour"),
            Step(id: 3, title: "Learn SwiftUI", description: "Study declarative UI patterns", duration: "3 hours"),
            Step(id: 4, title: "Build Portfolio Project", description: "Create a complete app for portfolio", duration: "1 week"),
        ],
        completedSteps: [1]
    )
    
    static let sampleCompleted = Goal(
        id: 2,
        name: "Run a 5K",
        category: "Health & Fitness",
        iconKey: "run",
        iconColor: IconColor.options[3],
        steps: [
            Step(id: 1, title: "Start with walking", description: "Walk 30 minutes daily"),
            Step(id: 2, title: "Begin jogging", description: "Jog for 10 minutes"),
            Step(id: 3, title: "Build endurance", description: "Increase to 20 minutes"),
        ],
        completedSteps: [1, 2, 3]
    )
    
    static let samples: [Goal] = [sample, sampleCompleted]
}

